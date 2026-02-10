/// Chat response DTO aligned with backend InteractionResponse.
/// Fields: message, language, user_id, timestamp, requires_security_check?, detected_name?.

class InteractResponse {
  final String message;
  final String language;
  final int? userId;
  final String? timestamp;
  final bool requiresSecurityCheck;
  final String? detectedName;

  const InteractResponse({
    required this.message,
    this.language = 'en',
    this.userId,
    this.timestamp,
    this.requiresSecurityCheck = false,
    this.detectedName,
  });

  factory InteractResponse.fromJson(Map<String, dynamic> json) {
    return InteractResponse(
      message: json['message']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? ''),
      timestamp: json['timestamp']?.toString(),
      requiresSecurityCheck: json['requires_security_check'] == true,
      detectedName: json['detected_name']?.toString(),
    );
  }
}
