"""Configuration module for ArogyaKrishi backend.

Manages environment variables, settings, and application-wide configuration.
"""

from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # App metadata
    app_name: str = "ArogyaKrishi Backend"
    app_version: str = "0.1.0"
    debug: bool = False
    
    # Database (PostgreSQL URL)
    database_url: str = "postgresql+psycopg://arogya_user:arogya_password@localhost:5432/arogya_krishi"
    
    # CORS
    allowed_origins: str = "http://localhost,http://localhost:3000,http://127.0.0.1,http://127.0.0.1:3000"
    
    # Image upload
    max_image_size_mb: int = 10
    allowed_image_types: str = "image/jpeg,image/png"
    
    # ML Model
    use_mock_inference: bool = True
    model_path: Optional[str] = None
    confidence_threshold: float = 0.5
    
    # LLM (optional)
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None

    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"  # Ignore extra fields from .env


settings = Settings()

