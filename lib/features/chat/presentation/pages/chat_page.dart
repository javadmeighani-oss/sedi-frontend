import 'package:flutter/material.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../widgets/rotary_scroll_bar.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_history_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController();
    _controller.initialize();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP BAR =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Spacer(),

                  // Health Status Icon (placeholder)
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    color: AppTheme.primaryBlack,
                    onPressed: () {
                      // later: open daily health status
                    },
                  ),

                  // Chat History Icon
                  IconButton(
                    icon: const Icon(Icons.history),
                    color: AppTheme.primaryBlack,
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

            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 168,
              ),
            ),

            // ================= MESSAGES =================
            Expanded(
              child: RotaryScrollBar(
                messages: _controller.messages,
                builder: (context, message) {
                  return MessageBubble(
                    message: message.text,
                    isSedi: !message.isUser,
                  );
                },
              ),
            ),

            // ================= INPUT BAR =================
            InputBar(
              hintText: _inputHint(),
              isRecording: _controller.isRecording,
              recordingTime: _controller.recordingTimeFormatted,
              onSendText: _controller.sendUserMessage,
              onStartRecording: _controller.startVoiceRecording,
              onStopRecordingAndSend: _controller.stopVoiceRecording,
            ),
          ],
        ),
      ),
    );
  }
}
