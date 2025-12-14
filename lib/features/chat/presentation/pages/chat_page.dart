import 'package:flutter/material.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_history_page.dart';

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
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _inputHint() {
    switch (_controller.currentLanguage) {
      case 'fa':
        return 'صحبت با صدی…';
      case 'ar':
        return 'تحدث مع سدي…';
      default:
        return 'Talk to Sedi…';
    }
  }

  void _scrollToLatest() {
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
    final messages = _controller.messages;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // ================= MAIN CONTENT =================
            Column(
              children: [
                // ---------- Top icons ----------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.favorite_rounded),
                        color: AppTheme.pistachioGreen,
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_rounded),
                        color: AppTheme.pistachioGreen,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatHistoryPage(
                                chatController: _controller,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ---------- Logo ----------
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: SediHeader(
                    isThinking: _controller.isThinking,
                    isAlert: _controller.isAlert,
                    size: 168,
                  ),
                ),

                // ---------- Messages ----------
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          return MessageBubble(
                            message: msg.text,
                            isSedi: !msg.isUser,
                          );
                        },
                      ),

                      // ---------- Scroll to latest ----------
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: _scrollToLatest,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 24,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ================= INPUT BAR =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: InputBar(
                hintText: _inputHint(),
                isRecording: _controller.isRecording,
                recordingTime: _controller.recordingTimeFormatted,
                onSendText: _controller.sendUserMessage,
                onStartRecording: _controller.startVoiceRecording,
                onStopRecordingAndSend: _controller.stopVoiceRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
