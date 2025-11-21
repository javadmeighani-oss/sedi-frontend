import 'package:flutter/material.dart';
import '../../state/chat_controller.dart';
import '../widgets/sedi_header.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rotary_scrollbar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _controller = ChatController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await _controller.sendUserMessage(text);

    _textController.clear();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// لوگوی صدی + حلقه تپشی
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Center(
                  child: SediHeader(
                    size: 165,
                    isThinking: _controller.isThinking,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// چت‌باکس زیر لوگو
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return InputBar(
                    controller: _textController,
                    isTyping: _controller.isTyping,
                    onTextChanged: (value) =>
                        _controller.setTyping(value.trim().isNotEmpty),
                    onSendMessage: _sendMessage,
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            /// ناحیه پیام‌ها + اسکرول‌بار چرخشی
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    children: [
                      /// پیام‌ها
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 20,
                          left: 24,
                          right: 8,
                        ),
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _controller.messages[index];
                          final isLast =
                              index == _controller.messages.length - 1;

                          return MessageBubble(
                            message: msg.text,
                            isSedi: msg.isFromSedi,
                            showOnlyLast: false,
                            isLast: isLast,
                          );
                        },
                      ),

                      /// اسکرول‌بار چرخشی
                      Positioned(
                        right: 0,
                        top: screenHeight * 0.12,
                        child: RotaryScrollbar(
                          controller: _scrollController,
                          height: screenHeight * 0.55,
                        ),
                      ),
                    ],
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
