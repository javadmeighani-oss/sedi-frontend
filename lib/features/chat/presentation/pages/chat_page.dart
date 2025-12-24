import 'package:flutter/material.dart';

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
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    // Add listener to update UI when timer changes
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {}); // Update UI (including timer display)
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged); // Remove listener
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _inputHint() {
    switch (_controller.currentLanguage) {
      case 'fa':
        return 'صحبت با صدی…';
      case 'ar':
        return 'تحدّث مع سِدي…';
      default:
        return 'Talk to Sedi…';
    }
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

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to position InputBar above keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      // Prevent back navigation to IntroPage
      // IntroPage should only appear once at app start
      canPop: false,
      onPopInvoked: (didPop) {
        // If user tries to go back, exit the app instead
        // This ensures IntroPage only appears once
        if (didPop) {
          // Already handled by system
          return;
        }
        // Prevent navigation back to IntroPage
        // User can exit app using system back button if needed
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
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: SediHeader(
                    isThinking: _controller.isThinking,
                    isAlert: _controller.isAlert,
                    size: 168,
                  ),
                ),

                // ================= MESSAGES AREA =================
                Expanded(
                  child: Stack(
                    children: [
                      // لیست پیام‌های قبلی (اسکرول دستی)
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true, // آخرین پیام در پایین
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _controller.messages.length > 1
                            ? _controller.messages.length - 1
                            : 0,
                        itemBuilder: (context, index) {
                          // از آخر به اول (چون reverse: true)
                          final reverseIndex =
                              _controller.messages.length - 2 - index;
                          final msg = _controller.messages[reverseIndex];
                          return MessageBubble(
                            message: msg.text,
                            isSedi: msg.isSedi,
                          );
                        },
                      ),

                      // دکمه بازگشت به آخرین پیام (سمت راست پایین)
                      if (_scrollController.hasClients &&
                          _scrollController.offset > 100)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            backgroundColor: AppTheme.pistachioGreen,
                            onPressed: _scrollToBottom,
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppTheme.backgroundWhite,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ================= آخرین پیام (همیشه دیده می‌شود) =================
                if (_controller.messages.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: MessageBubble(
                      message: _controller.messages.last.text,
                      isSedi: _controller.messages.last.isSedi,
                    ),
                  ),

                // ================= SPACER FOR INPUT BAR =================
                // Add space at bottom so content doesn't go under InputBar
                SizedBox(height: keyboardHeight > 0 ? 0 : 80),
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
