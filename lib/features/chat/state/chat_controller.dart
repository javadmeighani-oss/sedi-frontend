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

import 'dart:convert';
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

// STEP 2: Explicit state machine for chat flow
enum ChatSendState {
  idle,    // Ready to send
  sending, // Message being sent
  waiting, // Waiting for response
  error,   // Error occurred
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
  
  // STEP 2: Explicit state machine
  ChatSendState _sendState = ChatSendState.idle;
  ChatSendState get sendState => _sendState;
  bool get canSend => _sendState == ChatSendState.idle;
  
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

  Future<void> initialize({String? initialMessage}) async {
    if (_initialized) {
      print('[ChatController] ⚠️ Already initialized, skipping');
      return;
    }
    _initialized = true;

    print('[ChatController] ========== INITIALIZE START ==========');
    
    // Load user profile
    _userProfile = await UserProfileManager.loadProfile();
    // CRITICAL: Initial language is always English (per requirements)
    // Language will be detected from first user message
    currentLanguage = 'en';
    
    print('[ChatController] Profile loaded:');
    print('[ChatController]   - name: "${_userProfile.name}"');
    print('[ChatController]   - userId: ${_userProfile.userId}');
    print('[ChatController]   - language: $currentLanguage');
    print('[ChatController]   - isVerified: ${_userProfile.isVerified}');
    
    conversationState = ConversationState.initializing;
    notifyListeners();

    // ============================================
    // STEP 4: CHAT ERROR HANDLING (SEPARATE)
    // ============================================
    // Chat errors must:
    // - show ONLY inside chat UI
    // - never rollback onboarding
    // - never reset user state
    // ============================================
    
    // CRITICAL: If initial message provided (from onboarding), use it and STOP
    // Do NOT make any additional API calls
    // Even if initial message is empty or contains errors, onboarding was successful
    if (initialMessage != null) {
      print('[ChatController] ✅ Initial message provided from onboarding');
      print('[ChatController]   - Message: "${initialMessage.length > 50 ? initialMessage.substring(0, 50) + "..." : initialMessage}"');
      print('[ChatController]   - Length: ${initialMessage.length}');
      
      conversationState = ConversationState.chatting;
      notifyListeners();
      
      // Display initial message if not empty
      // If empty, it means chat/GPT failed, but onboarding succeeded (handled separately)
      if (initialMessage.isNotEmpty) {
        _addSediMessage(initialMessage);
      } else {
        // Chat failed but onboarding succeeded - show chat-specific error
        print('[ChatController] ⚠️ Initial message is empty (chat may have failed, but onboarding succeeded)');
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'پیام خوش‌آمدگویی دریافت نشد. لطفاً پیام خود را ارسال کنید.'
              : currentLanguage == 'ar'
                  ? 'لم يتم استلام رسالة الترحيب. يرجى إرسال رسالتك.'
                  : 'Welcome message could not be loaded. Please send your message.',
        );
      }
      
      print('[ChatController] ✅ Initialization complete (onboarding successful, chat handled separately)');
      print('[ChatController] ========== INITIALIZE END (ONBOARDING) ==========');
      return;
    }

    // CRITICAL: Only get greeting if NO initial message AND user_id exists
    // This prevents failed requests after onboarding
    if (_userProfile.userId == null) {
      print('[ChatController] ⚠️ WARNING: user_id is null, cannot fetch greeting');
      print('[ChatController]   - This should not happen after onboarding');
      print('[ChatController]   - Skipping greeting fetch');
      conversationState = ConversationState.chatting;
      notifyListeners();
      print('[ChatController] ========== INITIALIZE END (NO USER_ID) ==========');
      return;
    }

