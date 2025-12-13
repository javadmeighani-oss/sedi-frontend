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
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();
  }

  void _onControllerUpdate() {
    setState(() {});
    if (_controller.messages.length > _lastMessageCount) {
      _lastMessageCount = _controller.messages.length;
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
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ---------------- تاریخچه چت
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatHistoryPage(chatController: _controller),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.history_rounded, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- لوگو + حلقه تپنده
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.025,
              ),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 168,
              ),
            ),

            // ---------------- InputBar (اصلاح‌شده)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InputBar(
                hintText: _inputHint(),
                onSendText: _controller.sendUserMessage,
                onStartRecording: _controller.startVoiceRecording,
                onStopRecordingAndSend: _controller.stopVoiceRecording,
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- آخرین پیام
            if (_controller.lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: MessageBubble(
                  message: _controller.lastMessage!.text,
                  isSedi: !_controller.lastMessage!.isUser,
                ),
              ),

            const SizedBox(height: 12),

            // ---------------- پیام‌های قبلی
            Expanded(
              child: _controller.messages.length <= 1
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      itemCount: _controller.messages.length - 1,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            (_controller.messages.length - 2) - index;
                        final msg = _controller.messages[reversedIndex];
                        return MessageBubble(
                          message: msg.text,
                          isSedi: !msg.isUser,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
