import 'api_error.dart';

/// Backend-standard response: { ok, data, error }
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
class ApiResponse<T> {
  final bool ok;
  final T? data;
  final ApiError? error;
  /// HTTP status code when available (e.g. from ApiClient); for logging/trace (Stage 19).
  final int? statusCode;

  const ApiResponse({
    required this.ok,
    this.data,
    this.error,
    this.statusCode,
  });

  /// Tolerant parsing for backend `ok` values (bool, 0/1, "true"/"false").
  static bool readEnvelopeOk(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return false;
  }

  /// Resolve success for HTTP 2xx envelope responses.
  static bool resolveEnvelopeSuccess({
    required Map<String, dynamic> json,
    required bool parsedOk,
    required bool hasData,
    required bool hasError,
  }) {
    if (json.containsKey('ok')) return parsedOk;
    if (hasError) return false;
    return hasData;
  }

  /// Parse from JSON. [parser] converts the raw "data" object to T (or null).
  /// Use for responses where "data" is an object or list.
  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T? Function(Object? dataJson) parser,
  ) {
    final parsedOk =
        json.containsKey('ok') ? readEnvelopeOk(json['ok']) : false;
    final errorJson = json['error'];
    ApiError? error = errorJson == null
        ? null
        : ApiError.fromJson(
            errorJson is Map ? Map<String, dynamic>.from(errorJson) : null,
          );
    T? data;
    final Object? rawPayload = json['data'];
    final payloadWasPresent = rawPayload != null;
    if (payloadWasPresent) {
      try {
        data = parser(rawPayload);
      } catch (_) {
        data = null;
      }
    }
    var ok = resolveEnvelopeSuccess(
      json: json,
      parsedOk: parsedOk,
      hasData: data != null,
      hasError: error != null,
    );
    if (json.containsKey('ok') && parsedOk && payloadWasPresent && data == null) {
      ok = false;
      error ??= const ApiError(
        code: 'PARSE_ERROR',
        message: 'Failed to parse success payload',
      );
    } else if (json.containsKey('ok') &&
        parsedOk &&
        !payloadWasPresent &&
        data == null) {
      ok = false;
      error ??= const ApiError(
        code: 'PARSE_ERROR',
        message: 'Missing response data',
      );
    }
    return ApiResponse<T>(ok: ok, data: data, error: error, statusCode: null);
  }

  bool get isSuccess => ok && error == null;
  String get errorMessage => error?.message ?? 'Unknown error';

  @override
  String toString() => 'ApiResponse(ok: $ok, data: $data, error: $error)';
}
/// Parser for calls whose answer is only an acknowledgement (create / patch / delete). The backend sends a `data` object
/// with them; a parser returning null made ApiResponse report PARSE_ERROR although the server had saved (Javad 2026-11-09).
Object? ackParser(Object? dataJson) => dataJson ?? true;
