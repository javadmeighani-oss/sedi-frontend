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
      setState(() => _expanded = _focusNode.hasFocus);
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
        height: _expanded ? 130 : 56,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black87, width: 1.2),
        ),
        child: Stack(
          children: [
            // ================= TEXT =================
            Positioned(
              left: 0,
              right: _expanded ? 0 : 90,
              top: 0,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
                    hintStyle: const TextStyle(color: Colors.black45),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            // ================= ACTIONS =================
            Positioned(
              right: 0,
              bottom: _expanded ? 0 : null,
              top: _expanded ? null : 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // -------- MIC --------
                  GestureDetector(
                    onTap: widget.isRecording
                        ? widget.onStopRecordingAndSend
                        : widget.onStartRecording,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: widget.isRecording ? 1.0 : 0.45,
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // -------- SEND --------
                  GestureDetector(
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.06),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 28,
                        color: Colors.black,
                      ),
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
