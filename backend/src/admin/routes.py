from fastapi import APIRouter

from src.admin.auth.routes import router as auth_router
from src.admin.banners.routes import router as banners_router
from src.admin.policy.routes import router as policy_router
from src.admin.users.routes import router as users_router
from src.admin.subscriptions.routes import router as subscriptions_router
from src.admin.analytics.routes import router as analytics_router
from src.admin.notifications.routes import router as notifications_router
from src.admin.support.routes import router as support_router
from src.admin.connect_routes import router as connect_router

router = APIRouter()
router.include_router(auth_router)
router.include_router(banners_router)
router.include_router(policy_router)
router.include_router(users_router)
router.include_router(subscriptions_router)
router.include_router(analytics_router)
router.include_router(notifications_router)
router.include_router(support_router)
router.include_router(connect_router)
