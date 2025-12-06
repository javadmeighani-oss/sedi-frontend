import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';
import '../chat_service.dart';

class ChatController extends ChangeNotifier {
  bool isThinking = false;
  bool isAlert = false;

  final List<ChatMessage> messages = [];
  final ChatService _chatService = ChatService();
  bool _isInitialized = false;

  /// مقداردهی اولیه - پیام خوش‌آمدگویی
  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // اضافه کردن پیام خوش‌آمدگویی
    Future.delayed(const Duration(milliseconds: 500), () {
      addSediMessage('سلام! من صدی هستم 😊\nچطور می‌تونم کمکت کنم؟');
    });
  }

  // -------------------------------
  //  ارسال پیام کاربر
  // -------------------------------
  Future<void> sendUserMessage(String text) async {
    messages.add(
      ChatMessage(text: text, isSedi: false),
    );

    isThinking = true;
    notifyListeners();

    try {
      // ارسال پیام به API واقعی
      final response = await _chatService.sendMessage(text);
      addSediMessage(response);
    } catch (e) {
      addSediMessage("خطا در ارسال پیام: ${e.toString()}");
    }
  }

  // -------------------------------
  //  پاسخ صدی
  // -------------------------------
  void addSediMessage(String text) {
    isThinking = false;

    messages.add(
      ChatMessage(text: text, isSedi: true),
    );

    notifyListeners();
  }

  // -------------------------------
  //  ورودی صوت (در آینده به API وصل می‌شود)
  // -------------------------------
  void startVoiceInput() {
    // Placeholder
    addSediMessage("در حال شنیدن صدای شما هستم...");
  }
}
