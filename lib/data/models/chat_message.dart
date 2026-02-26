/// ============================================
/// ChatMessage - Model
/// ============================================
///
/// RESPONSIBILITY:
/// - فقط data model
/// - بدون UI
/// - بدون logic
/// ============================================

enum ChatRole { user, assistant, system }

enum ChatMessageStatus { sending, sent, failed }

class ChatMessage {
  final String localId;
  final String? id;
  final String text;
  final ChatRole role;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? type; // نوع پیام: "normal", "notification"
  final String? title; // عنوان (برای notification)
  final List<String>? quickReplies; // پاسخ‌های سریع (برای notification)

  ChatMessage({
    String? localId,
    this.id,
    required this.text,
    required this.role,
    DateTime? createdAt,
    this.status = ChatMessageStatus.sent,
    this.type,
    this.title,
    this.quickReplies,
  })  : localId = localId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory ChatMessage.user({
    required String text,
    String? localId,
    ChatMessageStatus status = ChatMessageStatus.sending,
  }) {
    return ChatMessage(
      localId: localId,
      text: text,
      role: ChatRole.user,
      status: status,
    );
  }

  factory ChatMessage.assistant({
    required String text,
    String? localId,
  }) {
    return ChatMessage(
      localId: localId,
      text: text,
      role: ChatRole.assistant,
      status: ChatMessageStatus.sent,
    );
  }

  ChatMessage copyWith({
    String? text,
    ChatMessageStatus? status,
  }) {
    return ChatMessage(
      localId: localId,
      id: id,
      text: text ?? this.text,
      role: role,
      createdAt: createdAt,
      status: status ?? this.status,
      type: type,
      title: title,
      quickReplies: quickReplies,
    );
  }

  // Legacy compatibility
  bool get isSedi => role == ChatRole.assistant || role == ChatRole.system;
  bool get isUser => role == ChatRole.user;
}
