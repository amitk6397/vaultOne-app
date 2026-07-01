import 'package:flutter_riverpod/legacy.dart';

import '../models/user_profile.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier()
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
      );

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

  void setBiometricLock(bool value) {
    state = state.copyWith(biometricLockEnabled: value);
  }

  void setCloudBackup(bool value) {
    state = state.copyWith(cloudBackupEnabled: value);
  }

  void setPushAlerts(bool value) {
    state = state.copyWith(pushAlertsEnabled: value);
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
