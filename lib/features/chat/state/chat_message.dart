import 'package:flutter/material.dart';

class ChatMessage {
  final String id; // ID پیام / نوتیف
  final String text; // متن پیام
  final bool isUser; // پیام کاربر یا صدی
  final String type; // normal / notification
  final String? title; // عنوان نوتیف
  final List<String>? quickReplies; // لیست پاسخ‌های سریع

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.type,
    this.title,
    this.quickReplies,
  });

  // دریافت داده از بک‌اند
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json["id"] ?? UniqueKey().toString(),
      text: json["text"] ?? "",
      isUser: json["is_user"] ?? false,
      type: json["type"] ?? "normal",
      title: json["title"],
      quickReplies: json["quick_replies"] != null
          ? List<String>.from(json["quick_replies"])
          : [],
    );
  }

  // ارسال پیام به بک‌اند
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "text": text,
      "is_user": isUser,
      "type": type,
      "title": title,
      "quick_replies": quickReplies,
    };
  }
}
