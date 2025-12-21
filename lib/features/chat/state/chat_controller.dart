import 'package:flutter/material.dart';

import '../../../../core/utils/language_detector.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../data/model/chat_message.dart';
import '../chat_service.dart';

enum OnboardingState {
  none,
  askingName,
  askingPassword,
  completed,
}

class ChatController extends ChangeNotifier {
  // ===============================
  // UI States
  // ===============================

  bool isThinking = false;
  bool isAlert = false;

  // ===============================
  // Language & Onboarding
  // ===============================

  String currentLanguage = 'en';
  OnboardingState onboardingState = OnboardingState.none;

  String? userName;
  String? userPassword;

  // ===============================
  // Voice Recording
  // ===============================

  bool isRecording = false;
  int recordingDuration = 0;

  // ===============================
  // Messages
  // ===============================

  final List<ChatMessage> messages = [];

  final ChatService _chatService = ChatService();
  bool _initialized = false;

  // ===============================
  // Initialization
  // ===============================

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final isFirstTime = await UserPreferences.isFirstTime();

    if (isFirstTime) {
      onboardingState = OnboardingState.askingName;
      currentLanguage = 'en';
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 600), () {
        _addSediMessage(AppMessages.getWelcomeMessage('en'));
      });

      Future.delayed(const Duration(milliseconds: 1400), () {
        _addSediMessage(AppMessages.getNameRequest('en'));
      });
    } else {
      userName = await UserPreferences.getUserName();
      currentLanguage = await UserPreferences.getUserLanguage();

      onboardingState = OnboardingState.completed;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _addSediMessage(
          AppMessages.getWelcomeBack(currentLanguage, userName ?? ''),
        );
      });
    }
  }

  // ===============================
  // User Text Message
  // ===============================

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Language detection only AFTER onboarding
    if (onboardingState == OnboardingState.completed) {
      final detectedLang = LanguageDetector.detectLanguage(trimmed);
      if (detectedLang != currentLanguage) {
        currentLanguage = detectedLang;
        await UserPreferences.saveUserLanguage(currentLanguage);
      }
    }

    // ---------------------------
    // Onboarding flow
    // ---------------------------

    if (onboardingState == OnboardingState.askingName) {
      userName = trimmed;
      await UserPreferences.saveUserName(userName!);

      onboardingState = OnboardingState.askingPassword;
      notifyListeners();

      _addSediMessage(
        AppMessages.getPasswordRequest(currentLanguage),
      );
      return;
    }

    if (onboardingState == OnboardingState.askingPassword) {
      userPassword = trimmed;
      await UserPreferences.saveUserPassword(userPassword!);
      await UserPreferences.setNotFirstTime();
      await UserPreferences.saveUserLanguage(currentLanguage);

      onboardingState = OnboardingState.completed;
      notifyListeners();

      _addSediMessage(
        currentLanguage == 'fa'
            ? 'عالی! حالا می‌تونیم شروع کنیم 😊'
            : currentLanguage == 'ar'
                ? 'رائع! الآن يمكننا البدء 😊'
                : 'Great! Now we can start 😊',
      );
      return;
    }

    // ---------------------------
    // Normal chat
    // ---------------------------

    messages.add(
      ChatMessage(
        text: trimmed,
        isSedi: false,
      ),
    );

    isThinking = true;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(trimmed);

      if (response.isEmpty ||
          response == 'NETWORK_ERROR' ||
          response == 'AUTH_REQUIRED') {
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'مشکلی در ارتباط پیش آمد.'
              : currentLanguage == 'ar'
                  ? 'حدثت مشكلة في الاتصال.'
                  : 'Connection issue occurred.',
        );
      } else {
        _addSediMessage(response);
      }
    } catch (_) {
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'خطا در ارسال پیام'
            : currentLanguage == 'ar'
                ? 'خطأ في إرسال الرسالة'
                : 'Error sending message',
      );
    }
  }

  // ===============================
  // Sedi Message
  // ===============================

  void _addSediMessage(String text) {
    isThinking = false;

    messages.add(
      ChatMessage(
        text: text,
        isSedi: true,
      ),
    );

    notifyListeners();
  }

  // ===============================
  // Voice Recording
  // ===============================

  void startVoiceRecording() {
    isRecording = true;
    recordingDuration = 0;
    notifyListeners();
    _tickRecordingTimer();
  }

  void stopVoiceRecording() {
    isRecording = false;
    notifyListeners();

    messages.add(
      ChatMessage(
        text: '[Voice Message]',
        isSedi: false,
      ),
    );

    isThinking = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'پیام صوتی شما دریافت شد.'
            : currentLanguage == 'ar'
                ? 'تم استلام رسالتك الصوتية.'
                : 'Your voice message was received.',
      );
    });
  }

  void _tickRecordingTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!isRecording) return;
      recordingDuration++;
      notifyListeners();
      _tickRecordingTimer();
    });
  }

  String get recordingTimeFormatted {
    final m = recordingDuration ~/ 60;
    final s = recordingDuration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ===============================
  // Last message (UI helper)
  // ===============================

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}
