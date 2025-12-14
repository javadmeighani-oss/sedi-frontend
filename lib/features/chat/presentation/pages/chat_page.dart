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

  bool _showScrollToLatest = false;

  @override
  void initState() {
    super.initState();

    _controller = ChatController();
    _controller.addListener(_onControllerUpdate);
    _controller.initialize();

    _scrollController.addListener(_onScroll);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;

    final shouldShow = (max - current) > 80;
    if (shouldShow != _showScrollToLatest) {
      setState(() => _showScrollToLatest = shouldShow);
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // =========================
            // Main Content
            // =========================
            Column(
              children: [
                // ---------- Top Icons ----------
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

                // ---------- Sedi Header ----------
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
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      140, // space for InputBar
                    ),
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
              ],
            ),

            // =========================
            // Scroll to latest button
            // =========================
            if (_showScrollToLatest)
              Positioned(
                bottom: 110,
                right: 16,
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

            // =========================
            // Input Bar (Overlay)
            // =========================
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
