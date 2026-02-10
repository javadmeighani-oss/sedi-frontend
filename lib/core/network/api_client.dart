import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'api_error.dart';
import 'api_response.dart';

/// Centralized HTTP client returning backend-standard ApiResponse<T>.
/// Maps HTTP and network errors to ApiResponse(ok: false, error: ApiError).
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
class ApiClient {
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET [path] with optional [queryParams]. Returns ApiResponse<T> using [parser] for body["data"].
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    required T? Function(Object? dataJson) parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(timeout, onTimeout: () {
        throw Exception('Request timeout');
      });

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _failureFromException(e);
    }
  }

  /// POST [path] with optional [body] and [queryParams]. Returns ApiResponse<T> using [parser] for body["data"].
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    required T? Function(Object? dataJson) parser,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await http
          .post(
            uri,
            headers: await _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout, onTimeout: () {
        throw Exception('Request timeout');
      });

      return _handleResponse<T>(response, parser);
    } catch (e) {
      return _failureFromException(e);
    }
  }

  /// GET that returns raw JSON as data (no parser). Use when you need the whole envelope as Map.
  Future<ApiResponse<Map<String, dynamic>>> getRaw(String path,
      {Map<String, String>? queryParams}) async {
    return get<Map<String, dynamic>>(
      path,
      queryParams: queryParams,
      parser: (v) =>
          v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// POST that returns raw JSON as data.
  Future<ApiResponse<Map<String, dynamic>>> postRaw(String path,
      {Map<String, dynamic>? body}) async {
    return post<Map<String, dynamic>>(
      path,
      body: body,
      parser: (v) =>
          v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T? Function(Object? dataJson) parser,
  ) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return ApiResponse<T>(
        ok: false,
        error: ApiError(
          code: 'PARSE_ERROR',
          message: 'Invalid JSON: ${response.body.length} bytes',
        ),
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.fromJson<T>(json, parser);
    }

    // HTTP error: map to ApiResponse with error from body or status
    final errorJson = json['error'];
    final ApiError error = errorJson != null && errorJson is Map
        ? ApiError.fromJson(Map<String, dynamic>.from(errorJson))
        : ApiError(
            code: 'HTTP_${response.statusCode}',
            message: json['detail']?.toString() ??
                json['message']?.toString() ??
                'Request failed with status ${response.statusCode}',
          );
    return ApiResponse<T>(ok: false, error: error);
  }

  ApiResponse<T> _failureFromException<T>(Object e) {
    final msg = e.toString();
    String code = 'NETWORK_ERROR';
    if (msg.toLowerCase().contains('timeout')) code = 'TIMEOUT';
    if (msg.toLowerCase().contains('connection refused') ||
        msg.toLowerCase().contains('socketexception') ||
        msg.toLowerCase().contains('failed host lookup')) {
      code = 'CONNECTION_ERROR';
    }
    return ApiResponse<T>(
      ok: false,
      error: ApiError(code: code, message: msg),
    );
  }
}
