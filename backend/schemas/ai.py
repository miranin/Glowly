"""
AI / chat schemas.
"""

from pydantic import BaseModel, Field
from pydantic.alias_generators import to_camel


class _CamelModel(BaseModel):
    model_config = {"alias_generator": to_camel, "populate_by_name": True}


class MessageRole(str):
    user = "user"
    assistant = "assistant"
    system = "system"


class AIMessage(_CamelModel):
    role: str          # "user" | "assistant"
    content: str


class ChatRequest(_CamelModel):
    messages: list[AIMessage]
    user_profile: dict = {}     # optional profile dict for context injection


class ChatResponse(_CamelModel):
    content: str
    model: str = ""
    usage: dict = {}


class RecommendationItem(_CamelModel):
    product_name: str
    brand: str
    category: str
    reason: str
    priority: int = 5
    ingredient_synergy: list[str] = []


class RecommendationsResponse(_CamelModel):
    recommendations: list[RecommendationItem]
    profile_summary: str = ""
    missing_routine_steps: list[str] = []


# ─── MCP tool call schemas ────────────────────────────────────────────────────

class MCPToolRequest(_CamelModel):
    tool: str
    input: dict = {}


class MCPToolResponse(_CamelModel):
    tool: str
    success: bool
    result: dict = {}
    error: str | None = None


class MCPToolManifest(BaseModel):
    name: str
    description: str
    input_schema: dict
