import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiServiceProvider));
});

class ProfileRepository {
  const ProfileRepository(this._api);

  final BaseApiService _api;

  Future<UserProfile> fetchProfile({String fallbackCity = ''}) async {
    final response = await _api.get(AppUrl.userProfile);
    final data = response is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>? ?? response
        : <String, dynamic>{};
    final profile = UserProfile.fromApi(data, fallbackCity: fallbackCity);
    await saveProfile(profile);
    return profile;
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    required String mobile,
    required String email,
    required String city,
  }) async {
    final response = await _api.put(
      AppUrl.userProfile,
      data: {
        'full_name': fullName,
        'phone': mobile,
        'email': email,
        'city': city,
      },
    );
    final data = response is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>? ?? response
        : <String, dynamic>{};
    final profile = UserProfile.fromApi(data, fallbackCity: city);
    await saveProfile(profile);
    return profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', profile.fullName);
    await prefs.setString('user_email', profile.email);
    await prefs.setString('user_phone', profile.mobile);
    await prefs.setString('user_city', profile.city);
  }

  Future<int> deleteDataSection(String section) async {
    final response = await _api.delete('${AppUrl.userData}/$section');
    final data = response is Map<String, dynamic> ? response['data'] : null;
    return data is Map<String, dynamic>
        ? (data['deleted_count'] as num?)?.toInt() ?? 0
        : 0;
  }

  Future<void> logout() async {
    await _api.post(AppUrl.userLogout);
  }
}
