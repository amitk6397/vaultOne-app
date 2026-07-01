class UserProfile {
  const UserProfile({
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.city,
    required this.memberSince,
    required this.avatarInitials,
    required this.biometricLockEnabled,
    required this.cloudBackupEnabled,
    required this.pushAlertsEnabled,
  });

  final String fullName;
  final String mobile;
  final String email;
  final String city;
  final DateTime memberSince;
  final String avatarInitials;
  final bool biometricLockEnabled;
  final bool cloudBackupEnabled;
  final bool pushAlertsEnabled;

  UserProfile copyWith({
    String? fullName,
    String? mobile,
    String? email,
    String? city,
    DateTime? memberSince,
    String? avatarInitials,
    bool? biometricLockEnabled,
    bool? cloudBackupEnabled,
    bool? pushAlertsEnabled,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      city: city ?? this.city,
      memberSince: memberSince ?? this.memberSince,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      pushAlertsEnabled: pushAlertsEnabled ?? this.pushAlertsEnabled,
    );
  }
}
