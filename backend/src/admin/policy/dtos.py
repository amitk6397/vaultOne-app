from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from src.database.models import PolicyType
from src.shared.dtos import ORMModel


class PolicySection(BaseModel):
    title: str = Field(min_length=2, max_length=160)
    body: str = Field(min_length=2)


class PolicyPageBase(BaseModel):
    policy_type: PolicyType
    title: str = Field(min_length=2, max_length=160)
    sections: list[PolicySection] = Field(min_length=1)
    is_active: bool = True

    @field_validator("sections")
    @classmethod
    def validate_sections(cls, value: list[PolicySection]) -> list[PolicySection]:
        if len(value) > 20:
            raise ValueError("Policy can contain up to 20 sections")
        return value


class PolicyPageCreate(PolicyPageBase):
    pass


class PolicyPageUpdate(BaseModel):
    policy_type: PolicyType | None = None
    title: str | None = Field(default=None, min_length=2, max_length=160)
    sections: list[PolicySection] | None = Field(default=None, min_length=1)
    is_active: bool | None = None

    @field_validator("sections")
    @classmethod
    def validate_sections(cls, value: list[PolicySection] | None) -> list[PolicySection] | None:
        if value is not None and len(value) > 20:
            raise ValueError("Policy can contain up to 20 sections")
        return value


class PolicyPageResponse(PolicyPageBase, ORMModel):
    id: int
    created_at: datetime
    updated_at: datetime
