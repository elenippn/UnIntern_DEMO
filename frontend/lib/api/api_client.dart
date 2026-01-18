import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));

  Future<String?> getToken() => storage.read(key: 'token');
  Future<void> setToken(String token) =>
      storage.write(key: 'token', value: token);
  Future<void> clearToken() => storage.delete(key: 'token');

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final token = await getToken();
    final fullUrl = '${dio.options.baseUrl}$path';
    print('═══════════════════════════════════════════');
    print('🔵 API GET REQUEST');
    print('Base URL: ${dio.options.baseUrl}');
    print('Path: $path');
    print('Full URL: $fullUrl');
    print('Query Parameters: $queryParameters');
    print('═══════════════════════════════════════════');
    
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null),
    );
  }

  Future<Response<T>> post<T>(String path, {Map<String, dynamic>? data}) async {
    final token = await getToken();
    return dio.post<T>(
      path,
      data: data,
      options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null),
    );
  }

  Future<Response<T>> put<T>(String path, {Map<String, dynamic>? data}) async {
    final token = await getToken();
    return dio.put<T>(
      path,
      data: data,
      options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null),
    );
  }

  Future<Response<T>> delete<T>(String path) async {
    final token = await getToken();
    return dio.delete<T>(
      path,
      options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null),
    );
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData data,
  }) async {
    final token = await getToken();
    return dio.post<T>(
      path,
      data: data,
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        contentType: 'multipart/form-data',
      ),
    );
  }
}
