import 'package:flutter/material.dart';
import '../../state/chat_controller.dart';
import '../widgets/sedi_header.dart';
import '../widgets/input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/rotary_scrollbar.dart';

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

    // مقداردهی اولیه کنترلر
    _controller.initialize();

    _controller.addListener(() {
      setState(() {});
      // اسکرول خودکار فقط وقتی پیام جدید اضافه می‌شود
      if (_controller.messages.length > _lastMessageCount) {
        _lastMessageCount = _controller.messages.length;
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color brandColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------
            //       هدر صدی (لوگو + حلقه)
            // -----------------------------
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
              ),
            ),

            const SizedBox(height: 12),

            // -----------------------------
            //    چت‌باکس هوشمند
            // -----------------------------
            InputBar(
              brandColor: brandColor,
              onSendText: (text) {
                _controller.sendUserMessage(text);
                _scrollToBottom();
              },
              onVoiceTap: () {
                _controller.startVoiceInput();
              },
            ),

            const SizedBox(height: 8),

            // -----------------------------
            //   پیام‌های صدی + اسکرول
            // -----------------------------
            Expanded(
              child: Row(
                children: [
                  // پیام‌ها
                  Expanded(
                    child: _controller.messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true, // پیام جدید در پایین
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            itemCount: _controller.messages.length,
                            itemBuilder: (context, index) {
                              // معکوس کردن index برای نمایش صحیح
                              final reversedIndex =
                                  _controller.messages.length - 1 - index;
                              final msg = _controller.messages[reversedIndex];
                              return MessageBubble(
                                message: msg.text,
                                isSedi: msg.isSedi,
                              );
                            },
                          ),
                  ),

                  // اسکرول‌بار چرخنده (فقط وقتی پیام وجود دارد)
                  if (_controller.messages.isNotEmpty)
                    RotaryScrollbar(
                      controller: _scrollController,
                      height: MediaQuery.of(context).size.height * 0.55,
                      color: brandColor,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      // چون reverse است، باید به 0 برویم
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildEmptyState() {
    final brandColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: brandColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'سلام! من صدی هستم 😊',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'چطور می‌تونم کمکت کنم؟',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 18,
                  color: brandColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'یا با میکروفن صحبت کن',
                  style: TextStyle(
                    fontSize: 14,
                    color: brandColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
