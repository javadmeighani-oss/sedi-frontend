/// Backend-standard error payload: { code?, message }
/// See: frontend/docs/FRONTEND_BACKEND_ALIGNMENT.md
class ApiError {
  final String? code;
  final String message;

  const ApiError({
    this.code,
    required this.message,
  });

  factory ApiError.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApiError(message: 'Unknown error');
    return ApiError(
      code: json['code'] as String?,
      message: (json['message'] as String?) ?? 'Unknown error',
    );
  }

  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        'message': message,
      };

  @override
  String toString() => code != null ? '[$code] $message' : message;
}
