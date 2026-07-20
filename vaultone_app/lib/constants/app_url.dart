class AppUrl {
  const AppUrl._();

  static const baseUrl = "http://192.168.1.26:8000/api/v1/";

  static const userLogin = '${baseUrl}user/auth/login';
  static const userLogout = '${baseUrl}user/auth/logout';
  static const userRefresh = '${baseUrl}user/auth/refresh';
  static const loginOtp = '${baseUrl}user/auth/login/otp';
  static const userRegister = '${baseUrl}user/auth/register';
  static const forgotPassword = '${baseUrl}user/auth/forgot-password';
  static const verifyOtp = '${baseUrl}user/auth/verify-otp';
  static const resetPassword = '${baseUrl}user/auth/reset-password';
  static const resendOtp = '${baseUrl}user/auth/resend-otp';
  static const onboarding = '${baseUrl}user/auth/onboarding';
  static const banners = '${baseUrl}user/banners';
  static const userProfile = '${baseUrl}user/profile/me';
  static const userData = '${baseUrl}user/profile/data';
  static const userFiles = '${baseUrl}user/files';
  static const userMedia = '${baseUrl}user/media';
  static const userDocuments = '${baseUrl}user/documents';
  static const userPasswords = '${baseUrl}user/passwords';
  static const userSecureNotes = '${baseUrl}user/secure-notes';
  static const userAiChat = '${baseUrl}user/ai/chat';
  static const userAiOcr = '${baseUrl}user/ai/ocr';
  static const privacyPolicy = '${baseUrl}user/policies/privacy';
  static const termsPolicy = '${baseUrl}user/policies/terms-and-conditions';
  static const notificationDeviceToken =
      '${baseUrl}user/notifications/device-token';
  static const unregisterNotificationDeviceToken =
      '${baseUrl}user/notifications/device-token/unregister';
  static const userNotifications = '${baseUrl}user/notifications';
  static const notificationCount = '$userNotifications/count';
  static const readAllNotifications = '$userNotifications/read-all';
  static const deleteAllNotifications = '$userNotifications/all';
  static const subscriptionPlans = '${baseUrl}subscription/plans';
  static const createSubscriptionPayment =
      '${baseUrl}subscription/create-payment';
  static const submitSubscriptionPayment =
      '${baseUrl}subscription/submit-payment';
  static const subscriptionStatus = '${baseUrl}subscription/status';
  static const supportContent = '${baseUrl}user/support/content';
  static const supportMessages = '${baseUrl}user/support/messages';

  // Vault Connect
  static const connectContactsDiscover = '${baseUrl}contacts/discover';
  static const connectDirectConversation = '${baseUrl}conversations/direct';
  static const connectConversations = '${baseUrl}conversations';
  static const connectMessages = '${baseUrl}messages';
  static const connectAttachments = '${baseUrl}attachments';
  static const connectInitUpload = '$connectAttachments/init-upload';
  static const connectBlockedUsers = '${baseUrl}users/blocked';
  static const connectUsers = '${baseUrl}users';
  static const connectReports = '${baseUrl}reports';

  static String connectConversation(String id) => '$connectConversations/$id';
  static String connectConversationMessages(String id) =>
      '${connectConversation(id)}/messages';
  static String connectDisappearingMessages(String id) =>
      '${connectConversation(id)}/disappearing-messages';
  static String connectClearConversation(String id) =>
      '${connectConversation(id)}/clear';
  static String connectMessageDelivered(String id) =>
      '$connectMessages/$id/delivered';
  static String connectMessageRead(String id) => '$connectMessages/$id/read';
  static String connectDeleteMessage(String id, {required bool everyone}) =>
      '$connectMessages/$id?scope=${everyone ? 'everyone' : 'me'}';
  static String connectAttachmentContent(String id) =>
      '$connectAttachments/$id/content';
  static String connectAttachmentComplete(String id) =>
      '$connectAttachments/$id/complete';
  static String connectAttachmentCancel(String id) =>
      '$connectAttachments/$id/cancel';
  static String connectAttachmentDownloadUrl(String id) =>
      '$connectAttachments/$id/download-url';
  static String connectBlockUser(int id) => '$connectUsers/$id/block';

  static Uri connectSocketUri(String accessToken) {
    final api = Uri.parse(baseUrl);
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/v1/ws/vault-connect',
      queryParameters: {'token': accessToken},
    );
  }

  static bool isRemoteUrl(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.startsWith('//')) return true;
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }

  static bool isNetworkResourceUrl(String? value) {
    final normalized = value?.trim() ?? '';
    return isRemoteUrl(normalized) ||
        normalized.startsWith('/uploads/') ||
        normalized.startsWith('uploads/') ||
        normalized.startsWith('/api/');
  }

  static String resolveResourceUrl(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return '';
    if (normalized.startsWith('//')) return 'https:$normalized';
    if (isRemoteUrl(normalized)) return normalized;

    final apiUri = Uri.parse(baseUrl);
    final backendOrigin = Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: '/',
    );
    return backendOrigin.resolve(normalized).toString();
  }
}
