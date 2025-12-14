import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final String hintText;
  final bool isRecording;
  final String recordingTime;
  final ValueChanged<String> onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecordingAndSend;

  const InputBar({
    super.key,
    required this.hintText,
    required this.isRecording,
    required this.recordingTime,
    required this.onSendText,
    required this.onStartRecording,
    required this.onStopRecordingAndSend,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _expanded = false;
  bool _sendPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _expanded = _focusNode.hasFocus);
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: _expanded ? 150 : 64,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black87),
        ),
        child: Column(
          children: [
            // ---------- Text ----------
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: _expanded ? 4 : 1,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isCollapsed: true,
              ),
            ),

            const Spacer(),

            // ---------- Actions ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Mic
                GestureDetector(
                  onTap: widget.isRecording
                      ? widget.onStopRecordingAndSend
                      : widget.onStartRecording,
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 28,
                        color:
                            widget.isRecording ? Colors.black : Colors.black38,
                      ),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            widget.recordingTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Send
                GestureDetector(
                  onTapDown: (_) => setState(() => _sendPressed = true),
                  onTapUp: (_) {
                    setState(() => _sendPressed = false);
                    _send();
                  },
                  onTapCancel: () => setState(() => _sendPressed = false),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sendPressed ? Colors.black26 : Colors.black12,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 26,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
