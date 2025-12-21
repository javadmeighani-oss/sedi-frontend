import 'package:flutter/material.dart';

import '../../state/chat_controller.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/sedi_header.dart';
import '../widgets/rotary_scrollbar.dart';
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
    _controller.initialize();
  }

  @override
  void dispose() {
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

            // ================= MESSAGES + SCROLL =================
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _controller.messages.length,
                    itemBuilder: (context, index) {
                      final msg = _controller.messages[index];
                      return MessageBubble(
                        message: msg.text,
                        isSedi: msg.isSedi,
                      );
                    },
                  ),

                  // Rotary scrollbar overlay
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: RotaryScrollbar(
                      controller: _scrollController,
                      height: MediaQuery.of(context).size.height * 0.6,
                    ),
                  ),
                ],
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
