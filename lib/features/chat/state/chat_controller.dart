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

import '../../../core/utils/language_detector.dart';
import '../../../core/utils/user_preferences.dart';
import '../../../core/utils/user_profile_manager.dart';
import '../../../data/dto/chat/chat_send_response.dart';
import '../../../data/dto/lifestyle_summary_response.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/lifestyle_repository.dart';
import '../../../services/chat/chat_service.dart' as v1chat;
import '../logic/greeting_templates.dart';
import 'package:flutter/foundation.dart';
import '../../../services/audio/audio_recorder_service.dart';
import '../chat_service.dart' as legacychat;

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

  final legacychat.ChatService _legacyChatService = legacychat.ChatService();
  final v1chat.ChatService _chatService = v1chat.ChatService();
  final LifestyleRepository _lifestyleRepo = LifestyleRepository();
  final AudioRecorderService _audioRecorder = AudioRecorderService();
  bool _initialized = false;

  /// Stage 17.2: Cached lifestyle summary (in-memory, session only)
  LifestyleSummaryResponse? _cachedLifestyleSummary;
  bool _lifestyleSummaryLoading = false;
  String? _lifestyleSummaryError;

  LifestyleSummaryResponse? get cachedLifestyleSummary =>
      _cachedLifestyleSummary;
  bool get lifestyleSummaryLoading => _lifestyleSummaryLoading;
  String? get lifestyleSummaryError => _lifestyleSummaryError;

  /// Fetch lifestyle summary. Uses cache unless [forceRefresh] or no cache.
  Future<void> fetchLifestyleSummary({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLifestyleSummary != null) {
      notifyListeners();
      return;
    }
    final userId = _userProfile.userId;
    if (userId == null) {
      _lifestyleSummaryError = 'Please sign in to see lifestyle summary';
      notifyListeners();
      return;
    }
    _lifestyleSummaryLoading = true;
    _lifestyleSummaryError = null;
    notifyListeners();
    try {
      final res = await _lifestyleRepo.fetchLifestyleSummary(
        userId: userId,
        lang: currentLanguage,
      );
      if (res.ok && res.data != null) {
        _cachedLifestyleSummary = res.data;
        _lifestyleSummaryError = null;
      } else {
        _lifestyleSummaryError = res.error?.message ?? 'Failed to load summary';
      }
    } catch (e) {
      _lifestyleSummaryError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _lifestyleSummaryLoading = false;
      notifyListeners();
    }
  }

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
    currentLanguage = _userProfile.preferredLanguage.isNotEmpty
        ? _userProfile.preferredLanguage
        : 'en';

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
      print(
          '[ChatController]   - Message: "${initialMessage.length > 50 ? initialMessage.substring(0, 50) + "..." : initialMessage}"');
      print('[ChatController]   - Length: ${initialMessage.length}');

      conversationState = ConversationState.chatting;
      notifyListeners();

      // Display initial message if not empty
      // If empty, it means chat/GPT failed, but onboarding succeeded (handled separately)
      if (initialMessage.isNotEmpty) {
        _addSediMessage(initialMessage);
      } else {
        // Chat failed but onboarding succeeded - show chat-specific error
        print(
            '[ChatController] ⚠️ Initial message is empty (chat may have failed, but onboarding succeeded)');
        _addSediMessage(
          currentLanguage == 'fa'
              ? 'پیام خوش‌آمدگویی دریافت نشد. لطفاً پیام خود را ارسال کنید.'
              : currentLanguage == 'ar'
                  ? 'لم يتم استلام رسالة الترحيب. يرجى إرسال رسالتك.'
                  : 'Welcome message could not be loaded. Please send your message.',
        );
      }

      print(
          '[ChatController] ✅ Initialization complete (onboarding successful, chat handled separately)');
      print(
          '[ChatController] ========== INITIALIZE END (ONBOARDING) ==========');
      return;
    }

    // CRITICAL: Only get greeting if NO initial message AND user_id exists
    // This prevents failed requests after onboarding
    if (_userProfile.userId == null) {
      print(
          '[ChatController] ⚠️ WARNING: user_id is null, cannot fetch greeting');
      print('[ChatController]   - This should not happen after onboarding');
      print('[ChatController]   - Skipping greeting fetch');
      conversationState = ConversationState.chatting;
      notifyListeners();
      print(
          '[ChatController] ========== INITIALIZE END (NO USER_ID) ==========');
      return;
    }

    print(
        '[ChatController] No initial message, using approved intro greeting (once per user, no duplicate on reopen).');
    await _showIntroGreetingOnce();
    print('[ChatController] ========== INITIALIZE END (GREETING) ==========');
  }

  /// Show approved intro greeting once; do not reinsert on app reopen if already seen.
  Future<void> _showIntroGreetingOnce() async {
    final alreadySeen = await UserPreferences.hasSeenIntroGreeting();
    if (alreadySeen) {
      print(
          '[ChatController] Intro greeting already seen, skipping (no duplicate on reopen).');
      conversationState = ConversationState.chatting;
      notifyListeners();
      return;
    }
    final profileLang = _userProfile.preferredLanguage;
    final lang = profileLang.isNotEmpty
        ? profileLang
        : await UserPreferences.getUserLanguage();
    final greeting = getIntroGreeting(lang);
    _addSediMessage(greeting);
    await UserPreferences.setHasSeenIntroGreeting(true);
    conversationState = ConversationState.chatting;
    notifyListeners();
  }

  /// Get greeting from backend - kept for reference; intro now uses greeting_templates.
  Future<void> _getGreetingFromBackend() async {
    // CRITICAL: Validate user_id before making any API call
    if (_userProfile.userId == null) {
      print(
          '[ChatController] ❌ ERROR: Cannot fetch greeting - user_id is null');
      print(
          '[ChatController]   - This should not happen. User should have user_id after onboarding.');
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
    print(
        '[ChatController] User: name="${_userProfile.name}", userId=${_userProfile.userId}, lang=$currentLanguage');
    print(
        '[ChatController] Profile loaded: name="${_userProfile.name}", userId=${_userProfile.userId}');

    try {
      // CRITICAL: Pass user name and user_id to backend so GPT can use it
      final greeting = await _legacyChatService.getGreeting(
        userName: _userProfile.name, // This will be passed to backend for GPT
        userPassword: _userProfile.securityPassword,
        language: currentLanguage,
        userId: _userProfile
            .userId, // CRITICAL: Pass user_id to prevent anonymous user creation
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
        print(
            '[ChatController] Displaying backend greeting (length: ${messageToDisplay.length})');
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
    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    final detected = LanguageDetector.detectLanguage(trimmed);
    currentLanguage = _userProfile.preferredLanguage.isNotEmpty
        ? _userProfile.preferredLanguage
        : detected;

    messages.add(
      ChatMessage.user(
        text: trimmed,
        localId: localId,
        status: ChatMessageStatus.sending,
      ),
    );
    isThinking = true;
    notifyListeners();

    final response = await _chatService.sendMessage(
      message: trimmed,
      language: currentLanguage,
      userId: _userProfile.userId,
    );

    if (!response.ok || response.data == null) {
      _setMessageStatus(localId, ChatMessageStatus.failed);
      isThinking = false;
      notifyListeners();
      return;
    }

    _setMessageStatus(localId, ChatMessageStatus.sent);
    await _appendAssistantResponse(response.data!);
  }

  Future<void> retryFailedMessage(String localId) async {
    final index = messages.indexWhere((m) => m.localId == localId);
    if (index < 0) return;
    final failed = messages[index];
    if (!failed.isUser || failed.status != ChatMessageStatus.failed) return;

    _setMessageStatus(localId, ChatMessageStatus.sending);
    isThinking = true;
    notifyListeners();

    final response = await _chatService.sendMessage(
      message: failed.text,
      language: currentLanguage,
      userId: _userProfile.userId,
    );
    if (!response.ok || response.data == null) {
      _setMessageStatus(localId, ChatMessageStatus.failed);
      isThinking = false;
      notifyListeners();
      return;
    }

    _setMessageStatus(localId, ChatMessageStatus.sent);
    await _appendAssistantResponse(response.data!);
  }

  Future<void> _appendAssistantResponse(ChatSendResponse data) async {
    if (data.userId != null && _userProfile.userId == null) {
      _userProfile = _userProfile.copyWith(userId: data.userId);
    }
    if (data.detectedName != null && data.detectedName!.trim().isNotEmpty) {
      _userProfile = _userProfile.copyWith(name: data.detectedName!.trim());
    }
    if (data.language.trim().isNotEmpty) {
      currentLanguage = data.language;
      _userProfile = _userProfile.copyWith(preferredLanguage: data.language);
      await UserPreferences.saveUserLanguage(data.language);
    }
    _userProfile = _userProfile.copyWith(
      conversationCount: _userProfile.conversationCount + 1,
    );
    await UserProfileManager.saveProfile(_userProfile);

    if (data.message.trim().isNotEmpty) {
      _addSediMessage(data.message.trim());
    } else {
      isThinking = false;
      notifyListeners();
    }
  }

  void _setMessageStatus(String localId, ChatMessageStatus status) {
    final idx = messages.indexWhere((m) => m.localId == localId);
    if (idx < 0) return;
    messages[idx] = messages[idx].copyWith(status: status);
  }

  // ===============================
  // Sedi Message (Display Only)
  // ===============================

  void _addSediMessage(String text) {
    isThinking = false;

    messages.add(
      ChatMessage(
        text: text,
        role: ChatRole.assistant,
      ),
    );

    notifyListeners();
  }

  // ===============================
  // Voice Recording (Stage 24: MVP local file; no voice-to-text yet)
  // ===============================

  /// Returns true if recording started, false if permission denied or error.
  Future<bool> startVoiceRecording() async {
    try {
      final granted = await _audioRecorder.ensurePermission();
      if (!granted) return false;
      await _audioRecorder.start();
      isRecording = true;
      recordingDuration = 0;
      notifyListeners();
      _tickRecordingTimer();
      return true;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ChatController] startVoiceRecording error: $e');
      return false;
    }
  }

  /// Stops recording and returns the local file path, or null on error.
  Future<String?> stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording = false;
      notifyListeners();
      return path;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[ChatController] stopVoiceRecording error: $e');
      isRecording = false;
      notifyListeners();
      return null;
    }
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
