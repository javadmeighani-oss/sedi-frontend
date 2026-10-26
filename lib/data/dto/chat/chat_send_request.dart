class ChatSendRequest {
  final String message;
  final int? sourceNotificationId;
  final String? conversationId;
  final int? healthSubjectId;

  /// Device IANA timezone (R-026): reminders need the user's own clock, and the Profile has no timezone field.
  final String? timezone;

  const ChatSendRequest({
    required this.message,
    this.timezone,
    this.sourceNotificationId,
    this.conversationId,
    this.healthSubjectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (sourceNotificationId != null)
        'source_notification_id': sourceNotificationId,
      if (conversationId != null && conversationId!.isNotEmpty)
        'conversation_id': conversationId,
      if (healthSubjectId != null) 'health_subject_id': healthSubjectId,
      if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone,
      // JWT is identity authority — do not send body user_id.
    };
  }
}
