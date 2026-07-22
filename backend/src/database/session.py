from collections.abc import AsyncGenerator

from sqlalchemy import inspect, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from src.config.settings import settings
from src.database.base import Base
from src.database import models
from src.user.connect import models as connect_models  # noqa: F401


engine = create_async_engine(
    settings.database_url,
    pool_size=5,
    max_overflow=10,
    pool_timeout=10,
    pool_recycle=1800,
    connect_args={"connect_timeout": 10}
    if settings.database_url.startswith("mysql+aiomysql")
    else {},
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session


async def init_db() -> None:
    try:
        async with engine.begin() as connection:
            # create_all does not add columns to an existing table. Keep this
            # small, idempotent upgrade here so deployed instances cannot boot
            # with a model/schema mismatch. Larger migrations remain versioned
            # in backend/migrations.
            tables = await connection.run_sync(
                lambda sync_connection: inspect(sync_connection).get_table_names()
            )
            if "users" in tables:
                user_columns = await connection.run_sync(
                    lambda sync_connection: {
                        column["name"]
                        for column in inspect(sync_connection).get_columns("users")
                    }
                )
                if "storage_limit_bytes" not in user_columns:
                    await connection.execute(
                        text(
                            "ALTER TABLE users "
                            "ADD COLUMN storage_limit_bytes BIGINT NULL"
                        )
                    )
            if "messages" in tables:
                message_columns = await connection.run_sync(
                    lambda sync_connection: {
                        column["name"]: str(column["type"]).lower()
                        for column in inspect(sync_connection).get_columns("messages")
                    }
                )
                if "voice" not in message_columns.get("message_type", ""):
                    await connection.execute(text(
                        "ALTER TABLE messages MODIFY COLUMN message_type "
                        "ENUM('text','image','video','document','voice','deleted') NOT NULL"
                    ))
            await connection.run_sync(Base.metadata.create_all)
    except OperationalError as error:
        raise RuntimeError(
            "Database connection failed. Check DB_USER, DB_PASSWORD, DB_HOST, "
            "DB_PORT, and DB_NAME in backend/.env, then make sure that MySQL "
            "user has permission to connect and create/use the database."
        ) from error


async def close_db() -> None:
    await engine.dispose()
