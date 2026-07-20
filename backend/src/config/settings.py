from functools import lru_cache
from urllib.parse import quote

from pydantic import AliasChoices, Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "vaultOne API"
    app_env: str = "development"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    database_url_value: str | None = Field(default=None, alias="DATABASE_URL")
    db_user: str | None = None
    db_password: str | None = None
    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_name: str | None = None

    jwt_secret_key: str = Field(min_length=32)
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    otp_expire_minutes: int = 10
    otp_length: int = 6

    smtp_host: str | None = None
    smtp_port: int = 587
    smtp_username: str | None = None
    smtp_password: str | None = None
    smtp_from_email: str | None = None
    smtp_from_name: str = "VaultOne"
    smtp_use_tls: bool = True

    brevo_api_key: str | None = Field(
        default=None,
        validation_alias=AliasChoices("BREVO_API_KEY"),
    )
    brevo_from_email: str | None = Field(
        default=None,
        validation_alias=AliasChoices("BREVO_FROM_EMAIL", "BREVO_SENDER_EMAIL"),
    )
    brevo_from_name: str = Field(
        default="VaultOne",
        validation_alias=AliasChoices("BREVO_FROM_NAME", "BREVO_SENDER_NAME"),
    )

    gemini_api_key: str | None = None
    gemini_model: str = "gemini-2.5-flash"
    gemini_timeout_seconds: int = 30

    # Firebase service-account JSON. Relative paths are resolved from backend/.
    firebase_credentials_path: str = "firebase-service-account.json"

    cloudinary_url: str | None = Field(default=None, alias="CLOUDINARY_URL")
    cloudinary_cloud_name: str | None = Field(
        default=None,
        alias="CLOUDINARY_CLOUD_NAME",
    )
    cloudinary_api_key: str | None = Field(
        default=None,
        alias="CLOUDINARY_API_KEY",
    )
    cloudinary_api_secret: str | None = Field(
        default=None,
        alias="CLOUDINARY_API_SECRET",
    )
    # "cloudinary" stores Vault Connect transfers as authenticated Cloudinary
    # assets. "local" is an explicit development-only private filesystem mode.
    vault_connect_storage_backend: str = "cloudinary"

    backend_cors_origins_value: str = Field(default="", alias="BACKEND_CORS_ORIGINS")
    backend_cors_origin_regex_value: str = Field(
        default="",
        alias="BACKEND_CORS_ORIGIN_REGEX",
    )

    @field_validator("debug", mode="before")
    @classmethod
    def parse_debug(cls, value: bool | str) -> bool:
        if isinstance(value, bool):
            return value
        normalized = value.strip().lower()
        if normalized in {"release", "prod", "production", "false", "0", "no"}:
            return False
        if normalized in {"debug", "dev", "development", "true", "1", "yes"}:
            return True
        return bool(value)

    @computed_field
    @property
    def database_url(self) -> str:
        if self.database_url_value:
            return self.database_url_value
        if not self.db_user or not self.db_password or not self.db_name:
            raise ValueError("DATABASE_URL or DB_USER, DB_PASSWORD, and DB_NAME must be set")
        encoded_user = quote(self.db_user, safe="")
        encoded_password = quote(self.db_password, safe="")
        encoded_database = quote(self.db_name, safe="")
        return (
            f"mysql+aiomysql://{encoded_user}:{encoded_password}"
            f"@{self.db_host}:{self.db_port}/{encoded_database}"
        )

    @computed_field
    @property
    def backend_cors_origins(self) -> list[str]:
        return [
            origin.strip()
            for origin in self.backend_cors_origins_value.split(",")
            if origin.strip()
        ]

    @computed_field
    @property
    def backend_cors_origin_regex(self) -> str | None:
        if self.backend_cors_origin_regex_value.strip():
            return self.backend_cors_origin_regex_value.strip()
        if self.app_env.lower() in {"development", "dev", "local"}:
            return r"^https?://(localhost|127\.0\.0\.1|192\.168\.\d{1,3}\.\d{1,3})(:\d+)?$"
        return None

    @property
    def is_development(self) -> bool:
        return self.app_env.strip().lower() in {"development", "dev", "local"}

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
