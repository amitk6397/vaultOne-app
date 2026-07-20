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
    this.passwordSecurityEnabled = true,
    this.secureNotesSecurityEnabled = true,
    this.filesSecurityEnabled = false,
    this.photosSecurityEnabled = true,
    this.videosSecurityEnabled = true,
    this.scannerSecurityEnabled = false,
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
  final bool passwordSecurityEnabled;
  final bool secureNotesSecurityEnabled;
  final bool filesSecurityEnabled;
  final bool photosSecurityEnabled;
  final bool videosSecurityEnabled;
  final bool scannerSecurityEnabled;

  factory UserProfile.fromApi(
    Map<String, dynamic> json, {
    String fallbackCity = '',
  }) {
    final fullName = json['full_name'] as String? ?? '';
    return UserProfile(
      fullName: fullName,
      mobile: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      city: json['city'] as String? ?? fallbackCity,
      memberSince: DateTime.now(),
      avatarInitials: _initialsFrom(fullName),
      biometricLockEnabled: true,
      cloudBackupEnabled: true,
      pushAlertsEnabled: true,
    );
  }

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
    bool? passwordSecurityEnabled,
    bool? secureNotesSecurityEnabled,
    bool? filesSecurityEnabled,
    bool? photosSecurityEnabled,
    bool? videosSecurityEnabled,
    bool? scannerSecurityEnabled,
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
      passwordSecurityEnabled:
          passwordSecurityEnabled ?? this.passwordSecurityEnabled,
      secureNotesSecurityEnabled:
          secureNotesSecurityEnabled ?? this.secureNotesSecurityEnabled,
      filesSecurityEnabled: filesSecurityEnabled ?? this.filesSecurityEnabled,
      photosSecurityEnabled:
          photosSecurityEnabled ?? this.photosSecurityEnabled,
      videosSecurityEnabled:
          videosSecurityEnabled ?? this.videosSecurityEnabled,
      scannerSecurityEnabled:
          scannerSecurityEnabled ?? this.scannerSecurityEnabled,
    );
  }

  static String _initialsFrom(String name) {
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
