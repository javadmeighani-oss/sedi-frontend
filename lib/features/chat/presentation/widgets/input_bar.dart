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

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _expanded = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
        curve: Curves.easeOut,
        height: _expanded ? 120 : 56,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black87,
            width: 1.2, // فقط همین کادر باید دیده شود
          ),
        ),
        child: Row(
          crossAxisAlignment:
              _expanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // ================= TEXT =================
            Expanded(
              child: Theme(
                // 🔴 خنثی‌سازی کامل Theme سراسری فقط در این ویجت
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: _expanded ? 4 : 1,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Colors.black45,
                    ),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ================= MIC =================
            GestureDetector(
              onTap: widget.isRecording
                  ? widget.onStopRecordingAndSend
                  : widget.onStartRecording,
              child: Row(
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    size: 34, // بزرگ‌تر (×۲)
                    color: Colors.black,
                  ),
                  if (widget.isRecording) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.recordingTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ================= SEND =================
            GestureDetector(
              onTap: _send,
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 36, // بزرگ‌تر (×۲)
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
