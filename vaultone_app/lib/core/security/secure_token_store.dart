import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureTokenStore {
  SecureTokenStore._();
  static final instance = SecureTokenStore._();

  static const _access = 'vaultone_access_token';
  static const _refresh = 'vaultone_refresh_token';
  static const _type = 'vaultone_token_type';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<String?> accessToken() async {
    await _migrateLegacy();
    return _storage.read(key: _access);
  }

  Future<String?> refreshToken() async {
    await _migrateLegacy();
    return _storage.read(key: _refresh);
  }

  Future<bool> isLoggedIn() async {
    final access = await accessToken();
    if (access != null && access.isNotEmpty) return true;
    final refresh = await refreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> write({
    required String accessToken,
    String? refreshToken,
    String tokenType = 'bearer',
  }) async {
    await _storage.write(key: _access, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refresh, value: refreshToken);
    }
    await _storage.write(key: _type, value: tokenType);
    await _removeLegacy();
  }

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _type);
    await _removeLegacy();
  }

  Future<void> _migrateLegacy() async {
    if (await _storage.containsKey(key: _access)) return;
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access_token');
    if (access == null || access.isEmpty) return;
    await write(
      accessToken: access,
      refreshToken: prefs.getString('refresh_token'),
      tokenType: prefs.getString('token_type') ?? 'bearer',
    );
  }

  Future<void> _removeLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_type');
  }
}
