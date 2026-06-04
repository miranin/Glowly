"""
Authentication router — fields match iOS AuthManager / AuthEndpoints exactly.

POST /api/auth/register   → registers user, returns AuthResponse (accessToken, username, email, roles)
POST /api/auth/login      → validates credentials, returns same AuthResponse
POST /api/auth/refresh    → stub (extend later with refresh tokens)
POST /api/auth/logout     → clears server-side session (stub for JWT)
"""

import logging

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import or_, select

from database.models import User, UserProfile
from routers.deps import DB, hash_password, verify_password, create_access_token
from schemas.auth import AuthResponse, LoginRequest, RefreshTokenRequest, RegisterRequest

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/auth", tags=["auth"])


# ─── Register ─────────────────────────────────────────────────────────────────

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: DB) -> AuthResponse:
    """
    Creates a new user account.
    Returns accessToken immediately so the iOS app can proceed without
    a separate email-verification step (MVP — add OTP later).
    """
    # Check uniqueness
    result = await db.execute(
        select(User).where(
            or_(User.username == body.username, User.email == str(body.email))
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered",
        )

    user = User(
        username=body.username,
        email=str(body.email),
        hashed_password=hash_password(body.password),
        roles=["user"],
    )
    db.add(user)
    await db.flush()  # get user.id before creating profile

    # Auto-create empty profile
    profile = UserProfile(user_id=user.id)
    db.add(profile)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(
        {"sub": user.id, "username": user.username, "email": user.email}
    )
    logger.info(f"Registered new user: {user.email}")

    return AuthResponse(
        access_token=token,
        username=user.username,
        email=user.email,
        roles=user.roles,
    )


# ─── Login ────────────────────────────────────────────────────────────────────

@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest, db: DB) -> AuthResponse:
    """
    Authenticates with email or username.
    iOS sends `usernameOrEmail` in the request body.
    """
    identifier = body.username_or_email
    result = await db.execute(
        select(User).where(
            or_(User.username == identifier, User.email == identifier)
        )
    )
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is deactivated")

    token = create_access_token(
        {"sub": user.id, "username": user.username, "email": user.email}
    )
    logger.info(f"Login: {user.email}")

    return AuthResponse(
        access_token=token,
        username=user.username,
        email=user.email,
        roles=user.roles,
    )


# ─── Logout ───────────────────────────────────────────────────────────────────

@router.post("/logout")
async def logout() -> dict:
    """
    JWT is stateless — client discards the token.
    This endpoint exists so the iOS AuthManager's signOut() doesn't 404.
    Add a token-blocklist here if you need server-side invalidation.
    """
    return {"message": "Logged out successfully"}


# ─── Refresh (stub) ───────────────────────────────────────────────────────────

@router.post("/refresh")
async def refresh_token(body: RefreshTokenRequest) -> dict:
    """Stub — extend with refresh token rotation in production."""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Refresh token rotation not yet implemented",
    )
