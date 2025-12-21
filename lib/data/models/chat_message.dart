/// ============================================
/// ChatMessage - Model
/// ============================================
/// 
/// RESPONSIBILITY:
/// - فقط data model
/// - بدون UI
/// - بدون logic
/// ============================================

class ChatMessage {
  final String? id;
  final String text;
  final bool isSedi; // آیا پیام از طرف صدی است؟
  final bool isUser; // آیا پیام از طرف کاربر است؟ (برای سازگاری با notification)
  final String? type; // نوع پیام: "normal", "notification"
  final String? title; // عنوان (برای notification)
  final List<String>? quickReplies; // پاسخ‌های سریع (برای notification)

  ChatMessage({
    this.id,
    required this.text,
    required this.isSedi,
    this.isUser = false,
    this.type,
    this.title,
    this.quickReplies,
  });
}
