import 'package:flutter/material.dart';
import '../../state/chat_controller.dart';
import '../widgets/sedi_header.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rotary_scrollbar.dart';
import '../../../../core/theme/app_theme.dart';

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
    // initialize باید await شود اما در initState نمی‌توانیم await کنیم
    // پس بدون await صدا می‌زنیم
    _controller.initialize();
  }

  void _onControllerUpdate() {
    setState(() {});
    // اسکرول خودکار فقط وقتی پیام جدید اضافه می‌شود
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ============================================
            // لوگوی صدی در بالا و وسط با حلقه تپنده
            // ============================================
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 140, // لوگوی بزرگ
              ),
            ),

            // ============================================
            // چت باکس (زیر لوگو)
            // ============================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InputBar(
                brandColor: AppTheme.pistachioGreen,
                onSendText: (text) {
                  _controller.sendUserMessage(text);
                },
                onVoiceTap: () {
                  _controller.startVoiceInput();
                },
              ),
            ),

            const SizedBox(height: 12),

            // ============================================
            // آخرین پیام (همیشه دیده می‌شود - زیر چت باکس)
            // ============================================
            if (_controller.lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MessageBubble(
                  message: _controller.lastMessage!.text,
                  isSedi: !_controller.lastMessage!.isUser,
                ),
              ),

            const SizedBox(height: 8),

            // ============================================
            // پیام‌های قدیمی (با اسکرول چرخشی - بالای آخرین پیام)
            // ============================================
            Expanded(
              child: _controller.messages.length <= 1
                  ? const SizedBox.shrink() // اگر فقط یک پیام داریم، اسکرول نشان نده
                  : Row(
                      children: [
                        // لیست پیام‌های قدیمی (بدون آخرین پیام)
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true, // پیام قدیمی در بالا (reverse برای اسکرول از پایین)
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: _controller.messages.length - 1, // بدون آخرین پیام
                            itemBuilder: (context, index) {
                              // معکوس کردن index برای نمایش صحیح
                              final reversedIndex = (_controller.messages.length - 2) - index;
                              final msg = _controller.messages[reversedIndex];
                              return MessageBubble(
                                message: msg.text,
                                isSedi: !msg.isUser,
                              );
                            },
                          ),
                        ),

                        // اسکرول‌بار چرخنده (فقط وقتی بیش از یک پیام داریم)
                        if (_controller.messages.length > 1)
                          RotaryScrollbar(
                            controller: _scrollController,
                            height: MediaQuery.of(context).size.height * 0.4,
                            color: AppTheme.pistachioGreen,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
