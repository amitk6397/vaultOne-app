import argparse
import asyncio
import getpass

from sqlalchemy import select

from src.core.security import hash_password
from src.database.models import Admin
from src.database.session import AsyncSessionLocal, engine


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create or update a VaultOne admin.")
    parser.add_argument("--email", required=True, help="Admin email address")
    parser.add_argument("--full-name", required=True, help="Admin full name")
    parser.add_argument(
        "--password",
        help="Admin password. Omit this flag to enter it securely.",
    )
    parser.add_argument(
        "--update-password",
        action="store_true",
        help="Update password if the admin already exists.",
    )
    return parser.parse_args()


def read_password(password: str | None) -> str:
    value = password or getpass.getpass("Password: ")
    confirm = getpass.getpass("Confirm password: ") if password is None else value
    if value != confirm:
        raise ValueError("Passwords do not match")
    if len(value) < 8:
        raise ValueError("Password must be at least 8 characters")
    return value


async def create_admin() -> None:
    args = parse_args()
    email = args.email.strip().lower()
    full_name = args.full_name.strip()
    password = read_password(args.password)

    async with AsyncSessionLocal() as session:
        admin = await session.scalar(select(Admin).where(Admin.email == email))
        if admin:
            admin.full_name = full_name
            admin.is_active = True
            if args.update_password:
                admin.password_hash = hash_password(password)
            await session.commit()
            print(f"Admin already exists and was updated: {email}")
            return

        session.add(
            Admin(
                full_name=full_name,
                email=email,
                password_hash=hash_password(password),
                is_active=True,
            )
        )
        await session.commit()
        print(f"Admin created: {email}")


if __name__ == "__main__":
    async def main() -> None:
        try:
            await create_admin()
        finally:
            await engine.dispose()

    asyncio.run(main())
