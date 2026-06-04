"""
Custom MCP (Model Context Protocol) server router.

GET  /api/mcp/tools      — returns tool manifests (for Claude tool_use API / academic demo)
POST /api/mcp/execute    — executes a named tool and returns the result

Authentication required on all routes.
"""

import logging

from fastapi import APIRouter, HTTPException

from routers.deps import CurrentUser
from schemas.ai import MCPToolManifest, MCPToolRequest, MCPToolResponse
from services.mcp_tools import TOOL_MANIFESTS, execute_tool

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/mcp", tags=["mcp"])


@router.get("/tools", response_model=list[MCPToolManifest])
async def list_tools(current_user: CurrentUser) -> list[dict]:
    """
    Returns the manifest of all available MCP tools in the format expected
    by Claude's tool_use API. The iOS client or a Claude agent can call this
    to discover available tools dynamically.
    """
    return [
        MCPToolManifest(
            name=t["name"],
            description=t["description"],
            input_schema=t["input_schema"],
        )
        for t in TOOL_MANIFESTS
    ]


@router.post("/execute", response_model=MCPToolResponse)
async def execute_mcp_tool(
    body: MCPToolRequest,
    current_user: CurrentUser,
) -> MCPToolResponse:
    """
    Execute a named MCP tool with the provided input.

    Available tools:
    - analyze_ingredients
    - categorize_product
    - recommend_routine

    Example request body:
    {
        "tool": "analyze_ingredients",
        "input": {
            "ingredients": ["retinol", "niacinamide", "hyaluronic acid"],
            "skin_type": "oily"
        }
    }
    """
    logger.info(f"MCP tool call: '{body.tool}' by user {current_user.id}")

    try:
        result = await execute_tool(body.tool, body.input)
        return MCPToolResponse(
            tool=body.tool,
            success=True,
            result=result,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.error(f"MCP tool '{body.tool}' failed: {exc}", exc_info=True)
        return MCPToolResponse(
            tool=body.tool,
            success=False,
            result={},
            error=str(exc),
        )
