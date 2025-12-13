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
        return 'تحدّث مع سِدي…';
      default:
        return 'Talk to Sedi…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // =================== HEADER ===================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Spacer(),

                  // Vitals (رزرو شده)
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded),
                    color: AppTheme.pistachioGreen,
                    onPressed: () {
                      // TODO: vitals page
                    },
                  ),

                  // History
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    color: AppTheme.pistachioGreen,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatHistoryPage(chatController: _controller),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // =================== LOGO ===================
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 168,
              ),
            ),

            // =================== MESSAGES ===================
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = _controller.messages[index];
                  return MessageBubble(
                    message: msg.text,
                    isSedi: !msg.isUser,
                  );
                },
              ),
            ),

            // =================== INPUT ===================
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: InputBar(
                hintText: _inputHint(),
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
