import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';

class NotificationHandler {
  // ---------------------------------------------------------------------------------
  // تبدیل پاسخ خام بک‌اند به ChatMessage برای UI
  // بک‌اند ممکن است ساختار یا فیلدهای متفاوت ارسال کند، اینجا استانداردسازی می‌کنیم
  // ---------------------------------------------------------------------------------
  ChatMessage parseIncoming(Map<String, dynamic> json) {
    final String type = json["type"] ?? "normal";

    if (type == "notification") {
      return ChatMessage(
        id: json["id"] ?? UniqueKey().toString(),
        text: json["text"] ?? "",
        isUser: false,
        type: "notification",
        title: json["title"] ?? "Sedi",
        quickReplies: json["quick_replies"] != null
            ? List<String>.from(json["quick_replies"])
            : [],
      );
    }

    // پیام معمولی چت
    return ChatMessage(
      id: json["id"] ?? UniqueKey().toString(),
      text: json["text"] ?? "",
      isUser: json["is_user"] ?? false,
      type: "normal",
    );
  }
}
