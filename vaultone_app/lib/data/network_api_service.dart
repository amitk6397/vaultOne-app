import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'base_api_service.dart';
import '../constants/app_url.dart';
import '../core/localization/app_language_controller.dart';
import '../core/security/secure_token_store.dart';

Future<String?>? _refreshTokenFuture;

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
        final token = await SecureTokenStore.instance.accessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('API -> ${options.method} ${options.uri}');
          if (options.data != null) {
            debugPrint('API request: ${options.data}');
          }
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
            request.extra['retried_after_refresh'] != true &&
            !request.path.endsWith('/auth/refresh')) {
          final refreshToken = await SecureTokenStore.instance.refreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              _refreshTokenFuture ??= _refreshSession(refreshToken);
              final accessToken = await _refreshTokenFuture;
              _refreshTokenFuture = null;

              if (accessToken != null && accessToken.isNotEmpty) {
                await SecureTokenStore.instance.write(
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                );
                request.headers['Authorization'] = 'Bearer $accessToken';
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

Future<String?> _refreshSession(String refreshToken) async {
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

  return accessToken;
}

Future<void> _clearSessionTokens() async {
  await SecureTokenStore.instance.clear();
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
