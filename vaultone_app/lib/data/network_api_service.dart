import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'base_api_service.dart';
import '../constants/app_url.dart';
import '../core/localization/app_language_controller.dart';
import '../core/security/secure_token_store.dart';

typedef _SessionTokens = ({String accessToken, String refreshToken});

Future<_SessionTokens?>? _refreshTokenFuture;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppUrl.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        options.headers['Accept-Language'] =
            prefs.getString(appLanguagePreferenceKey) ?? 'en';
        if (_isVaultOneApi(options.uri)) {
          var token = await SecureTokenStore.instance.accessToken();
          if (_tokenNeedsRefresh(token) &&
              !options.path.endsWith('/auth/refresh')) {
            final storedRefresh = await SecureTokenStore.instance
                .refreshToken();
            if (storedRefresh != null && storedRefresh.isNotEmpty) {
              final refresh = _refreshTokenFuture ??= _refreshSession(
                storedRefresh,
              );
              try {
                final session = await refresh;
                token = session?.accessToken;
              } finally {
                if (identical(_refreshTokenFuture, refresh)) {
                  _refreshTokenFuture = null;
                }
              }
            }
          } else {
            final activeRefresh = _refreshTokenFuture;
            final refreshed = activeRefresh == null
                ? null
                : await activeRefresh;
            token = refreshed?.accessToken ?? token;
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } else {
          options.headers.remove('Authorization');
        }
        if (kDebugMode) {
          debugPrint('API -> ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            'API <- ${response.statusCode} ${response.requestOptions.uri}',
          );
          debugPrint('API response: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint(
            'API !! ${error.response?.statusCode} ${error.requestOptions.uri}',
          );
          debugPrint('API error: ${error.response?.data ?? error.message}');
        }
        final request = error.requestOptions;
        if (error.response?.statusCode == 401 &&
            _isVaultOneApi(request.uri) &&
            request.extra['skip_auth_refresh'] != true &&
            request.extra['retried_after_refresh'] != true &&
            !request.path.endsWith('/auth/refresh')) {
          final refreshToken = await SecureTokenStore.instance.refreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refresh = _refreshTokenFuture ??= _refreshSession(
                refreshToken,
              );
              final session = await refresh;
              if (identical(_refreshTokenFuture, refresh)) {
                _refreshTokenFuture = null;
              }

              if (session != null) {
                request.headers['Authorization'] =
                    'Bearer ${session.accessToken}';
                request.extra['retried_after_refresh'] = true;
                return handler.resolve(await dio.fetch(request));
              }
            } on DioException catch (_) {
              _refreshTokenFuture = null;
              await _clearSessionTokens();
            } catch (_) {
              _refreshTokenFuture = null;
              await _clearSessionTokens();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

Future<_SessionTokens?> _refreshSession(String refreshToken) async {
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppUrl.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  final response = await refreshDio.post<Map<String, dynamic>>(
    AppUrl.userRefresh,
    data: {'refresh_token': refreshToken},
  );
  final data = response.data?['data'] as Map<String, dynamic>?;
  final accessToken = data?['access_token']?.toString();
  final rotatedRefreshToken = data?['refresh_token']?.toString();
  final tokenType = data?['token_type']?.toString();

  if (accessToken == null || accessToken.isEmpty) {
    await _clearSessionTokens();
    return null;
  }

  await SecureTokenStore.instance.write(
    accessToken: accessToken,
    refreshToken: rotatedRefreshToken ?? refreshToken,
    tokenType: tokenType ?? 'bearer',
  );

  return (
    accessToken: accessToken,
    refreshToken: rotatedRefreshToken ?? refreshToken,
  );
}

Future<void> _clearSessionTokens() async {
  await SecureTokenStore.instance.clear();
}

bool _isVaultOneApi(Uri uri) {
  final api = Uri.parse(AppUrl.baseUrl);
  return uri.scheme == api.scheme &&
      uri.host == api.host &&
      _port(uri) == _port(api);
}

int _port(Uri uri) => uri.hasPort
    ? uri.port
    : uri.scheme == 'https'
    ? 443
    : 80;

bool _tokenNeedsRefresh(String? token) {
  if (token == null || token.isEmpty) return false;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final expiresAt = payload is Map ? payload['exp'] as num? : null;
    if (expiresAt == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt.toInt() <= now + 30;
  } catch (_) {
    return true;
  }
}

final apiServiceProvider = Provider<BaseApiService>((ref) {
  return NetworkApiService(ref.watch(dioProvider));
});

class NetworkApiService implements BaseApiService {
  const NetworkApiService(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _request(() => _dio.get(endpoint, queryParameters: queryParameters));
  }

  @override
  Future<dynamic> post(String endpoint, {Object? data}) async {
    return _request(() => _dio.post(endpoint, data: data));
  }

  @override
  Future<dynamic> put(String endpoint, {Object? data}) async {
    return _request(() => _dio.put(endpoint, data: data));
  }

  @override
  Future<dynamic> patch(String endpoint, {Object? data}) async {
    return _request(() => _dio.patch(endpoint, data: data));
  }

  @override
  Future<dynamic> delete(String endpoint) async {
    return _request(() => _dio.delete(endpoint));
  }

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (error) {
      final data = error.response?.data;
      final detail = data is Map<String, dynamic> ? data['detail'] : null;
      final message = detail is Map
          ? detail['message']?.toString()
          : detail?.toString() ?? error.message;
      throw ApiException(
        message ?? 'Something went wrong',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
