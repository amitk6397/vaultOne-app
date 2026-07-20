import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../features/ai/views/ai_page.dart';
import '../features/auth/views/forgot_password_page.dart';
import '../features/auth/views/login_page.dart';
import '../features/auth/views/language_selection_page.dart';
import '../features/auth/views/onboarding_page.dart';
import '../features/auth/views/register_page.dart';
import '../features/auth/views/reset_password_page.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/verify_otp_page.dart';
import '../features/files_vault/views/files_vault_page.dart';
import '../features/files_vault/views/vault_file_detail_page.dart';
import '../features/files_vault/views/vault_files_list_page.dart';
import '../features/home/views/home_page_redesigned.dart';
import '../features/home/views/notifications_page.dart';
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
import '../features/profile/views/delete_data_page.dart';
import '../features/profile/views/edit_profile_page.dart';
import '../features/profile/views/privacy_policy_page.dart';
import '../features/profile/views/profile_page.dart';
import '../features/profile/views/security_settings_page.dart';
import '../features/profile/views/module_security_page.dart';
import '../features/scanner/views/scanner_page.dart';
import '../features/subscriptions/models/subscription_models.dart';
import '../features/subscriptions/views/payment_verification_page.dart';
import '../features/subscriptions/views/subscription_page.dart';
import '../features/vault_connect/models/connect_models.dart';
import '../features/vault_connect/views/chat_detail_page.dart';
import '../features/vault_connect/views/connect_management_pages.dart';
import '../features/vault_connect/views/contacts_pages.dart';
import '../features/vault_connect/views/vault_connect_home_page.dart';
import '../shared/widgets/local_auth_gate.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splashPath,
  routes: [
    GoRoute(
      name: AppRoutes.splashName,
      path: AppRoutes.splashPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const SplashScreen()),
    ),
    GoRoute(
      name: AppRoutes.languageName,
      path: AppRoutes.languagePath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const LanguageSelectionPage()),
    ),
    GoRoute(
      name: AppRoutes.onboardingName,
      path: AppRoutes.onboardingPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const OnboardingPage()),
    ),
    GoRoute(
      name: AppRoutes.loginName,
      path: AppRoutes.loginPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const LoginPage()),
    ),
    GoRoute(
      name: AppRoutes.registerName,
      path: AppRoutes.registerPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const RegisterPage()),
    ),
    GoRoute(
      name: AppRoutes.forgotPasswordName,
      path: AppRoutes.forgotPasswordPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const ForgotPasswordPage()),
    ),
    GoRoute(
      name: AppRoutes.verifyOtpName,
      path: AppRoutes.verifyOtpPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const VerifyOtpPage()),
    ),
    GoRoute(
      name: AppRoutes.resetPasswordName,
      path: AppRoutes.resetPasswordPath,
      pageBuilder: (context, state) =>
          _authPage(state: state, child: const ResetPasswordPage()),
    ),
    GoRoute(
      name: AppRoutes.subscriptionsName,
      path: AppRoutes.subscriptionsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const SubscriptionPage()),
    ),
    GoRoute(
      name: AppRoutes.paymentVerificationName,
      path: AppRoutes.paymentVerificationPath,
      pageBuilder: (context, state) {
        final payment = state.extra;
        return _fadePage(
          state: state,
          child: payment is UpiPaymentRequest
              ? PaymentVerificationPage(payment: payment)
              : const SubscriptionPage(),
        );
      },
    ),
    GoRoute(
      name: AppRoutes.homeName,
      path: AppRoutes.homePath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const HomePage()),
    ),
    GoRoute(
      name: AppRoutes.notificationsName,
      path: AppRoutes.notificationsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const NotificationsPage()),
    ),
    GoRoute(
      name: AppRoutes.connectHomeName,
      path: AppRoutes.connectHomePath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const VaultConnectHomePage()),
    ),
    GoRoute(
      name: AppRoutes.connectPermissionName,
      path: AppRoutes.connectPermissionPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ContactPermissionInfoPage()),
    ),
    GoRoute(
      name: AppRoutes.connectContactsName,
      path: AppRoutes.connectContactsPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const RegisteredContactsPage()),
    ),
    GoRoute(
      name: AppRoutes.connectChatName,
      path: AppRoutes.connectChatPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: state.extra is ConnectConversation
            ? ChatDetailPage(conversation: state.extra! as ConnectConversation)
            : const VaultConnectHomePage(),
      ),
    ),
    GoRoute(
      name: AppRoutes.connectVaultPickerName,
      path: AppRoutes.connectVaultPickerPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          enabled: true,
          title: 'Unlock your Vault',
          reason: 'Authenticate to select a file for secure transfer',
          child: VaultConnectFilePickerPage(
            conversationId: state.pathParameters['conversationId'] ?? '',
          ),
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.connectPreviewName,
      path: AppRoutes.connectPreviewPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: state.extra is PickedConnectFile
            ? AttachmentPreviewPage(
                conversationId: state.pathParameters['conversationId'] ?? '',
                file: state.extra! as PickedConnectFile,
              )
            : const VaultConnectHomePage(),
      ),
    ),
    GoRoute(
      name: AppRoutes.connectSettingsName,
      path: AppRoutes.connectSettingsPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: state.extra is ConnectConversation
            ? ChatSettingsPage(
                conversation: state.extra! as ConnectConversation,
              )
            : const VaultConnectHomePage(),
      ),
    ),
    GoRoute(
      name: AppRoutes.connectSharedName,
      path: AppRoutes.connectSharedPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: SharedMediaDocumentsPage(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.connectBlockedName,
      path: AppRoutes.connectBlockedPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const BlockedUsersPage()),
    ),
    GoRoute(
      name: AppRoutes.connectReportName,
      path: AppRoutes.connectReportPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: state.extra is ConnectConversation
            ? ReportUserPage(conversation: state.extra! as ConnectConversation)
            : const VaultConnectHomePage(),
      ),
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
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          section: VaultSecuritySection.passwords,
          title: context.l10n.tr('password_vault'),
          reason: context.l10n.tr('unlock_password_vault'),
          child: const PasswordsPage(),
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.addEditPasswordName,
      path: AppRoutes.addEditPasswordPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: AddEditPasswordPage(passwordId: state.uri.queryParameters['id']),
      ),
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
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          section: VaultSecuritySection.secureNotes,
          title: context.l10n.tr('secure_notes'),
          reason: context.l10n.tr('unlock_secure_notes'),
          child: const SecureNotesPage(),
        ),
      ),
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
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          section: VaultSecuritySection.files,
          title: context.l10n.tr('files_vault'),
          reason: context.l10n.tr('unlock_files_vault'),
          child: const FilesVaultPage(),
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.filesVaultFilesName,
      path: AppRoutes.filesVaultFilesPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const VaultFilesListPage(mode: VaultFilesMode.public),
      ),
    ),
    GoRoute(
      name: AppRoutes.filesVaultPrivateName,
      path: AppRoutes.filesVaultPrivatePath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          enabled: true,
          section: VaultSecuritySection.files,
          title: context.l10n.tr('private_files'),
          reason: context.l10n.tr('unlock_private_files'),
          child: const VaultFilesListPage(mode: VaultFilesMode.private),
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.filesVaultArchiveName,
      path: AppRoutes.filesVaultArchivePath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: const VaultFilesListPage(mode: VaultFilesMode.archive),
      ),
    ),
    GoRoute(
      name: AppRoutes.filesVaultPreviewName,
      path: AppRoutes.filesVaultPreviewPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: VaultFileDetailPage(
          fileId: state.pathParameters['fileId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.photoGalleryName,
      path: AppRoutes.photoGalleryPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ProtectedPhotoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.privatePhotosName,
      path: AppRoutes.privatePhotosPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ProtectedPhotoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.publicPhotosName,
      path: AppRoutes.publicPhotosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: FilteredMediaPage(
          title: context.l10n.tr('public_photos'),
          subtitle: context.l10n.tr('public_photos_subtitle'),
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
          _fadePage(state: state, child: const ProtectedVideoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.privateVideosName,
      path: AppRoutes.privateVideosPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const ProtectedVideoGalleryPage()),
    ),
    GoRoute(
      name: AppRoutes.publicVideosName,
      path: AppRoutes.publicVideosPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: FilteredMediaPage(
          title: context.l10n.tr('public_videos'),
          subtitle: context.l10n.tr('public_videos_subtitle'),
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
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          section: VaultSecuritySection.scanner,
          title: context.l10n.tr('ai_scanner'),
          reason: context.l10n.tr('unlock_ai_scanner'),
          child: const ScannerPage(),
        ),
      ),
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
      name: AppRoutes.moduleSecurityName,
      path: AppRoutes.moduleSecurityPath,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: LocalAuthGate(
          enabled: true,
          title: context.l10n.tr('module_security'),
          reason: context.l10n.tr('confirm_module_security_identity'),
          child: const ModuleSecurityPage(),
        ),
      ),
    ),
    GoRoute(
      name: AppRoutes.deleteDataName,
      path: AppRoutes.deleteDataPath,
      pageBuilder: (context, state) =>
          _fadePage(state: state, child: const DeleteDataPage()),
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

CustomTransitionPage<void> _authPage({
  required GoRouterState state,
  required Widget child,
}) {
  return _fadePage(
    state: state,
    child: Theme(data: AppTheme.light(), child: child),
  );
}

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
