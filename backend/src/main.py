import asyncio
from contextlib import suppress

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from src.admin.routes import router as admin_router
from src.config.settings import settings
from src.database.session import close_db, init_db
from src.shared.dtos import DataResponse
from src.user.routes import router as user_router
from src.user.connect.cleanup import cleanup_loop


class PrivateNetworkAccessMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        if request.headers.get("access-control-request-private-network") == "true":
            response.headers["Access-Control-Allow-Private-Network"] = "true"
        return response


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        debug=settings.debug,
        version="1.0.0",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.backend_cors_origins,
        allow_origin_regex=settings.backend_cors_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.add_middleware(PrivateNetworkAccessMiddleware)
    app.include_router(user_router, prefix=settings.api_v1_prefix)
    app.include_router(admin_router, prefix=settings.api_v1_prefix)

    @app.on_event("startup")
    async def on_startup() -> None:
        await init_db()
        app.state.vault_connect_cleanup = asyncio.create_task(cleanup_loop())

    @app.on_event("shutdown")
    async def on_shutdown() -> None:
        cleanup_task = getattr(app.state, "vault_connect_cleanup", None)
        if cleanup_task:
            cleanup_task.cancel()
            with suppress(asyncio.CancelledError):
                await cleanup_task
        await close_db()

    @app.get("/health", response_model=DataResponse, tags=["health"])
    async def health_check() -> DataResponse:
        return DataResponse(message="Health check successful", data={"status": "ok"})

    return app


app = create_app()
