import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ai/views/ai_page.dart';
import '../features/assets/views/assets_page.dart';
import '../features/auth/views/forgot_password_page.dart';
import '../features/auth/views/login_page.dart';
import '../features/auth/views/onboarding_page.dart';
import '../features/auth/views/register_page.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/verify_otp_page.dart';
import '../features/documents/views/documents_page.dart';
import '../features/files_vault/views/files_vault_page.dart';
import '../features/home/views/home_page_redesigned.dart';
import '../features/media/models/media_item.dart';
import '../features/media/views/album_details_page.dart';
import '../features/media/views/albums_page.dart';
import '../features/media/views/deleted_media_page.dart';
import '../features/media/views/filtered_media_page.dart';
import '../features/media/views/media_details_page.dart';
import '../features/media/views/media_security_page.dart';
import '../features/media/views/photo_gallery_page.dart';
import '../features/media/views/photo_viewer_page.dart';
import '../features/media/views/video_folders_page.dart';
import '../features/media/views/video_gallery_page.dart';
import '../features/media/views/video_player_page.dart';
import '../features/passwords/views/add_edit_password_page.dart';
import '../features/passwords/views/breach_check_page.dart';
import '../features/passwords/views/password_generator_page.dart';
import '../features/passwords/views/passwords_page.dart';
import '../features/passwords/views/secure_notes_page.dart';
import '../features/profile/views/delete_account_page.dart';
import '../features/profile/views/edit_profile_page.dart';
import '../features/profile/views/privacy_policy_page.dart';
import '../features/profile/views/profile_page.dart';
import '../features/profile/views/security_settings_page.dart';
import '../features/scanner/views/scanner_page.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: [
    GoRoute(
      name: AppRoutes.splashName,
      path: AppRoutes.splashPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SplashScreen()),
    ),
    GoRoute(
      name: AppRoutes.onboardingName,
      path: AppRoutes.onboardingPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const OnboardingPage()),
    ),
    GoRoute(
      name: AppRoutes.loginName,
      path: AppRoutes.loginPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const LoginPage()),
    ),
    GoRoute(
      name: AppRoutes.registerName,
      path: AppRoutes.registerPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const RegisterPage()),
    ),
    GoRoute(
      name: AppRoutes.forgotPasswordName,
      path: AppRoutes.forgotPasswordPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ForgotPasswordPage()),
    ),
    GoRoute(
      name: AppRoutes.verifyOtpName,
      path: AppRoutes.verifyOtpPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const VerifyOtpPage()),
    ),
    GoRoute(
      name: AppRoutes.homeName,
      path: AppRoutes.homePath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const HomePage()),
    ),
    GoRoute(
      name: AppRoutes.assetsName,
      path: AppRoutes.assetsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AssetsPage()),
    ),
    GoRoute(
      name: AppRoutes.documentsName,
      path: AppRoutes.documentsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const DocumentsPage()),
    ),
    GoRoute(
      name: AppRoutes.aiName,
      path: AppRoutes.aiPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AiPage()),
    ),
    GoRoute(
      name: AppRoutes.passwordsName,
      path: AppRoutes.passwordsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PasswordsPage()),
    ),
    GoRoute(
      name: AppRoutes.addEditPasswordName,
      path: AppRoutes.addEditPasswordPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AddEditPasswordPage()),
    ),
    GoRoute(
      name: AppRoutes.passwordGeneratorName,
      path: AppRoutes.passwordGeneratorPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PasswordGeneratorPage()),
    ),
    GoRoute(
      name: AppRoutes.secureNotesName,
      path: AppRoutes.secureNotesPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SecureNotesPage()),
    ),
    GoRoute(
      name: AppRoutes.breachCheckName,
      path: AppRoutes.breachCheckPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const BreachCheckPage()),
    ),
    GoRoute(
      name: AppRoutes.filesVaultName,
      path: AppRoutes.filesVaultPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const FilesVaultPage()),
    ),
    GoRoute(
      name: AppRoutes.photoGalleryName,
      path: AppRoutes.photoGalleryPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PhotoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.privatePhotosName,
      path: AppRoutes.privatePhotosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const FilteredMediaPage(
          title: 'Private Photos',
          subtitle: 'Locked photos protected by PIN or biometrics',
          icon: Icons.lock_rounded,
          kind: MediaKind.photo,
          visibility: MediaVisibility.private,
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.publicPhotosName,
      path: AppRoutes.publicPhotosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const FilteredMediaPage(
          title: 'Public Photos',
          subtitle: 'Shareable photos in your public gallery',
          icon: Icons.public_rounded,
          kind: MediaKind.photo,
          visibility: MediaVisibility.public,
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.albumsName,
      path: AppRoutes.albumsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AlbumsPage()),
    ),
    GoRoute(
      name: AppRoutes.albumDetailsName,
      path: AppRoutes.albumDetailsPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: AlbumDetailsPage(albumId: state.pathParameters['albumId'] ?? ''),
      ),
    ),
    GoRoute(
      name: AppRoutes.photoViewerName,
      path: AppRoutes.photoViewerPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: PhotoViewerPage(photoId: state.pathParameters['photoId'] ?? ''),
      ),
    ),
    GoRoute(
      name: AppRoutes.photoDetailsName,
      path: AppRoutes.photoDetailsPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: MediaDetailsPage(mediaId: state.pathParameters['photoId'] ?? ''),
      ),
    ),
    GoRoute(
      name: AppRoutes.videoGalleryName,
      path: AppRoutes.videoGalleryPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const VideoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.privateVideosName,
      path: AppRoutes.privateVideosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const FilteredMediaPage(
          title: 'Private Videos',
          subtitle: 'Locked videos protected by PIN or biometrics',
          icon: Icons.lock_rounded,
          kind: MediaKind.video,
          visibility: MediaVisibility.private,
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.publicVideosName,
      path: AppRoutes.publicVideosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const FilteredMediaPage(
          title: 'Public Videos',
          subtitle: 'Shareable videos in your public gallery',
          icon: Icons.public_rounded,
          kind: MediaKind.video,
          visibility: MediaVisibility.public,
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.videoFoldersName,
      path: AppRoutes.videoFoldersPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const VideoFoldersPage()),
    ),
    GoRoute(
      name: AppRoutes.videoDetailsName,
      path: AppRoutes.videoDetailsPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: MediaDetailsPage(mediaId: state.pathParameters['videoId'] ?? ''),
      ),
    ),
    GoRoute(
      name: AppRoutes.videoPlayerName,
      path: AppRoutes.videoPlayerPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: VideoPlayerPage(videoId: state.pathParameters['videoId'] ?? ''),
      ),
    ),
    GoRoute(
      name: AppRoutes.deletedMediaName,
      path: AppRoutes.deletedMediaPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const DeletedMediaPage()),
    ),
    GoRoute(
      name: AppRoutes.mediaSecurityName,
      path: AppRoutes.mediaSecurityPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const MediaSecurityPage()),
    ),
    GoRoute(
      name: AppRoutes.scannerName,
      path: AppRoutes.scannerPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ScannerPage()),
    ),
    GoRoute(
      name: AppRoutes.profileName,
      path: AppRoutes.profilePath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ProfilePage()),
    ),
    GoRoute(
      name: AppRoutes.editProfileName,
      path: AppRoutes.editProfilePath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const EditProfilePage()),
    ),
    GoRoute(
      name: AppRoutes.privacyPolicyName,
      path: AppRoutes.privacyPolicyPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const PrivacyPolicyPage()),
    ),
    GoRoute(
      name: AppRoutes.securitySettingsName,
      path: AppRoutes.securitySettingsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SecuritySettingsPage()),
    ),
    GoRoute(
      name: AppRoutes.appSettingsName,
      path: AppRoutes.appSettingsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AppSettingsPage()),
    ),
    GoRoute(
      name: AppRoutes.deleteAccountName,
      path: AppRoutes.deleteAccountPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const DeleteAccountPage()),
    ),
    GoRoute(
      name: AppRoutes.supportName,
      path: AppRoutes.supportPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SupportPage()),
    ),
    GoRoute(
      name: AppRoutes.aboutName,
      path: AppRoutes.aboutPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const AboutPage()),
    ),
  ],
);

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
