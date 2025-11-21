import 'package:flutter/foundation.dart';

/// مدل ساده پیام
class ChatMessage {
  final String text;
  final bool isFromSedi;

  ChatMessage({
    required this.text,
    required this.isFromSedi,
  });
}

/// کنترل اصلی چت
class ChatController extends ChangeNotifier {
  /// لیست پیام‌ها
  final List<ChatMessage> messages = [];

  /// آیا صدی در حال فکر کردن است؟
  bool isThinking = false;

  /// آیا کاربر در حال تایپ است؟
  bool isTyping = false;

  /// تغییر وضعیت تایپ
  void setTyping(bool value) {
    isTyping = value;
    notifyListeners();
  }

  /// ارسال پیام کاربر
  Future<void> sendUserMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // اضافه کردن پیام کاربر
    messages.add(ChatMessage(
      text: cleanText,
      isFromSedi: false,
    ));

    isTyping = false;
    isThinking = true;
    notifyListeners();

    // شبیه‌سازی تأخیر پاسخ (بعداً به بک‌اند واقعی وصل می‌شود)
    await Future.delayed(const Duration(milliseconds: 900));

    // ساخت پاسخ موقت صدی
    final reply = _dummyReply(cleanText);

    // اضافه کردن پیام صدی
    messages.add(ChatMessage(
      text: reply,
      isFromSedi: true,
    ));

    isThinking = false;
    notifyListeners();
  }

  /// پاسخ موقت برای تست UI
  String _dummyReply(String text) {
    return "پیامت رو گرفتم: «$text»\nبه زودی پاسخ‌های واقعی از بک‌اند نمایش داده میشه.";
  }
}
