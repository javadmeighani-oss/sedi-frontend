import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_history_page.dart';

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
  
  const ChatPage({super.key, this.initialMessage});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();

  // Double tap to exit variables
  DateTime? _lastBackPressTime;
  Timer? _backPressTimer;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    // Add listener to update UI when timer changes
    _controller.addListener(_onControllerChanged);
    // Auto-scroll to bottom when new message arrives
    _controller.addListener(_scrollToBottomOnNewMessage);
    _controller.initialize(initialMessage: widget.initialMessage);
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
    _backPressTimer?.cancel(); // Cancel timer if active
    _controller.removeListener(_onControllerChanged); // Remove listener
    _controller.removeListener(_scrollToBottomOnNewMessage); // Remove scroll listener
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _inputHint() {
    // CRITICAL: Input placeholder MUST ALWAYS be English (per requirements)
    // Language detection happens after first user message
    return 'Talk to Sedi…';
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
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        color: AppTheme.primaryBlack,
                        onPressed: () {
                          // later: daily health status
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        color: AppTheme.primaryBlack,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChatHistoryPage(),
                            ),
                          );
                        },
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

            // ================= INPUT BAR (Positioned above keyboard) =================
            Positioned(
              bottom: keyboardHeight, // Position InputBar above keyboard
              left: 0,
              right: 0,
              child: Center(
                // Center InputBar and allow custom width
                child: InputBar(
                  hintText: _inputHint(),
                  isRecording: _controller.isRecording,
                  recordingTime: _controller.recordingTimeFormatted,
                  onSendText: _controller.sendUserMessage,
                  onStartRecording: _controller.startVoiceRecording,
                  onStopRecordingAndSend: _controller.stopVoiceRecording,
                ),
              ),
            ),
            
          ],
        ),
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
