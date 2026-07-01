class AppRoutes {
  const AppRoutes._();

  static const splashName = 'splash';
  static const splashPath = '/';

  static const onboardingName = 'onboarding';
  static const onboardingPath = '/onboarding';

  static const loginName = 'login';
  static const loginPath = '/login';

  static const registerName = 'register';
  static const registerPath = '/register';

  static const forgotPasswordName = 'forgot-password';
  static const forgotPasswordPath = '/forgot-password';

  static const verifyOtpName = 'verify-otp';
  static const verifyOtpPath = '/verify-otp';

  static const homeName = 'home';
  static const homePath = '/home';

  static const assetsName = 'assets';
  static const assetsPath = '/assets';

  static const documentsName = 'documents';
  static const documentsPath = '/documents';

  static const aiName = 'ai';
  static const aiPath = '/ai';

  static const passwordsName = 'passwords';
  static const passwordsPath = '/passwords';

  static const addEditPasswordName = 'add-edit-password';
  static const addEditPasswordPath = '/passwords/add-edit';

  static const passwordGeneratorName = 'password-generator';
  static const passwordGeneratorPath = '/passwords/generator';

  static const secureNotesName = 'secure-notes';
  static const secureNotesPath = '/passwords/secure-notes';

  static const breachCheckName = 'breach-check';
  static const breachCheckPath = '/passwords/breach-check';

  static const filesVaultName = 'files-vault';
  static const filesVaultPath = '/files-vault';

  static const photoGalleryName = 'photo-gallery';
  static const photoGalleryPath = '/photos';

  static const privatePhotosName = 'private-photos';
  static const privatePhotosPath = '/photos/private';

  static const publicPhotosName = 'public-photos';
  static const publicPhotosPath = '/photos/public';

  static const albumsName = 'albums';
  static const albumsPath = '/photos/albums';

  static const albumDetailsName = 'album-details';
  static const albumDetailsPath = '/photos/albums/:albumId';

  static const photoViewerName = 'photo-viewer';
  static const photoViewerPath = '/photos/viewer/:photoId';

  static const photoDetailsName = 'photo-details';
  static const photoDetailsPath = '/photos/details/:photoId';

  static const videoGalleryName = 'video-gallery';
  static const videoGalleryPath = '/videos';

  static const privateVideosName = 'private-videos';
  static const privateVideosPath = '/videos/private';

  static const publicVideosName = 'public-videos';
  static const publicVideosPath = '/videos/public';

  static const videoFoldersName = 'video-folders';
  static const videoFoldersPath = '/videos/folders';

  static const videoDetailsName = 'video-details';
  static const videoDetailsPath = '/videos/details/:videoId';

  static const videoPlayerName = 'video-player';
  static const videoPlayerPath = '/videos/player/:videoId';

  static const deletedMediaName = 'deleted-media';
  static const deletedMediaPath = '/media/deleted';

  static const mediaSecurityName = 'media-security';
  static const mediaSecurityPath = '/media/security';

  static const scannerName = 'scanner';
  static const scannerPath = '/scanner';

  static const profileName = 'profile';
  static const profilePath = '/profile';

  static const editProfileName = 'edit-profile';
  static const editProfilePath = '/profile/edit';

  static const privacyPolicyName = 'privacy-policy';
  static const privacyPolicyPath = '/profile/privacy-policy';

  static const securitySettingsName = 'security-settings';
  static const securitySettingsPath = '/profile/security';

  static const appSettingsName = 'app-settings';
  static const appSettingsPath = '/profile/settings';

  static const deleteAccountName = 'delete-account';
  static const deleteAccountPath = '/profile/delete-account';

  static const supportName = 'support';
  static const supportPath = '/profile/support';

  static const aboutName = 'about';
  static const aboutPath = '/profile/about';
}
