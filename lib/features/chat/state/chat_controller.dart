import 'package:flutter/material.dart';
import '../../../../core/utils/language_detector.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/messages.dart';
import 'chat_message.dart';
import '../chat_service.dart';

enum OnboardingState {
  none, // ورود عادی
  askingName, // در حال پرسیدن نام
  askingPassword, // در حال پرسیدن رمز
  completed, // تکمیل شده
}

class ChatController extends ChangeNotifier {
  bool isThinking = false;
  bool isAlert = false;
  String currentLanguage = 'en'; // زبان فعلی: en, fa, ar
  OnboardingState onboardingState = OnboardingState.none;
  String? userName;
  String? userPassword;

  final List<ChatMessage> messages = [];
  final ChatService _chatService = ChatService();
  bool _isInitialized = false;

  /// مقداردهی اولیه
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // بررسی اینکه آیا اولین بار است
    final isFirstTime = await UserPreferences.isFirstTime();
    
    if (isFirstTime) {
      // ورود اول: شروع با انگلیسی
      onboardingState = OnboardingState.askingName;
      currentLanguage = 'en';
      
      Future.delayed(const Duration(milliseconds: 800), () {
        addSediMessage(AppMessages.getWelcomeMessage('en'));
        Future.delayed(const Duration(milliseconds: 1000), () {
          addSediMessage(AppMessages.getNameRequest('en'));
        });
      });
    } else {
      // ورود مجدد: بارگذاری اطلاعات کاربر
      userName = await UserPreferences.getUserName();
      currentLanguage = await UserPreferences.getUserLanguage();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        addSediMessage(AppMessages.getWelcomeBack(currentLanguage, userName ?? ''));
      });
    }
  }

  // -------------------------------
  //  ارسال پیام کاربر
  // -------------------------------
  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;

    // تشخیص زبان از روی متن کاربر
    final detectedLang = LanguageDetector.detectLanguage(text);
    if (detectedLang != currentLanguage && onboardingState == OnboardingState.completed) {
      currentLanguage = detectedLang;
      await UserPreferences.saveUserLanguage(currentLanguage);
    }

    // مدیریت ورود اول
    if (onboardingState == OnboardingState.askingName) {
      userName = text.trim();
      await UserPreferences.saveUserName(userName!);
      onboardingState = OnboardingState.askingPassword;
      
      // تشخیص زبان از نام
      final nameLang = LanguageDetector.detectLanguage(userName!);
      if (nameLang != 'en') {
        currentLanguage = nameLang;
      }
      
      addSediMessage(AppMessages.getPasswordRequest(currentLanguage));
      return;
    }

    if (onboardingState == OnboardingState.askingPassword) {
      userPassword = text.trim();
      await UserPreferences.saveUserPassword(userPassword!);
      await UserPreferences.setNotFirstTime();
      await UserPreferences.saveUserLanguage(currentLanguage);
      onboardingState = OnboardingState.completed;
      
      // پیام تایید
      final confirmMsg = currentLanguage == 'fa' 
          ? 'عالی! حالا می‌تونیم شروع کنیم 😊'
          : currentLanguage == 'ar'
              ? 'رائع! الآن يمكننا البدء 😊'
              : 'Great! Now we can start 😊';
      
      addSediMessage(confirmMsg);
      return;
    }

    // ارسال پیام عادی
    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        type: 'normal',
      ),
    );

    isThinking = true;
    notifyListeners();

    try {
      // ارسال پیام به API واقعی
      final response = await _chatService.sendMessage(text);
      addSediMessage(response);
    } catch (e) {
      final errorMsg = currentLanguage == 'fa'
          ? 'خطا در ارسال پیام: ${e.toString()}'
          : currentLanguage == 'ar'
              ? 'خطأ في إرسال الرسالة: ${e.toString()}'
              : 'Error sending message: ${e.toString()}';
      addSediMessage(errorMsg);
    }
  }

  // -------------------------------
  //  پاسخ صدی
  // -------------------------------
  void addSediMessage(String text) {
    isThinking = false;

    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: false,
        type: 'normal',
      ),
    );

    notifyListeners();
  }

  // -------------------------------
  //  ورودی صوت
  // -------------------------------
  void startVoiceInput() {
    final voiceMsg = currentLanguage == 'fa'
        ? 'در حال شنیدن صدای شما هستم...'
        : currentLanguage == 'ar'
            ? 'أستمع إلى صوتك...'
            : 'Listening to your voice...';
    addSediMessage(voiceMsg);
  }

  // -------------------------------
  //  آخرین پیام (برای نمایش زیر چت باکس)
  // -------------------------------
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }
}
