import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/lifestyle_summary_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../../../../core/preferences/notification_prefs.dart';
import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/brand_name.dart';
import '../../../../core/utils/user_preferences.dart';
import '../../../../core/utils/user_profile_manager.dart';
import '../../../../core/widgets/app_states/app_empty_state.dart';
import '../../../../core/widgets/app_states/app_loading_state.dart';
import '../../../../data/models/chat_message.dart';
import '../../../onboarding/presentation/widgets/get_to_know_you_sheet.dart';
import 'chat_history_page.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../health/presentation/pages/vitals_page.dart';
import '../../../lifestyle/presentation/pages/lifestyle_page.dart';
import '../../../notification/data/notification_service.dart';
import '../../../notification/logic/notification_sync.dart';
import '../../../notification/presentation/pages/notifications_inbox_page.dart';
import '../../../auth_otp/presentation/pages/otp_login_page.dart';

/// ============================================
/// ChatPage - صفحه اصلی چت
/// ============================================
///
/// CONTRACT:
/// - پیام‌های صدی نباید زیر چت‌باکس بروند
/// - فقط آخرین پیام به صورت طبیعی دیده شود
/// - اسکرول دستی برای پیام‌های قبلی
/// - دکمه بازگشت به آخرین پیام (سمت راست پایین)
/// ============================================
class ChatPage extends StatefulWidget {
  final String? initialMessage;

  /// Opened from push notification (deep link / OPEN_CHAT)
  final bool fromNotification;
  final int? notificationId;

