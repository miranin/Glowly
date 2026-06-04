"""
Auth schemas — field names match iOS RegisterRequest / LoginRequest exactly.
camelCase on the wire (alias_generator) ↔ snake_case in Python.
"""

from pydantic import BaseModel, EmailStr, Field, field_validator
from pydantic.alias_generators import to_camel


class _CamelModel(BaseModel):
    """Base model that serializes to camelCase (matches Swift Codable defaults)."""

    model_config = {"alias_generator": to_camel, "populate_by_name": True}


# ─── Register ────────────────────────────────────────────────────────────────

class RegisterRequest(_CamelModel):
    username: str = Field(..., min_length=2, max_length=64)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    valid: bool = True

    @field_validator("username")
    @classmethod
    def no_spaces(cls, v: str) -> str:
        if " " in v:
            raise ValueError("Username must not contain spaces")
        return v


# ─── Login ───────────────────────────────────────────────────────────────────

class LoginRequest(_CamelModel):
    # iOS sends email or phone in this field
    username_or_email: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


# ─── Auth response (what iOS expects) ────────────────────────────────────────

class AuthResponse(_CamelModel):
    access_token: str
    token_type: str = "bearer"
    username: str
    email: str
    roles: list[str] = []


# ─── Refresh token ────────────────────────────────────────────────────────────

class RefreshTokenRequest(_CamelModel):
    refresh_token: str


class RefreshTokenResponse(_CamelModel):
    access_token: str
    token_type: str = "bearer"


# ─── User profile ─────────────────────────────────────────────────────────────

class UserProfileRequest(_CamelModel):
    age_range: str | None = None
    sex: str | None = None
    skin_type: str | None = None
    skin_tone: str | None = None
    skin_conditions: list[str] = []
    allergies: list[str] = []
    sensitivities: list[str] = []
    experience_level: str | None = None
    beauty_goals: list[str] = []
    preferred_brands: list[str] = []
    makeup_frequency: str | None = None
    skincare_routine_complexity: str | None = None
    has_completed_onboarding: bool = False


class UserProfileResponse(UserProfileRequest):
    id: str
    user_id: str


# ─── JWT payload ─────────────────────────────────────────────────────────────

class TokenData(BaseModel):
    user_id: str
    username: str
    email: str
