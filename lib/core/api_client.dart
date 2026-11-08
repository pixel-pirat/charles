import 'dart:io';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Points at the deployed Render backend by default — real device or
/// desktop, no local server or LAN setup required.
///
/// Override with `--dart-define=API_BASE_URL=<url>` to hit a local
/// dev server instead, e.g.:
///   --dart-define=API_BASE_URL=http://localhost:4000/api
///   --dart-define=API_BASE_URL=http://10.0.2.2:4000/api       (Android emulator)
///   --dart-define=API_BASE_URL=http://192.168.1.23:4000/api   (real device, same Wi-Fi as the dev machine)
const _prodBaseUrl = 'https://charles-80p2.onrender.com/api';

String apiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  return _prodBaseUrl;
}

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
      : dio = Dio(BaseOptions(baseUrl: apiBaseUrl())) {
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

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? data}) {
    return _unwrap(dio.patch<Map<String, dynamic>>(path, data: data));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _unwrap(dio.get<Map<String, dynamic>>(path, queryParameters: query));
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<void>(path);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Some DELETE endpoints (e.g. deleting a chat message for everyone)
  /// return the updated resource instead of a bare 204.
  Future<Map<String, dynamic>> deleteExpectingBody(String path) {
    return _unwrap(dio.delete<Map<String, dynamic>>(path));
  }

  /// Uploads a local file as multipart/form-data under field "file" —
  /// matches POST /api/media's contract. Returns the public URL.
  Future<String> uploadFile(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split(Platform.pathSeparator).last),
    });
    final json = await _unwrap(dio.post<Map<String, dynamic>>('/media', data: form));
    return json['url'] as String;
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
