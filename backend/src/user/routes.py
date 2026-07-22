from fastapi import APIRouter

from src.user.ai.routes import router as ai_router
from src.user.auth.routes import router as auth_router
from src.user.banners.routes import router as banners_router
from src.user.documents.routes import router as documents_router
from src.user.files.routes import router as files_router
from src.user.media.routes import router as media_router
from src.user.passwords.routes import router as passwords_router
from src.user.policy.routes import router as policy_router
from src.user.profile.routes import router as profile_router
from src.user.subscriptions.routes import router as subscriptions_router
from src.user.notifications.routes import router as notifications_router
from src.user.support.routes import router as support_router
from src.user.connect.routes import router as connect_router

router = APIRouter()
router.include_router(ai_router)
router.include_router(auth_router)
router.include_router(banners_router)
router.include_router(documents_router)
router.include_router(files_router)
router.include_router(media_router)
router.include_router(passwords_router)
router.include_router(policy_router)
router.include_router(profile_router)
router.include_router(subscriptions_router)
router.include_router(notifications_router)
router.include_router(support_router)
router.include_router(connect_router)
