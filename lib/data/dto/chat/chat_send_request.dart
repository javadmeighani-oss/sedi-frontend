class ChatSendRequest {
  final int userId;
  final String message;

  const ChatSendRequest({
    required this.userId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
    };
  }
}
