import 'package:flutter/material.dart';
import '../../state/chat_controller.dart';
import '../widgets/sedi_header.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_history_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _controller = ChatController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    setState(() {});
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ================= Header =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Spacer(),

                  // آیکن علائم حیاتی (راست بالا - دائمی)
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded),
                    color: AppTheme.pistachioGreen,
                    onPressed: () {
                      // TODO: navigate to vitals page
                    },
                  ),

                  // آیکن تاریخچه چت
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

            // ================= Logo + Ring =================
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.015,
                bottom: screenHeight * 0.02,
              ),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 168,
              ),
            ),

            // ================= Messages (Center) =================
            Expanded(
              child: _controller.messages.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _controller.messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            (_controller.messages.length - 1) - index;
                        final msg = _controller.messages[reversedIndex];
                        return MessageBubble(
                          message: msg.text,
                          isSedi: !msg.isUser,
                        );
                      },
                    ),
            ),

            // ================= InputBar (Bottom Fixed) =================
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
