import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/auth_constants.dart';
import '../../../core/security/secure_token_store.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../notifications/repositories/notification_repository.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(
    ref.watch(profileRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  ),
);

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier(this._repository, this._notifications)
    : super(
        UserProfile(
          fullName: 'Amit Kumar',
          mobile: '+91 98765 43210',
          email: 'amit@vaultone.app',
          city: 'Delhi, India',
          memberSince: DateTime(2026, 1, 12),
          avatarInitials: 'AK',
          biometricLockEnabled: true,
          cloudBackupEnabled: true,
          pushAlertsEnabled: true,
        ),
      ) {
    loadSavedProfile();
  }

  final ProfileRepository _repository;
  final NotificationRepository _notifications;

  Future<void> loadSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final phone = prefs.getString('user_phone');
    final city = prefs.getString('user_city');
    state = state.copyWith(
      passwordSecurityEnabled: prefs.getBool('security_passwords') ?? true,
      secureNotesSecurityEnabled: prefs.getBool('security_notes') ?? true,
      filesSecurityEnabled: prefs.getBool('security_files') ?? false,
      photosSecurityEnabled: prefs.getBool('security_photos') ?? true,
      videosSecurityEnabled: prefs.getBool('security_videos') ?? true,
      scannerSecurityEnabled: prefs.getBool('security_scanner') ?? false,
    );
    if (name != null || email != null || phone != null) {
      state = state.copyWith(
        fullName: name ?? state.fullName,
        email: email ?? state.email,
        mobile: phone ?? state.mobile,
        city: city ?? state.city,
        avatarInitials: _initials(name ?? state.fullName),
      );
    }
    final token = await SecureTokenStore.instance.accessToken();
    if (token == null || token.isEmpty) return;
    try {
      final remote = await _repository.fetchProfile(
        fallbackCity: city ?? state.city,
      );
      state = remote.copyWith(
        passwordSecurityEnabled: state.passwordSecurityEnabled,
        secureNotesSecurityEnabled: state.secureNotesSecurityEnabled,
        filesSecurityEnabled: state.filesSecurityEnabled,
        photosSecurityEnabled: state.photosSecurityEnabled,
        videosSecurityEnabled: state.videosSecurityEnabled,
        scannerSecurityEnabled: state.scannerSecurityEnabled,
      );
    } catch (_) {
      // Keep the locally cached profile when the API is temporarily unavailable.
    }
  }

  Future<void> clearSession({required bool deleteSavedData}) async {
    // Start best-effort server cleanup, but never await network before clearing
    // the local session. Logout must work instantly while offline too.
    unawaited(_bestEffortRemoteLogout());
    final prefs = await SharedPreferences.getInstance();
    await SecureTokenStore.instance.clear();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_city');
    if (deleteSavedData) {
      final languageCode = prefs.getString(appLanguagePreferenceKey);
      final onboardingCompleted =
          prefs.getBool(AuthConstants.onboardingCompletedKey) ?? false;
      await prefs.clear();
      if (languageCode != null && languageCode.isNotEmpty) {
        await prefs.setString(appLanguagePreferenceKey, languageCode);
      }
      if (onboardingCompleted) {
        await prefs.setBool(AuthConstants.onboardingCompletedKey, true);
      }
    }
  }

  Future<void> _bestEffortRemoteLogout() async {
    try {
      await Future.wait([
        _notifications.unregisterStoredToken(),
        _repository.logout(),
      ]).timeout(const Duration(seconds: 5));
    } catch (_) {
      // The local session is authoritative for signing out this device.
    }
  }

  void updateProfile({
    required String fullName,
    required String mobile,
    required String email,
    required String city,
  }) {
    state = state.copyWith(
      fullName: fullName,
      mobile: mobile,
      email: email,
      city: city,
      avatarInitials: _initials(fullName),
    );
  }

  Future<void> updateProfileFromApi({
    required String fullName,
    required String mobile,
    required String email,
    required String city,
  }) async {
    state = await _repository.updateProfile(
      fullName: fullName,
      mobile: mobile,
      email: email,
      city: city,
    );
  }

  void setBiometricLock(bool value) {
    state = state.copyWith(biometricLockEnabled: value);
  }

  void setCloudBackup(bool value) {
    state = state.copyWith(cloudBackupEnabled: value);
  }

  void setPushAlerts(bool value) {
    state = state.copyWith(pushAlertsEnabled: value);
  }

  Future<void> setPasswordSecurity(bool value) async {
    state = state.copyWith(passwordSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool(
      'security_passwords',
      value,
    );
  }

  Future<void> setSecureNotesSecurity(bool value) async {
    state = state.copyWith(secureNotesSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool('security_notes', value);
  }

  Future<void> setFilesSecurity(bool value) async {
    state = state.copyWith(filesSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool('security_files', value);
  }

  Future<void> setPhotosSecurity(bool value) async {
    state = state.copyWith(photosSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool('security_photos', value);
  }

  Future<void> setVideosSecurity(bool value) async {
    state = state.copyWith(videosSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool('security_videos', value);
  }

  Future<void> setScannerSecurity(bool value) async {
    state = state.copyWith(scannerSecurityEnabled: value);
    (await SharedPreferences.getInstance()).setBool('security_scanner', value);
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
