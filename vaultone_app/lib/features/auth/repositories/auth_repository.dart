import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../../../core/security/secure_token_store.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../models/request/auth_requests.dart';
import '../models/response/auth_response.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiServiceProvider),
    ref.watch(notificationRepositoryProvider),
  );
});

class AuthRepository {
  const AuthRepository(this._api, this._notifications);

  final BaseApiService _api;
  final NotificationRepository _notifications;

  Future<String?> register(RegisterRequest request) async {
    final response = await _api.post(
      AppUrl.userRegister,
      data: request.toJson(),
    );
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data['otp'] as String?;
      }
    }
    return null;
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _api.post(AppUrl.userLogin, data: request.toJson());
    final auth = AuthResponse.fromJson(_unwrapData(response));
    await _saveSession(auth);
    return auth;
  }

  Future<String?> sendLoginOtp(String email) async {
    final response = await _api.post(AppUrl.loginOtp, data: {'email': email});
    return _extractOtp(response);
  }

  Future<String?> forgotPassword(String identity) async {
    final response = await _api.post(
      AppUrl.forgotPassword,
      data: {'identity': identity},
    );
    return _extractOtp(response);
  }

  Future<AuthResponse?> verifyOtp({
    required String identity,
    required String otp,
    required String purpose,
  }) async {
    final response = await _api.post(
      AppUrl.verifyOtp,
      data: {'identity': identity, 'otp': otp, 'purpose': purpose},
    );
    final data = _unwrapNullableData(response);
    if (data != null && data.containsKey('access_token')) {
      final auth = AuthResponse.fromJson(data);
      await _saveSession(auth);
      return auth;
    }
    return null;
  }

  Future<String?> resendOtp({
    required String identity,
    required String purpose,
  }) async {
    final response = await _api.post(
      AppUrl.resendOtp,
      data: {'identity': identity, 'purpose': purpose},
    );
    return _extractOtp(response);
  }

  Future<void> resetPassword({
    required String identity,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    await _api.post(
      AppUrl.resetPassword,
      data: {
        'identity': identity,
        'otp': otp,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<void> _saveSession(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await SecureTokenStore.instance.write(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      tokenType: auth.tokenType,
    );
    await prefs.setInt('user_id', auth.user.id);
    await prefs.setString('user_name', auth.user.fullName);
    await prefs.setString('user_email', auth.user.email);
    await prefs.setString('user_phone', auth.user.phone);
    await _notifications.syncStoredToken();
  }

  Map<String, dynamic> _unwrapData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return {};
  }

  Map<String, dynamic>? _unwrapNullableData(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (response.containsKey('access_token')) return response;
    }
    return null;
  }

  String? _extractOtp(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return data['otp'] as String?;
      }
    }
    return null;
  }
}
