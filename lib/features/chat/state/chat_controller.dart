/// ============================================
/// ChatController - State Management
/// ============================================
/// 
/// CONTRACT:
/// - فقط state management
/// - بدون UI
/// - بدون animation
/// - بدون import widget
/// ============================================

import '../../../../core/utils/language_detector.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../data/models/user_profile.dart';
import '../chat_service.dart';
import 'package:flutter/foundation.dart';

enum ConversationState {
  initializing, // صدی در حال شروع صحبت
  chatting, // مکالمه عادی
  askingName, // در حال پرسیدن نام (طبیعی در مکالمه)
  askingSecurityPassword, // در حال پرسیدن رمز امنیتی (بعد از آشنایی)
  verifyingSecurity, // در حال بررسی رمز (رفتار مشکوک)
}

class ChatController extends ChangeNotifier {
  // ===============================
  // Animation States (for SediHeader)
  // ===============================

  bool isThinking = false;
  bool isAlert = false;

  // ===============================
  // Language & Conversation State
  // ===============================

  String currentLanguage = 'en';
  ConversationState conversationState = ConversationState.initializing;
  
  // User Profile
  UserProfile _userProfile = UserProfile();
  
  // Security
  bool _isSecurityCheckActive = false; // آیا در حال بررسی امنیتی هستیم؟

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

    // Load user profile
    _userProfile = await UserProfileManager.loadProfile();
    currentLanguage = _userProfile.preferredLanguage;
    
    conversationState = ConversationState.initializing;
    notifyListeners();