    print('[ChatController] No initial message, fetching greeting from backend...');
    // Otherwise, get greeting from backend (only for returning users)
    await _getGreetingFromBackend();
    print('[ChatController] ========== INITIALIZE END (GREETING) ==========');
  }

  /// Get greeting from backend - NO frontend logic
  Future<void> _getGreetingFromBackend() async {
    // CRITICAL: Validate user_id before making any API call
    if (_userProfile.userId == null) {
      print('[ChatController] ❌ ERROR: Cannot fetch greeting - user_id is null');
      print('[ChatController]   - This should not happen. User should have user_id after onboarding.');
      conversationState = ConversationState.chatting;
      notifyListeners();
      _addSediMessage(
        currentLanguage == 'fa'
            ? 'خطا در بارگذاری پروفایل کاربر. لطفاً دوباره تلاش کنید.'
            : currentLanguage == 'ar'
                ? 'خطأ في تحميل ملف تعريف المستخدم. يرجى المحاولة مرة أخرى.'
                : 'Error loading user profile. Please try again.',
      );
      return;
    }
    
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 800));

    print('[ChatController] ========== GET GREETING START ==========');
    print('[ChatController] Requesting greeting from backend...');
    print('[ChatController] User: name="${_userProfile.name}", userId=${_userProfile.userId}, lang=$currentLanguage');
    print('[ChatController] Profile loaded: name="${_userProfile.name}", userId=${_userProfile.userId}');

    try {
      // CRITICAL: Pass user name and user_id to backend so GPT can use it
      final greeting = await _chatService.getGreeting(
        userName: _userProfile.name,  // This will be passed to backend for GPT
        userPassword: _userProfile.securityPassword,
        language: currentLanguage,
        userId: _userProfile.userId,  // CRITICAL: Pass user_id to prevent anonymous user creation
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
        final parsed = _parseResponse(greeting);
        final messageToDisplay = parsed['message'] as String;
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

  /// Parse response to extract user_id, detected_name, and return clean message
  Map<String, dynamic> _parseResponse(String? response) {
    if (response == null || response.isEmpty) {
      return {'message': '', 'detected_name': null};
    }
    
    String message = response;
    String? detectedName;
    int? userId;
    
    // Extract DETECTED_NAME if present
    if (message.contains('DETECTED_NAME:')) {
      final nameMatch = RegExp(r'DETECTED_NAME:([^|]+)\|').firstMatch(message);
      if (nameMatch != null) {
        detectedName = nameMatch.group(1);
        message = message.replaceFirst(RegExp(r'DETECTED_NAME:[^|]+\|'), '');
        print('[ChatController] Extracted detected_name: $detectedName');
      }
    }
    
    // Extract USER_ID if present
    if (message.startsWith('USER_ID:')) {
      final parts = message.split('|MESSAGE:');
      if (parts.length == 2) {
        final userIdStr = parts[0].replaceFirst('USER_ID:', '');
        userId = int.tryParse(userIdStr);
        if (userId != null && _userProfile.userId == null) {
          // Save user_id for anonymous user
          _userProfile = _userProfile.copyWith(userId: userId);
          UserProfileManager.saveProfile(_userProfile);
        }
        message = parts[1]; // Clean message without USER_ID prefix
      } else {
        // Try alternative format
        final userIdMatch = RegExp(r'USER_ID:(\d+)\|').firstMatch(message);
        if (userIdMatch != null) {
          userId = int.tryParse(userIdMatch.group(1)!);
          if (userId != null && _userProfile.userId == null) {
            _userProfile = _userProfile.copyWith(userId: userId);
            UserProfileManager.saveProfile(_userProfile);
          }
          message = message.replaceFirst(RegExp(r'USER_ID:\d+\|'), '');
        }
      }
    }
    
    return {
      'message': message,
      'detected_name': detectedName,
      'user_id': userId,
    };
  }

  // ===============================
  // User Text Message
  // ===============================

  /// Send user message to backend and display response
  /// NO frontend logic - backend decides everything
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    
    // STEP 2: Block if already sending
    if (_sendState != ChatSendState.idle) {
      print('[ChatController] ⚠️ Message send blocked - state: $_sendState');
      return;
    }

    // STEP 3: Detect language from user message ONLY (not device/IP)
    final detected = LanguageDetector.detectLanguage(trimmed);
    if (detected != currentLanguage) {
      currentLanguage = detected;
      _userProfile = _userProfile.copyWith(preferredLanguage: currentLanguage);
      await UserPreferences.saveUserLanguage(currentLanguage);
      await UserProfileManager.saveProfile(_userProfile);
    }

    // STEP 2: Set state to sending
    _sendState = ChatSendState.sending;
    notifyListeners();

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

    // STEP 2: Set state to waiting
    _sendState = ChatSendState.waiting;
    isThinking = true;
    notifyListeners();

    try {
      // CRITICAL: Validate user_id before sending message
      if (_userProfile.userId == null) {
        print('[ChatController] ❌ ERROR: Cannot send message - user_id is null');
        print('[ChatController]   - This should not happen after onboarding');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در بارگذاری پروفایل کاربر. لطفاً دوباره تلاش کنید.'
              : currentLanguage == 'ar'
                  ? 'خطأ في تحميل ملف تعريف المستخدم. يرجى المحاولة مرة أخرى.'
                  : 'Error loading user profile. Please try again.',
        );
        // Reset to idle after error
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }
      
      // 3️⃣ Send to backend - backend decides everything
      print('[ChatController] ===== SENDING TO BACKEND =====');
      print('[ChatController] Message: "${trimmed.substring(0, trimmed.length > 50 ? 50 : trimmed.length)}..."');
      print('[ChatController] User: name="${_userProfile.name}", userId=${_userProfile.userId}, lang=$currentLanguage');
      
      final response = await _chatService.sendMessage(
        trimmed,
        userId: _userProfile.userId, // STEP 2: Only user_id and message (JSON body)
      );
      
      print('[ChatController] ===== BACKEND RESPONSE =====');
      print('[ChatController] Response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');

      // STEP 4: Handle error responses (only real HTTP/timeout errors)
      // Remove fake errors - only show real backend errors
      if (response.startsWith('VALIDATION_ERROR:')) {
        final errorMessage = response.replaceFirst('VALIDATION_ERROR: ', '');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در اعتبارسنجی: $errorMessage'
              : currentLanguage == 'ar'
                  ? 'خطأ في التحقق: $errorMessage'
                  : 'Validation error: $errorMessage',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }

      if (response.startsWith('USER_NOT_FOUND:')) {
        final errorMessage = response.replaceFirst('USER_NOT_FOUND: ', '');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'کاربر یافت نشد: $errorMessage'
              : currentLanguage == 'ar'
                  ? 'المستخدم غير موجود: $errorMessage'
                  : 'User not found: $errorMessage',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }

      if (response.startsWith('SERVER_ERROR:')) {
        final errorMessage = response.replaceFirst('SERVER_ERROR: ', '');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطای سرور: $errorMessage'
              : currentLanguage == 'ar'
                  ? 'خطأ في الخادم: $errorMessage'
                  : 'Server error: $errorMessage',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }

      if (response.startsWith('ERROR_')) {
        final errorMessage = response.replaceFirst(RegExp(r'ERROR_\d+: '), '');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا: $errorMessage'
              : currentLanguage == 'ar'
                  ? 'خطأ: $errorMessage'
                  : 'Error: $errorMessage',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }

      // Handle GPT errors (502 from backend) - real error
      if (response.startsWith('GPT_ERROR:')) {
        final errorMessage = response.replaceFirst('GPT_ERROR: ', '');
        print('[ChatController] GPT error received: $errorMessage');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در سرویس هوش مصنوعی: $errorMessage'
              : currentLanguage == 'ar'
                  ? 'خطأ في خدمة الذكاء الاصطناعي: $errorMessage'
                  : 'AI service error: $errorMessage',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
        return;
      }

      // 5️⃣ Display backend response - Parse JSON according to backend contract
      // Backend returns: {"message": string, "language": string, "timestamp": string, "requires_security_check": boolean, "detected_name": string | null}
      if (response.isEmpty) {
        print('[ChatController] ⚠️ WARNING: Empty response from backend');
        _sendState = ChatSendState.error;
        isThinking = false;
        notifyListeners();
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'پاسخ خالی از سرور دریافت شد.'
              : currentLanguage == 'ar'
                  ? 'تم استلام رد فارغ من الخادم.'
                  : 'Empty response from server.',
        );
        _sendState = ChatSendState.idle;
        notifyListeners();
      } else {
        // STEP 2: Parse JSON response according to backend contract
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response) as Map<String, dynamic>;
          print('[ChatController] ✅ Response parsed as JSON');
        } catch (e) {
          // Fallback to old format parsing for backward compatibility
          print('[ChatController] Response is not JSON, using old format parser: $e');
          final parsed = _parseResponse(response);
          responseData = {
            'message': parsed['message'] as String,
            'detected_name': parsed['detected_name'] as String?,
          };
        }
        
        final messageToDisplay = responseData['message']?.toString() ?? '';
        final detectedName = responseData['detected_name']?.toString();
        final responseLanguage = responseData['language']?.toString();
        
        // STEP 3: Update language if backend returned different language
        if (responseLanguage != null && responseLanguage.isNotEmpty && responseLanguage != currentLanguage) {
          print('[ChatController] Language updated from backend: $currentLanguage -> $responseLanguage');
          currentLanguage = responseLanguage;
          _userProfile = _userProfile.copyWith(preferredLanguage: currentLanguage);
          await UserPreferences.saveUserLanguage(currentLanguage);
          await UserProfileManager.saveProfile(_userProfile);
        }
        
        // Update UserProfile if name was detected from conversation
        if (detectedName != null && detectedName.isNotEmpty) {
          print('[ChatController] ✅ Name detected from conversation: $detectedName');
          _userProfile = _userProfile.copyWith(name: detectedName);
          await UserProfileManager.saveProfile(_userProfile);
          print('[ChatController] ✅ UserProfile updated with new name: $detectedName');
        }
        
        print('[ChatController] ✅ Displaying backend message');
        print('[ChatController] Original response length: ${response.length}');
        print('[ChatController] Parsed message length: ${messageToDisplay.length}');
        print('[ChatController] Message preview: ${messageToDisplay.substring(0, messageToDisplay.length > 100 ? 100 : messageToDisplay.length)}...');
        
        if (messageToDisplay.isEmpty) {
          print('[ChatController] ⚠️ WARNING: Parsed message is empty!');
        }
        
        // STEP 2: Append message only after successful response
        _addSediMessage(messageToDisplay);
        
        // STEP 2: Reset to idle after success
        _sendState = ChatSendState.idle;
        isThinking = false;
        notifyListeners();
        
        // NO frontend logic here - backend Conversation Brain decides everything
        // NO asking for name, password, etc. from frontend
        // Backend will send those messages if needed
      }
    } catch (e, stackTrace) {
      // STEP 4: Only show real HTTP/timeout errors (no fake errors)
      print('[ChatController] ===== ERROR SENDING MESSAGE =====');
      print('[ChatController] Error: $e');
      print('[ChatController] Error type: ${e.runtimeType}');
      print('[ChatController] Stack trace: $stackTrace');
      print('[ChatController] Message that failed: "$trimmed"');
      print('[ChatController] User ID: ${_userProfile.userId}');
      print('[ChatController] Language: $currentLanguage');
      print('[ChatController] ===== END ERROR =====');
      
      _sendState = ChatSendState.error;
      isThinking = false;
      notifyListeners();
      
      // STEP 4: Only show error if it's a real network/timeout/HTTP error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') || 
          errorString.contains('connection') || 
          errorString.contains('network') ||
          errorString.contains('socket') ||
          errorString.contains('http')) {
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در ارتباط با سرور. لطفاً دوباره تلاش کنید.'
              : currentLanguage == 'ar'
                  ? 'خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.'
                  : 'Error connecting to server. Please try again.',
        );
      } else {
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'خطا در ارسال پیام. لطفاً دوباره تلاش کنید.'
              : currentLanguage == 'ar'
                  ? 'خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى.'
                  : 'Error sending message. Please try again.',
        );
      }
      
      // STEP 2: Reset to idle after error
      _sendState = ChatSendState.idle;
      notifyListeners();
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
