import 'dart:io';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// The Phoenix dev server's host as seen from each run target. The
/// Android emulator can't reach the host machine via `localhost` — it
/// has to go through the special `10.0.2.2` alias instead.
String backendHost() {
  if (!Platform.isAndroid) return 'localhost';
  return '10.0.2.2';
}

const backendPort = 4000;

class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors});

  final String message;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => message;
}

/// Thin wrapper around Dio that attaches the stored bearer token to
/// every request and turns Phoenix's error shapes into [ApiException].
class ApiClient {
  ApiClient(this._tokenStorage)
      : dio = Dio(BaseOptions(baseUrl: 'http://${backendHost()}:$backendPort/api')) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) {
    return _unwrap(dio.post<Map<String, dynamic>>(path, data: data));
  }

  Future<Map<String, dynamic>> get(String path) {
    return _unwrap(dio.get<Map<String, dynamic>>(path));
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<void>(path);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> _unwrap(Future<Response<Map<String, dynamic>>> request) async {
    try {
      final response = await request;
      return response.data ?? {};
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      // ChangesetJSON's error shape: {"errors": {"email": ["has already been taken"]}}
      final errors = data['errors'];
      if (errors is Map) {
        final fieldErrors = errors.map(
          (key, value) => MapEntry(key.toString(), List<String>.from(value as List)),
        );
        final firstMessage = fieldErrors.values.firstOrNull?.firstOrNull;
        return ApiException(
          firstMessage ?? 'Something went wrong',
          fieldErrors: fieldErrors,
        );
      }
      // Plain {"error": "invalid email or password"} shape.
      final error = data['error'];
      if (error is String) return ApiException(error);
    }
    return ApiException(e.message ?? 'Network error');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