  const ChatPage({
    super.key,
    this.initialMessage,
    this.fromNotification = false,
    this.notificationId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();
  final NotificationService _notificationService = NotificationService();

  // Double tap to exit variables
  DateTime? _lastBackPressTime;
  Timer? _backPressTimer;

  /// Unread count for badge; null = not loaded yet.
  int? _unreadCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ChatController();
    // Add listener to update UI when timer changes
    _controller.addListener(_onControllerChanged);
    // Auto-scroll to bottom when new message arrives
    _controller.addListener(_scrollToBottomOnNewMessage);
    _controller.initialize(initialMessage: widget.initialMessage);
    _refreshUnreadCount();
    if (widget.fromNotification) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showFromNotificationBanner());
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowGetToKnowYou());
  }

  /// If user reached Chat without completing get-to-know-you (e.g. onboarding skipped), show once.
  Future<void> _maybeShowGetToKnowYou() async {
    if (!mounted) return;
    final completed = await UserPreferences.hasCompletedGetToKnowYou();
    if (completed || !mounted) return;
    final profile = await UserProfileManager.loadProfile();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GetToKnowYouSheet(
        userId: profile.userId,
        prefilledName: profile.name,
      ),
    );
  }

  void _showFromNotificationBanner() {
    if (!mounted) return;
    final lang = _controller.currentLanguage;
    final msg = lang == 'fa'
        ? 'از اعلان باز شد'
        : lang == 'ar'
            ? 'تم الفتح من الإشعار'
            : 'Opened from notification';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  static bool _isLifestyleSummaryCommand(String text) {
    final t = text.trim().toLowerCase();
    if (t == '/lifestyle' || t == 'lifestyle summary') return true;
    if (t == '/سبک' || t.contains('خلاصه سبک زندگی')) return true;
    if (t == '/نمط' || t.contains('ملخص نمط الحياة')) return true;
    return false;
  }

  void _handleSendText(String text) {
    if (_isLifestyleSummaryCommand(text)) {
      _showLifestyleSummarySheet(context);
      return;
    }
    _controller.sendUserMessage(text);
  }

  void _showLifestyleSummarySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _LifestyleSummarySheetContent(
          controller: _controller,
          scrollController: scrollController,
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _showNotificationSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _NotificationSettingsSheet(
        onSend: (text) {
          Navigator.of(ctx).pop();
          _controller.sendUserMessage(text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _controller.currentLanguage == 'fa'
                    ? 'ارسال شد'
                    : _controller.currentLanguage == 'ar'
                        ? 'تم الإرسال'
                        : 'Sent',
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        lang: _controller.currentLanguage,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationSync.syncOnce();
      _refreshUnreadCount();
    }
  }

  Future<void> _refreshUnreadCount() async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OtpLoginPage()),
      );
      return;
    }
    final resp = await _notificationService.fetchUnreadList(userId: userId);
    if (!mounted) return;
    if (resp['ok'] == true) {
      setState(() => _unreadCount = NotificationService.parseUnreadCount(resp));
    } else {
      setState(() => _unreadCount = _unreadCount ?? 0);
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        // Update UI (including timer display)
      });
    }
  }

  void _scrollToBottomOnNewMessage() {
    // Scroll to bottom when new message is added
    // Use WidgetsBinding to ensure scroll happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backPressTimer?.cancel(); // Cancel timer if active
    _controller.removeListener(_onControllerChanged); // Remove listener
    _controller
        .removeListener(_scrollToBottomOnNewMessage); // Remove scroll listener
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Placeholder: brand name from brand_name.dart
  String _inputHint() {
    final lang = _controller.currentLanguage;
    final brand = sediBrandName(lang);
    if (lang == 'fa') return 'با $brand صحبت کنید…';
    if (lang == 'ar') return 'تحدث مع $brand…';
    return 'Talk to $brand…';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handle back button press with double tap to exit
  bool _handleBackPress() {
    final now = DateTime.now();

    // If this is the first tap or more than 2 seconds have passed
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // First tap: show message and start timer
      _lastBackPressTime = now;

      // Cancel previous timer if exists
      _backPressTimer?.cancel();

      // Show snackbar message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'برای خروج دوباره back بزنید',
            textDirection: TextDirection.rtl,
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryBlack.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            bottom: 100,
            left: 16,
            right: 16,
          ),
        ),
      );

      // Reset counter after 2 seconds
      _backPressTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _lastBackPressTime = null;
          });
        }
      });

      return false; // Prevent exit
    } else {
      // Second tap within 2 seconds: exit app
      _backPressTimer?.cancel();
      SystemNavigator.pop(); // Exit the app
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to position InputBar above keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isRtl = _controller.currentLanguage == 'fa' ||
        _controller.currentLanguage == 'ar';

    final content = PopScope(
      // Prevent back navigation to IntroPage
      // IntroPage should only appear once at app start
      // Implement double tap to exit functionality
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Already handled by system
          return;
        }
        // Handle double tap to exit
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        resizeToAvoidBottomInset: false, // We handle keyboard manually
        body: SafeArea(
          child: Stack(
            children: [
              // ================= MAIN CONTENT =================
              Column(
                children: [
                  // ================= TOP BAR =================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        const Spacer(),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              iconSize: 24,
                              style: IconButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlack,
                                minimumSize: const Size(44, 44),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsInboxPage(),
                                      ),
                                    )
                                    .then((_) => _refreshUnreadCount());
                              },
                            ),
                            if (_unreadCount != null && _unreadCount! > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryBlack,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                      minWidth: 18, minHeight: 18),
                                  child: Text(
                                    _unreadCount! > 99
                                        ? '99+'
                                        : '$_unreadCount',
                                    style: const TextStyle(
                                      color: AppTheme.backgroundWhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/icons/device_ecg_icon.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DevicesPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const VitalsPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.history),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatHistoryPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.self_improvement_outlined),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LifestylePage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.schedule_outlined),
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlack,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () =>
                              _showNotificationSettingsSheet(context),
                        ),
                      ],
                    ),
                  ),

                  // ================= HEADER =================
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 2.4,
                        bottom:
                            16), // 20% higher (top: 12 * 0.2 = 2.4, reduced bottom: 20 * 0.8 = 16)
                    child: SediHeader(
                      isThinking: _controller.isThinking,
                      isAlert: _controller.isAlert,
                      size: 134.4, // 20% smaller (168 * 0.8 = 134.4)
                    ),
                  ),

                  // ================= MESSAGES AREA =================
                  Expanded(
                    child: _controller.conversationState ==
                                ConversationState.initializing &&
                            _controller.messages.isEmpty
                        ? const AppLoadingState(
                            label: 'Loading conversation...')
                        : _controller.messages.isEmpty
                            ? const AppEmptyState(
                                title: 'No messages yet',
                                subtitle:
                                    'Start by sending your first message.',
                              )
                            : Stack(
                                children: [
                                  // لیست تمام پیام‌ها (همه در یک لیست)
                                  ListView.builder(
                                    controller: _scrollController,
                                    reverse: true, // آخرین پیام در پایین
                                    physics:
                                        const AlwaysScrollableScrollPhysics(), // Enable manual scrolling
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      top:
                                          9.6, // 20% more space (8 * 1.2 = 9.6)
                                      bottom: keyboardHeight > 0
                                          ? 100 // Space for input bar when keyboard is open
                                          : 100, // Space for input bar when keyboard is closed
                                    ),
                                    itemCount: _controller.messages.length +
                                        (_controller.isThinking ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (_controller.isThinking &&
                                          index == 0) {
                                        return const Padding(
                                          padding: EdgeInsets.only(bottom: 9.6),
                                          child: MessageBubble(
                                            message: '...',
                                            isSedi: true,
                                            showTyping: true,
                                          ),
                                        );
                                      }
                                      // از آخر به اول (چون reverse: true)
                                      final effectiveIndex =
                                          _controller.isThinking
                                              ? index - 1
                                              : index;
                                      final reverseIndex =
                                          _controller.messages.length -
                                              1 -
                                              effectiveIndex;
                                      final msg =
                                          _controller.messages[reverseIndex];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 9.6),
                                        child: MessageBubble(
                                          message: msg.text,
                                          isSedi: msg.isSedi,
                                          isFailed: msg.isUser &&
                                              msg.status ==
                                                  ChatMessageStatus.failed,
                                          onRetry: msg.isUser &&
                                                  msg.status ==
                                                      ChatMessageStatus.failed
                                              ? () => _controller
                                                  .retryFailedMessage(
                                                      msg.localId)
                                              : null,
                                        ),
                                      );
                                    },
                                  ),

                                  // دکمه بازگشت به آخرین پیام (سمت چپ پایین، بالای چت باکس)
                                  if (_scrollController.hasClients &&
                                      _scrollController.offset > 100)
                                    Positioned(
                                      left: 16,
                                      bottom: keyboardHeight > 0
                                          ? keyboardHeight +
                                              60 // Position above input bar when keyboard is open
                                          : 100, // Position above input bar when keyboard is closed
                                      child: _ScrollToBottomButton(
                                        scrollController: _scrollController,
                                        onTap: _scrollToBottom,
                                      ),
                                    ),
                                ],
                              ),
                  ),
                ],
              ),

              // ================= INPUT BAR (full width within SafeArea) =================
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: InputBar(
                  hintText: _inputHint(),
                  isRecording: _controller.isRecording,
                  recordingTime: _controller.recordingTimeFormatted,
                  onSendText: _handleSendText,
                  onStartRecording: () {
                    _controller.startVoiceRecording().then((ok) {
                      if (!mounted) return;
                      if (ok == false) {
                        final msg = _controller.currentLanguage == 'fa'
                            ? 'دسترسی به میکروفون لازم است'
                            : _controller.currentLanguage == 'ar'
                                ? 'مطلوب إذن الميكروفون'
                                : 'Microphone permission required';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                                bottom: 100, left: 16, right: 16),
                          ),
                        );
                      }
                    });
                  },
                  onStopRecordingAndSend: () {
                    _controller.stopVoiceRecording().then((path) {
                      if (!mounted) return;
                      if (path != null) {
                        if (kDebugMode)
                          debugPrint('[Audio] recorded file: $path');
                        final msg = _controller.currentLanguage == 'fa'
                            ? 'صدایت ضبط شد'
                            : _controller.currentLanguage == 'ar'
                                ? 'تم تسجيل الصوت'
                                : 'Voice recorded';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(
                                bottom: 100, left: 16, right: 16),
                          ),
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: content,
    );
  }
}