    // Start proactive conversation - صدی ابتدا صحبت می‌کند
    await _startProactiveConversation();
  }

  /// Start proactive conversation (صدی ابتدا صحبت می‌کند)
  Future<void> _startProactiveConversation() async {
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 800));

    // Try to get greeting from backend first
    String? backendGreeting;
    try {
      backendGreeting = await _chatService.getGreeting(
        userName: _userProfile.name,
        userPassword: _userProfile.securityPassword,
        language: currentLanguage,
      );
    } catch (e) {
      // If backend greeting fails, we'll use fallback
      print('[ChatController] Backend greeting failed: $e');
    }

    // Use backend greeting if available, otherwise use fallback
    if (backendGreeting != null && backendGreeting.isNotEmpty) {
      // Backend provided greeting - use it directly
      _addSediMessage(backendGreeting);
    } else {
      // Fallback to hardcoded greeting (only if backend unavailable)
      if (_userProfile.name == null) {
        // کاربر جدید - صدی خودش را معرفی می‌کند
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'سلام! من صدی هستم، همراه هوشمند مراقبت سلامتت 🌿'
              : currentLanguage == 'ar'
                  ? 'مرحباً! أنا صدي، رفيقك الذكي للعناية بالصحة 🌿'
                  : 'Hello! I\'m Sedi, your intelligent health companion 🌿',
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // ادامه مکالمه برای آشنایی
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خوشحالم که باهام صحبت می‌کنی! می‌خوای باهم بیشتر آشنا بشیم؟'
              : currentLanguage == 'ar'
                  ? 'سعيد أن أتحدث معك! هل تريد أن نتعرف أكثر؟'
                  : 'I\'m happy to talk with you! Would you like to get to know each other better?',
        );
      } else {
        // کاربر بازگشته - صدی با نامش خوش‌آمد می‌گوید
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خوش برگشتی ${_userProfile.name} 😊'
              : currentLanguage == 'ar'
                  ? 'مرحباً بعودتك ${_userProfile.name} 😊'
                  : 'Welcome back ${_userProfile.name} 😊',
        );
      }
    }

    conversationState = ConversationState.chatting;
    notifyListeners();
  }

  // ===============================
  // User Text Message
  // ===============================

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Detect language
    final detected = LanguageDetector.detectLanguage(trimmed);
    if (detected != currentLanguage) {
      currentLanguage = detected;
      _userProfile = _userProfile.copyWith(preferredLanguage: currentLanguage);
      await UserProfileManager.saveProfile(_userProfile);
    }

    // ---------------------------
    // Security Verification (if needed)
    // ---------------------------
    if (conversationState == ConversationState.verifyingSecurity) {
      await _handleSecurityVerification(trimmed);
      return;
    }

    // ---------------------------
    // Security Password Setup (after familiarity)
    // ---------------------------
    if (conversationState == ConversationState.askingSecurityPassword) {
      await _handleSecurityPasswordSetup(trimmed);
      return;
    }

    // ---------------------------
    // Name Collection (natural in conversation - AI-driven)
    // ---------------------------
    if (conversationState == ConversationState.askingName) {
      await _handleNameCollection(trimmed);
      // Continue to normal chat after name
    }

    // ---------------------------
    // Normal Chat
    // ---------------------------

    // 1️⃣ Add user message
    messages.add(
      ChatMessage(
        text: trimmed,
        isSedi: false,
        isUser: true,
      ),
    );

    // 2️⃣ Increment conversation count
    _userProfile = _userProfile.copyWith(
      conversationCount: _userProfile.conversationCount + 1,
    );
    await UserProfileManager.saveProfile(_userProfile);

    isThinking = true;
    notifyListeners();

    try {
      // 3️⃣ Send to backend (may return security flag)
      final response = await _chatService.sendMessage(
        trimmed,
        userName: _userProfile.name,
        userPassword: _userProfile.securityPassword,
      );

      // 4️⃣ Check for security requirements
      if (response == 'SECURITY_CHECK_REQUIRED') {
        await _triggerSecurityCheck();
        return;
      }

      // 4️⃣ Check for backend update required
      if (response.startsWith('BACKEND_UPDATE_REQUIRED:')) {
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'سرور نیاز به به‌روزرسانی دارد. لطفاً با مدیر سیستم تماس بگیرید.'
              : currentLanguage == 'ar'
                  ? 'الخادم يحتاج إلى تحديث. يرجى الاتصال بمدير النظام.'
                  : 'Server needs to be updated. Please contact administrator.',
        );
        return;
      }

      // 4️⃣ Check for server connection error
      if (response.startsWith('SERVER_CONNECTION_ERROR:')) {
        final errorMessage = response.replaceFirst('SERVER_CONNECTION_ERROR: ', '');
        _addSediMessage(errorMessage);
        return;
      }

      if (response.isEmpty) {
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'مشکلی در ارتباط پیش آمد.'
              : currentLanguage == 'ar'
                  ? 'حدثت مشكلة في الاتصال.'
                  : 'Connection issue occurred.',
        );
      } else {
        _addSediMessage(response);
        
        // 5️⃣ Check if we should ask for name (AI-driven, after a few messages)
        if (_userProfile.name == null && _userProfile.conversationCount >= 2) {
          await _maybeAskForName();
        }
        
        // 6️⃣ Check if we should ask for security password (after familiarity)
        if (_userProfile.needsSecurityPassword) {
          await _maybeAskForSecurityPassword();
        }
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

  /// Handle security verification (when suspicious behavior detected)
  Future<void> _handleSecurityVerification(String password) async {
    if (_userProfile.securityPassword == null) {
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'رمز امنیتی تنظیم نشده است. لطفاً ابتدا رمز را تنظیم کنید.'
            : currentLanguage == 'ar'
                ? 'لم يتم تعيين كلمة المرور الأمنية. يرجى تعيينها أولاً.'
                : 'Security password not set. Please set it first.',
      );
      conversationState = ConversationState.chatting;
      notifyListeners();
      return;
    }

    if (password == _userProfile.securityPassword) {
      // Password correct - clear security check
      _userProfile = _userProfile.copyWith(requiresSecurityCheck: false);
      await UserProfileManager.saveProfile(_userProfile);
      _isSecurityCheckActive = false;
      conversationState = ConversationState.chatting;
      notifyListeners();

      _addSediMessage(
        currentLanguage == 'fa'
            ? 'احراز هویت موفق بود. خوش برگشتی! 😊'
            : currentLanguage == 'ar'
                ? 'تم التحقق بنجاح. أهلاً بعودتك! 😊'
                : 'Verification successful. Welcome back! 😊',
      );
    } else {
      // Password incorrect
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'رمز اشتباه است. لطفاً دوباره تلاش کنید.'
            : currentLanguage == 'ar'
                ? 'كلمة المرور خاطئة. يرجى المحاولة مرة أخرى.'
                : 'Incorrect password. Please try again.',
      );
      // Keep in verification state
    }
  }

  /// Handle security password setup (after familiarity)
  Future<void> _handleSecurityPasswordSetup(String password) async {
    _userProfile = _userProfile.copyWith(
      securityPassword: password,
      hasSecurityPassword: true,
      securityPasswordSetAt: DateTime.now(),
    );
    await UserProfileManager.saveProfile(_userProfile);
    
    // Register user with backend if name is available
    if (_userProfile.name != null && _userProfile.name!.isNotEmpty) {
      try {
        await _chatService.registerUser(
          _userProfile.name!,
          _userProfile.securityPassword!,
          currentLanguage,
        );
      } catch (e) {
        // Registration error is not critical - user can still chat
        print('[ChatController] Registration error: $e');
      }
    }
    
    conversationState = ConversationState.chatting;
    notifyListeners();

    _addSediMessage(
      currentLanguage == 'fa'
          ? 'عالی! رمز امنیتی شما تنظیم شد. حالا می‌تونیم با اطمینان بیشتر ادامه بدیم 😊'
          : currentLanguage == 'ar'
              ? 'رائع! تم تعيين كلمة المرور الأمنية. الآن يمكننا المتابعة بثقة أكبر 😊'
              : 'Great! Your security password is set. Now we can continue with more confidence 😊',
    );
  }

  /// Handle name collection (natural in conversation)
  Future<void> _handleNameCollection(String name) async {
    _userProfile = _userProfile.copyWith(name: name);
    await UserProfileManager.saveProfile(_userProfile);
    
    // Register user with backend if password is already set
    if (_userProfile.securityPassword != null && _userProfile.securityPassword!.isNotEmpty) {
      try {
        await _chatService.registerUser(
          _userProfile.name!,
          _userProfile.securityPassword!,
          currentLanguage,
        );
      } catch (e) {
        // Registration error is not critical - user can still chat
        print('[ChatController] Registration error: $e');
      }
    }
    
    conversationState = ConversationState.chatting;
    notifyListeners();

    _addSediMessage(
      currentLanguage == 'fa'
          ? 'خوشحالم که با تو آشنا شدم $name! 😊'
          : currentLanguage == 'ar'
              ? 'سعيد أن أتعرف عليك $name! 😊'
              : 'Nice to meet you $name! 😊',
    );
  }

  /// Maybe ask for name (AI-driven, natural in conversation)
  Future<void> _maybeAskForName() async {
    if (_userProfile.name != null) return; // Already has name
    
    conversationState = ConversationState.askingName;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));
    
    _addSediMessage(
      currentLanguage == 'fa'
          ? 'می‌خوای بگی اسمت چیه؟ دوست دارم با اسمت صدا بزنم 😊'
          : currentLanguage == 'ar'
              ? 'هل تريد أن تخبرني باسمك؟ أحب أن أناديك باسمك 😊'
              : 'Would you like to tell me your name? I\'d love to call you by name 😊',
    );
  }

  /// Maybe ask for security password (after familiarity)
  Future<void> _maybeAskForSecurityPassword() async {
    if (_userProfile.hasSecurityPassword) return; // Already has password
    
    conversationState = ConversationState.askingSecurityPassword;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));
    
    _addSediMessage(
      currentLanguage == 'fa'
          ? 'حالا که باهم بیشتر آشنا شدیم، برای امنیت بیشتر بهتره یک رمز امنیتی تنظیم کنیم. اگر روزی رفتار مشکوکی ببینم، ازت رمز رو می‌پرسم. می‌خوای یک رمز انتخاب کنی؟'
          : currentLanguage == 'ar'
              ? 'الآن بعد أن تعرفنا أكثر، للأمان أكثر، من الأفضل أن نضع كلمة مرور أمنية. إذا رأيت سلوكًا مشبوهًا يومًا ما، سأسألك عن كلمة المرور. هل تريد اختيار كلمة مرور؟'
              : 'Now that we know each other better, for better security, it\'s good to set a security password. If I ever notice suspicious behavior, I\'ll ask you for the password. Would you like to choose a password?',
    );
  }

  /// Trigger security check (when suspicious behavior detected)
  Future<void> _triggerSecurityCheck() async {
    if (!_userProfile.hasSecurityPassword) {
      // No password set yet - can't verify
      return;
    }

    _isSecurityCheckActive = true;
    _userProfile = _userProfile.copyWith(requiresSecurityCheck: true);
    await UserProfileManager.saveProfile(_userProfile);
    
    conversationState = ConversationState.verifyingSecurity;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));
    
    _addSediMessage(
      currentLanguage == 'fa'
          ? 'برای اطمینان از هویت شما، لطفاً رمز امنیتی را وارد کنید:'
          : currentLanguage == 'ar'
              ? 'للتحقق من هويتك، يرجى إدخال كلمة المرور الأمنية:'
              : 'To verify your identity, please enter your security password:',
    );
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
        isUser: true,
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
