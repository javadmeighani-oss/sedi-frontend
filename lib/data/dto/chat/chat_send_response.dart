class ChatSendResponse {
  final String message;
  final String language;
  final int? userId;
  final DateTime? timestamp;
  final bool requiresSecurityCheck;
  final String? detectedName;

  const ChatSendResponse({
    required this.message,
    required this.language,
    this.userId,
    this.timestamp,
    this.requiresSecurityCheck = false,
    this.detectedName,
  });

  factory ChatSendResponse.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'];
    return ChatSendResponse(
      message: json['message']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      userId: rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId?.toString() ?? ''),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      requiresSecurityCheck: json['requires_security_check'] as bool? ?? false,
      detectedName: json['detected_name']?.toString(),
    );
  }
}
