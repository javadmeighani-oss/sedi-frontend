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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ============================================
            // آیکن تاریخچه چت (بالا سمت چپ)
            // ============================================
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // آیکن تاریخچه چت
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: باز کردن صفحه تاریخچه چت (دسته‌بندی شده)
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.history_rounded,
                          color: AppTheme.pistachioGreen,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // ============================================
            // لوگوی صدی در بالا و وسط با حلقه تپنده
            // ============================================
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.025,
              ),
              child: SediHeader(
                isThinking: _controller.isThinking,
                isAlert: _controller.isAlert,
                size: 168, // 20% بزرگتر (140 * 1.2 = 168)
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
                onVoiceStart: () {
                  _controller.startVoiceRecording();
                },
                onVoiceStop: () {
                  _controller.stopVoiceRecording();
                },
                isRecording: _controller.isRecording,
                recordingTime: _controller.recordingTimeFormatted,
              ),
            ),

            const SizedBox(height: 16),

            // ============================================
            // آخرین پیام (همیشه دیده می‌شود - زیر چت باکس)
            // ============================================
            if (_controller.lastMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: MessageBubble(
                  message: _controller.lastMessage!.text,
                  isSedi: !_controller.lastMessage!.isUser,
                ),
              ),

            const SizedBox(height: 12),

            // ============================================
            // پیام‌های قدیمی (با اسکرول چرخشی - بالای آخرین پیام)
            // ============================================
            Expanded(
              child: _controller.messages.length <= 1
                  ? const SizedBox.shrink()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // لیست پیام‌های قدیمی (بدون آخرین پیام)
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            itemCount: _controller.messages.length - 1,
                            itemBuilder: (context, index) {
                              final reversedIndex = (_controller.messages.length - 2) - index;
                              final msg = _controller.messages[reversedIndex];
                              return MessageBubble(
                                message: msg.text,
                                isSedi: !msg.isUser,
                              );
                            },
                          ),
                        ),

                        // اسکرول‌بار چرخنده (همیشه نمایش داده می‌شود)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: RotaryScrollbar(
                            controller: _scrollController,
                            height: screenHeight * 0.45,
                            color: AppTheme.pistachioGreen,
                          ),
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
