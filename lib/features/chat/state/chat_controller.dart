/// ============================================
/// ChatController - Display Layer Only
/// ============================================
/// 
/// RESPONSIBILITY:
/// - فقط نمایش پاسخ‌های backend
/// - ارسال پیام کاربر به backend
/// - هیچ تصمیم‌گیری یا logic ندارد
/// - همه متن‌ها از backend می‌آیند
/// ============================================

import '../../../../core/utils/language_detector.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../data/models/chat_message.dart';
import '../../../../data/models/user_profile.dart';
import '../chat_service.dart';
import 'package:flutter/foundation.dart';

enum ConversationState {
  initializing, // در حال دریافت greeting از backend
  chatting, // مکالمه عادی
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

    // Get greeting from backend ONLY - no frontend logic
    await _getGreetingFromBackend();
  }

  /// Get greeting from backend - NO frontend logic
  Future<void> _getGreetingFromBackend() async {
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 800));

    print('[ChatController] Requesting greeting from backend...');
    print('[ChatController] User: name=${_userProfile.name}, userId=${_userProfile.userId}, lang=$currentLanguage');

    try {
      final greeting = await _chatService.getGreeting(
        userName: _userProfile.name,
        userPassword: _userProfile.securityPassword,
        language: currentLanguage,
      );

      conversationState = ConversationState.chatting;
      notifyListeners();

      if (greeting != null && greeting.isNotEmpty) {
        // Check if backend is unavailable
        if (greeting == 'BACKEND_UNAVAILABLE') {
          print('[ChatController] ERROR: Backend unavailable');
          // Show error state - NO greeting, NO fallback
          _addSediMessage(
            currentLanguage == 'fa'
                ? 'متأسفانه در حال حاضر به سرور متصل نیستم. لطفاً اتصال اینترنت را بررسی کنید و دوباره تلاش کنید. 😔'
                : currentLanguage == 'ar'
                    ? 'عذراً، أنا غير متصل بالخادم حاليًا. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى. 😔'
                    : 'I\'m sorry, I\'m not connected to the server right now. Please check your internet connection and try again. 😔',
          );
          return;
        }

        // Backend provided greeting - display it
        final messageToDisplay = _parseResponse(greeting);
        print('[ChatController] Displaying backend greeting (length: ${messageToDisplay.length})');
        _addSediMessage(messageToDisplay);
      } else {
        // Backend didn't respond - show error only
        print('[ChatController] ERROR: Backend greeting returned null');
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'متأسفانه در حال حاضر به سرور متصل نیستم. لطفاً اتصال اینترنت را بررسی کنید و دوباره تلاش کنید. 😔'
              : currentLanguage == 'ar'
                  ? 'عذراً، أنا غير متصل بالخادم حاليًا. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى. 😔'
                  : 'I\'m sorry, I\'m not connected to the server right now. Please check your internet connection and try again. 😔',
        );
      }
    } catch (e) {
      print('[ChatController] ERROR getting greeting: $e');
      conversationState = ConversationState.chatting;
      notifyListeners();
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'خطا در اتصال به سرور. لطفاً دوباره تلاش کنید.'
            : currentLanguage == 'ar'
                ? 'خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.'
                : 'Error connecting to server. Please try again.',
      );
    }
  }

  /// Parse response to extract user_id and return clean message
  String _parseResponse(String? response) {
    if (response == null || response.isEmpty) return '';
    
    // Check if response contains user_id (for anonymous users)
    if (response.startsWith('USER_ID:')) {
      final parts = response.split('|MESSAGE:');
      if (parts.length == 2) {
        final userIdStr = parts[0].replaceFirst('USER_ID:', '');
        final userId = int.tryParse(userIdStr);
        if (userId != null && _userProfile.userId == null) {
          // Save user_id for anonymous user
          _userProfile = _userProfile.copyWith(userId: userId);
          UserProfileManager.saveProfile(_userProfile);
        }
        return parts[1]; // Return clean message without USER_ID prefix
      }
    }
    
    return response; // Return as-is if no USER_ID prefix
  }

  // ===============================
  // User Text Message
  // ===============================

  /// Send user message to backend and display response
  /// NO frontend logic - backend decides everything
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Detect language from user message (for sending to backend)
    final detected = LanguageDetector.detectLanguage(trimmed);
    if (detected != currentLanguage) {
      currentLanguage = detected;
      _userProfile = _userProfile.copyWith(preferredLanguage: currentLanguage);
      await UserPreferences.saveUserLanguage(currentLanguage);
      await UserProfileManager.saveProfile(_userProfile);
    }

    // 1️⃣ Add user message to UI
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
      // 3️⃣ Send to backend - backend decides everything
      print('[ChatController] ===== SENDING TO BACKEND =====');
      print('[ChatController] Message: "${trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length)}..."');
      print('[ChatController] User: name=${_userProfile.name}, userId=${_userProfile.userId}, lang=$currentLanguage');
      
      final response = await _chatService.sendMessage(
        trimmed,
        userName: _userProfile.name,
        userPassword: _userProfile.securityPassword,
        language: currentLanguage, // Send current language to backend
      );
      
      print('[ChatController] ===== BACKEND RESPONSE =====');
      print('[ChatController] Response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');

      // 4️⃣ Handle special backend responses
      if (response == 'SECURITY_CHECK_REQUIRED') {
        // Backend requested security check - show backend's message
        // Frontend doesn't decide what to show - backend will send the message
        print('[ChatController] Backend requested security check');
        // Don't show anything - backend will send the actual message in next response
        return;
      }

      if (response.startsWith('BACKEND_UPDATE_REQUIRED:')) {
        final errorMessage = response.replaceFirst('BACKEND_UPDATE_REQUIRED: ', '');
        _addSediMessage(errorMessage);
        return;
      }

      if (response.startsWith('SERVER_CONNECTION_ERROR:')) {
        final errorMessage = response.replaceFirst('SERVER_CONNECTION_ERROR: ', '');
        _addSediMessage(errorMessage);
        return;
      }

      if (response.startsWith('AUTH_REQUIRED')) {
        // Backend requires auth - show error
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'نیاز به احراز هویت است. لطفاً دوباره تلاش کنید.'
              : currentLanguage == 'ar'
                  ? 'يجب التحقق من الهوية. يرجى المحاولة مرة أخرى.'
                  : 'Authentication required. Please try again.',
        );
        return;
      }

      if (response.startsWith('SERVER_ERROR_') || response.startsWith('NETWORK_ERROR:')) {
        // Backend error - show error
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در ارتباط با سرور. لطفاً دوباره تلاش کنید.'
              : currentLanguage == 'ar'
                  ? 'خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.'
                  : 'Error connecting to server. Please try again.',
        );
        return;
      }

      // 5️⃣ Display backend response - NO frontend logic
      if (response.isEmpty) {
        print('[ChatController] ⚠️ WARNING: Empty response from backend');
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'پاسخ خالی از سرور دریافت شد.'
              : currentLanguage == 'ar'
                  ? 'تم استلام رد فارغ من الخادم.'
                  : 'Empty response from server.',
        );
      } else {
        // Parse and display backend message
        final messageToDisplay = _parseResponse(response);
        print('[ChatController] ✅ Displaying backend message');
        print('[ChatController] Original response length: ${response.length}');
        print('[ChatController] Parsed message length: ${messageToDisplay.length}');
        print('[ChatController] Message preview: ${messageToDisplay.substring(0, messageToDisplay.length > 100 ? 100 : messageToDisplay.length)}...');
        
        if (messageToDisplay.isEmpty) {
          print('[ChatController] ⚠️ WARNING: Parsed message is empty!');
        }
        
        _addSediMessage(messageToDisplay);
        
        // NO frontend logic here - backend Conversation Brain decides everything
        // NO asking for name, password, etc. from frontend
        // Backend will send those messages if needed
      }
    } catch (e) {
      // Log error details for debugging
      print('[ChatController] ERROR sending message: $e');
      print('[ChatController] Error type: ${e.runtimeType}');
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'خطا در ارسال پیام به سرور. لطفاً دوباره تلاش کنید.'
            : currentLanguage == 'ar'
                ? 'خطأ في إرسال الرسالة إلى الخادم. يرجى المحاولة مرة أخرى.'
                : 'Error sending message to server. Please try again.',
      );
    }
  }

  // ===============================
  // Sedi Message (Display Only)
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

    // Send voice message to backend - backend decides response
    Future.delayed(const Duration(seconds: 2), () {
      // Backend should process voice and send response
      // For now, just show a placeholder - backend will handle this
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