/// Bottom sheet content for lifestyle summary (Stage 17.2).
class _LifestyleSummarySheetContent extends StatefulWidget {
  final ChatController controller;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const _LifestyleSummarySheetContent({
    required this.controller,
    required this.scrollController,
    required this.onClose,
  });

  @override
  State<_LifestyleSummarySheetContent> createState() =>
      _LifestyleSummarySheetContentState();
}

class _LifestyleSummarySheetContentState
    extends State<_LifestyleSummarySheetContent> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.fetchLifestyleSummary(forceRefresh: false);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => widget.controller
                        .fetchLifestyleSummary(forceRefresh: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: LifestyleSummaryCard(
              data: widget.controller.cachedLifestyleSummary,
              isLoading: widget.controller.lifestyleSummaryLoading,
              error: widget.controller.lifestyleSummaryError,
              onRetry: () =>
                  widget.controller.fetchLifestyleSummary(forceRefresh: true),
              lang: widget.controller.currentLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Settings V1: channel toggles, quiet hours, engagement, sound. Persisted locally.
class _NotificationSettingsSheet extends StatefulWidget {
  final void Function(String text) onSend;
  final String lang;

  const _NotificationSettingsSheet({required this.onSend, required this.lang});

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _loaded = false;
  final Map<String, bool> _channelEnabled = {};
  String _quietStart = kDefaultQuietStart;
  String _quietEnd = kDefaultQuietEnd;
  String _engagementLevel = kDefaultEngagementLevel;
  String _soundKey = kDefaultSoundKey;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final start = await NotificationPrefs.getQuietHoursStart();
      final end = await NotificationPrefs.getQuietHoursEnd();
      final engagement = await NotificationPrefs.getEngagementLevel();
      final sound = await NotificationPrefs.getSoundKey();
      final channelMap = <String, bool>{};
      for (final ch in kNotificationChannels) {
        channelMap[ch] = await NotificationPrefs.getChannelEnabled(ch);
      }
      if (mounted) {
        setState(() {
          _quietStart = start;
          _quietEnd = end;
          _engagementLevel = engagement;
          _soundKey = sound;
          _channelEnabled.addAll(channelMap);
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          for (final ch in kNotificationChannels) {
            _channelEnabled[ch] = true;
          }
          _loaded = true;
        });
      }
    }
  }

  String _l(String en, String fa, String ar) {
    if (widget.lang == 'fa') return fa;
    if (widget.lang == 'ar') return ar;
    return en;
  }

  String _channelLabel(String channel) {
    switch (channel) {
      case 'companion':
        return _l('Companion', 'همراه', 'الرفيق');
      case 'health_alert':
        return _l('Health alerts', 'هشدار سلامت', 'تنبيهات الصحة');
      case 'medication':
        return _l('Medication', 'دارو', 'الدواء');
      case 'appointment':
        return _l('Appointment', 'نوبت', 'الموعد');
      case 'system':
        return _l('System', 'سیستم', 'النظام');
      default:
        return channel;
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _quietStart : _quietEnd;
    final parts = current.split(':');
    var h = 22;
    var m = 30;
    if (parts.length >= 2) {
      h = int.tryParse(parts[0]) ?? h;
      m = int.tryParse(parts[1]) ?? m;
    }
    final initial = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (isStart) {
      await NotificationPrefs.setQuietHoursStart(value);
      if (mounted) setState(() => _quietStart = value);
    } else {
      await NotificationPrefs.setQuietHoursEnd(value);
      if (mounted) setState(() => _quietEnd = value);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.pistachioGreen),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _l('Notification settings', 'تنظیمات اعلان‌ها',
                'إعدادات الإشعارات'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          // Channel toggles
          Text(
            _l('Channels', 'کانال‌ها', 'القنوات'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...kNotificationChannels.map((channel) {
            final enabled = _channelEnabled[channel] ?? true;
            return SwitchListTile(
              value: enabled,
              onChanged: (v) async {
                await NotificationPrefs.setChannelEnabled(channel, v);
                if (mounted) setState(() => _channelEnabled[channel] = v);
              },
              title: Text(
                _channelLabel(channel),
                style:
                    const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Quiet hours
          Text(
            _l('Quiet hours', 'ساعات سکوت', 'ساعات الهدوء'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bedtime_outlined,
                      color: AppTheme.primaryBlack, size: 22),
                  title:
                      Text(_quietStart, style: const TextStyle(fontSize: 15)),
                  subtitle: Text(_l('Start', 'شروع', 'بداية'),
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  onTap: () => _pickTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_outlined,
                      color: AppTheme.primaryBlack, size: 22),
                  title: Text(_quietEnd, style: const TextStyle(fontSize: 15)),
                  subtitle: Text(_l('End', 'پایان', 'نهاية'),
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Engagement frequency
          Text(
            _l('Companion frequency', 'تکرار همراه', 'تكرار الرفيق'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['low', 'normal', 'high'].map((level) {
              final isSelected = _engagementLevel == level;
              final label = level == 'low'
                  ? _l('Low', 'کم', 'منخفض')
                  : level == 'high'
                      ? _l('High', 'زیاد', 'عالي')
                      : _l('Normal', 'معمولی', 'عادي');
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (v) async {
                  if (!v) return;
                  await NotificationPrefs.setEngagementLevel(level);
                  if (mounted) setState(() => _engagementLevel = level);
                },
                selectedColor: AppTheme.pistachioGreen.withOpacity(0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Sound
          Text(
            _l('Sound', 'صدای اعلان', 'صوت الإشعار'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...kSoundKeys.map((key) {
            final label = key == 'default'
                ? _l('Default', 'پیش‌فرض', 'افتراضي')
                : key == 'soft'
                    ? _l('Soft', 'ملایم', 'ناعم')
                    : key == 'chime'
                        ? _l('Chime', 'زنگ', 'نغمة')
                        : key == 'pulse'
                            ? _l('Pulse', 'پالس', 'نبض')
                            : _l('Silent', 'بی‌صدا', 'صامت');
            return RadioListTile<String>(
              value: key,
              groupValue: _soundKey,
              onChanged: (v) async {
                if (v == null) return;
                await NotificationPrefs.setSoundKey(v);
                if (mounted) setState(() => _soundKey = v);
              },
              title: Text(label, style: const TextStyle(fontSize: 15)),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.lang == 'fa' || widget.lang == 'ar';
    return SafeArea(
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: _buildContent(context),
      ),
    );
  }
}

/// ============================================
/// ScrollToBottomButton - دکمه برگشت به آخرین چت
/// ============================================
///
/// آیکن مثلث برعکس سفید داخل کادر دایره‌ای مشکی
/// با کلیک رنگ کادر دایره‌ای به خاکستری تغییر می‌کند
/// ============================================
class _ScrollToBottomButton extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onTap;

  const _ScrollToBottomButton({
    required this.scrollController,
    required this.onTap,
  });

  @override
  State<_ScrollToBottomButton> createState() => _ScrollToBottomButtonState();
}

class _ScrollToBottomButtonState extends State<_ScrollToBottomButton> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTap() {
    setState(() {
      _isPressed = true;
    });
    widget.onTap();
    // Reset pressed state after animation
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed
              ? AppTheme.metalGrey // Grey when pressed
              : AppTheme.primaryBlack, // Black when not pressed
        ),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.backgroundWhite,
          size: 24,
        ),
      ),
    );
  }
}
