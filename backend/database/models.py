"""
SQLAlchemy ORM models — mirrors the iOS data model exactly so JSON payloads
round-trip without transformation.
"""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    JSON,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database.db import Base


def _uuid() -> str:
    return str(uuid.uuid4())


# ─── User ─────────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    username: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    roles: Mapped[list] = mapped_column(JSON, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    profile: Mapped["UserProfile"] = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    products: Mapped[list["Product"]] = relationship("Product", back_populates="user", cascade="all, delete-orphan")
    chat_messages: Mapped[list["ChatMessage"]] = relationship("ChatMessage", back_populates="user", cascade="all, delete-orphan")


# ─── UserProfile ──────────────────────────────────────────────────────────────

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), unique=True, nullable=False)

    # Demographics
    age_range: Mapped[str | None] = mapped_column(String(32))
    sex: Mapped[str | None] = mapped_column(String(16))

    # Skin
    skin_type: Mapped[str | None] = mapped_column(String(32))
    skin_tone: Mapped[str | None] = mapped_column(String(32))
    skin_conditions: Mapped[list] = mapped_column(JSON, default=list)    # ["acne", "redness", ...]
    allergies: Mapped[list] = mapped_column(JSON, default=list)
    sensitivities: Mapped[list] = mapped_column(JSON, default=list)

    # Goals & preferences
    experience_level: Mapped[str | None] = mapped_column(String(32))
    beauty_goals: Mapped[list] = mapped_column(JSON, default=list)
    preferred_brands: Mapped[list] = mapped_column(JSON, default=list)
    makeup_frequency: Mapped[str | None] = mapped_column(String(32))
    skincare_routine_complexity: Mapped[str | None] = mapped_column(String(32))

    has_completed_onboarding: Mapped[bool] = mapped_column(Boolean, default=False)
    last_updated: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship("User", back_populates="profile")

    @property
    def ai_context_string(self) -> str:
        """Formatted string injected into LLM system prompt."""
        parts = ["User Profile:"]
        if self.age_range:
            parts.append(f"- Age Range: {self.age_range}")
        if self.sex:
            parts.append(f"- Sex: {self.sex}")
        if self.skin_type:
            parts.append(f"- Skin Type: {self.skin_type}")
        if self.skin_tone:
            parts.append(f"- Skin Tone: {self.skin_tone}")
        if self.skin_conditions:
            parts.append(f"- Skin Conditions: {', '.join(self.skin_conditions)}")
        if self.allergies:
            parts.append(f"- Allergies: {', '.join(self.allergies)}")
        if self.beauty_goals:
            parts.append(f"- Beauty Goals: {', '.join(self.beauty_goals)}")
        if self.experience_level:
            parts.append(f"- Experience Level: {self.experience_level}")
        if self.makeup_frequency:
            parts.append(f"- Makeup Frequency: {self.makeup_frequency}")
        return "\n".join(parts)


# ─── Product ──────────────────────────────────────────────────────────────────

class Product(Base):
    __tablename__ = "products"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    brand: Mapped[str] = mapped_column(String(128), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)        # English key: "moisturizer"
    application_zone: Mapped[str | None] = mapped_column(String(64))

    # AI-extracted fields
    ingredients: Mapped[str] = mapped_column(Text, default="")
    ingredients_list: Mapped[list] = mapped_column(JSON, default=list)       # parsed list
    how_to_use: Mapped[str] = mapped_column(Text, default="")
    benefits: Mapped[list] = mapped_column(JSON, default=list)
    warnings: Mapped[list] = mapped_column(JSON, default=list)
    barcode: Mapped[str | None] = mapped_column(String(64))
    notes: Mapped[str] = mapped_column(Text, default="")

    # Safety flags
    is_sensitive_safe: Mapped[bool] = mapped_column(Boolean, default=False)
    is_acne_safe: Mapped[bool] = mapped_column(Boolean, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # AI metadata
    ai_confidence: Mapped[float] = mapped_column(Float, default=0.0)
    ai_raw_description: Mapped[str | None] = mapped_column(Text)             # raw vision output
    needs_confirmation: Mapped[bool] = mapped_column(Boolean, default=False)

    purchase_date: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship("User", back_populates="products")


# ─── ChatMessage ──────────────────────────────────────────────────────────────

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), nullable=False, index=True)
    role: Mapped[str] = mapped_column(String(16), nullable=False)            # "user" | "assistant"
    content: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="chat_messages")
