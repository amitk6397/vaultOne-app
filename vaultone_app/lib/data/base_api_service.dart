abstract class BaseApiService {
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters});

  Future<dynamic> post(String endpoint, {Object? data});

  Future<dynamic> put(String endpoint, {Object? data});

  Future<dynamic> patch(String endpoint, {Object? data});

  Future<dynamic> delete(String endpoint);
}
