from pydantic import BaseModel, EmailStr, Field, field_validator


class AccountDeletionRequestCreate(BaseModel):
    reason_code: str = Field(min_length=2, max_length=60)
    reason_text: str | None = Field(default=None, max_length=1000)


class UserProfileUpdate(BaseModel):
    full_name: str = Field(min_length=3, max_length=120)
    email: EmailStr
    phone: str = Field(min_length=10, max_length=20)
    city: str | None = Field(default=None, max_length=120)

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str) -> str:
        digits = "".join(char for char in value if char.isdigit())
        if len(digits) < 10 or len(digits) > 13:
            raise ValueError("Enter a valid phone number")
        return digits
