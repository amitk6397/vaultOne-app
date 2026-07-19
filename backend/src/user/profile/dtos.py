from pydantic import BaseModel, EmailStr, Field, field_validator


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
