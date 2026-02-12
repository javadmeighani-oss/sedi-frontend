import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/lifestyle_summary_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/brand_name.dart';
import '../../../../core/utils/user_profile_manager.dart';
import 'chat_history_page.dart';
import '../../../devices/presentation/pages/devices_page.dart';
import '../../../health/presentation/pages/vitals_page.dart';
import '../../../notification/data/notification_service.dart';
import '../../../notification/logic/notification_sync.dart';
import '../../../notification/presentation/pages/notifications_inbox_page.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFromNotificationBanner());
    }
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
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    if (userId == null) {
      if (mounted) setState(() => _unreadCount = 0);
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
    _controller.removeListener(_scrollToBottomOnNewMessage); // Remove scroll listener
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

    return PopScope(
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
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsInboxPage(),
                                ),
                              ).then((_) => _refreshUnreadCount());
                            },
                          ),
                          if (_unreadCount != null && _unreadCount! > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  _unreadCount! > 99 ? '99+' : '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                        icon: const Icon(Icons.schedule_outlined),
                        iconSize: 24,
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlack,
                          minimumSize: const Size(44, 44),
                        ),
                        onPressed: () => _showNotificationSettingsSheet(context),
                      ),
                    ],
                  ),
                ),

                // ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.only(top: 2.4, bottom: 16), // 20% higher (top: 12 * 0.2 = 2.4, reduced bottom: 20 * 0.8 = 16)
                  child: SediHeader(
                    isThinking: _controller.isThinking,
                    isAlert: _controller.isAlert,
                    size: 134.4, // 20% smaller (168 * 0.8 = 134.4)
                  ),
                ),

                // ================= MESSAGES AREA =================
                Expanded(
                  child: Stack(
                    children: [
                      // لیست تمام پیام‌ها (همه در یک لیست)
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true, // آخرین پیام در پایین
                        physics: const AlwaysScrollableScrollPhysics(), // Enable manual scrolling
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 9.6, // 20% more space (8 * 1.2 = 9.6)
                          bottom: keyboardHeight > 0 
                              ? 100 // Space for input bar when keyboard is open
                              : 100, // Space for input bar when keyboard is closed
                        ),
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          // از آخر به اول (چون reverse: true)
                          final reverseIndex =
                              _controller.messages.length - 1 - index;
                          final msg = _controller.messages[reverseIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 9.6),
                            child: MessageBubble(
                              message: msg.text,
                              isSedi: msg.isSedi,
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
                              ? keyboardHeight + 60 // Position above input bar when keyboard is open
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
                onStartRecording: _controller.startVoiceRecording,
                onStopRecordingAndSend: _controller.stopVoiceRecording,
              ),
            ),
            
          ],
        ),
        ),
      ),
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
  State<_LifestyleSummarySheetContent> createState() => _LifestyleSummarySheetContentState();
}

class _LifestyleSummarySheetContentState extends State<_LifestyleSummarySheetContent> {
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
                    onPressed: () => widget.controller.fetchLifestyleSummary(forceRefresh: true),
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
              onRetry: () => widget.controller.fetchLifestyleSummary(forceRefresh: true),
              lang: widget.controller.currentLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for notification settings quick actions (Stage 16.6.6).
class _NotificationSettingsSheet extends StatefulWidget {
  final void Function(String text) onSend;
  final String lang;

  const _NotificationSettingsSheet({required this.onSend, required this.lang});

  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  final _timezoneController = TextEditingController(text: 'timezone: Asia/Tehran');

  @override
  void dispose() {
    _timezoneController.dispose();
    super.dispose();
  }

  String _l(String en, String fa, String ar) {
    if (widget.lang == 'fa') return fa;
    if (widget.lang == 'ar') return ar;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _l('Notification settings', 'تنظیمات اعلان‌ها', 'إعدادات الإشعارات'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlack,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.public, color: AppTheme.primaryBlack, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _timezoneController,
                    decoration: const InputDecoration(
                      hintText: 'timezone: Asia/Tehran',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final t = _timezoneController.text.trim();
                    if (t.isNotEmpty) widget.onSend(t);
                  },
                  child: Text(_l('Send', 'ارسال', 'إرسال')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bedtime_outlined, color: AppTheme.primaryBlack, size: 24),
              title: Text(_l('Set quiet hours 22:00–08:00', 'تنظیم ساعات سکوت', 'تعيين ساعات الهدوء')),
              trailing: FilledButton(
                onPressed: () => widget.onSend('quiet hours 22:00-08:00'),
                child: Text(_l('Send', 'ارسال', 'إرسال')),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_off_outlined, color: AppTheme.primaryBlack, size: 24),
              title: Text(_l('Disable quiet hours', 'خاموش کردن ساعات سکوت', 'إيقاف ساعات الهدوء')),
              trailing: FilledButton(
                onPressed: () => widget.onSend('disable quiet hours'),
                child: Text(_l('Send', 'ارسال', 'إرسال')),
              ),
            ),
          ],
        ),
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
