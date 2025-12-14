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

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendPressed = true);

    widget.onSendText(text);
    _controller.clear();
    _focusNode.unfocus();

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() => _sendPressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        height: _expanded ? 150 : 64,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? Colors.green.shade400 : Colors.black26,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            // ================= TEXT FIELD (NO INNER BOX) =================
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: _expanded ? 4 : 1,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
              ),
              style: const TextStyle(fontSize: 16),
            ),

            const Spacer(),

            // ================= ACTIONS =================
            Row(
              children: [
                // ---- LEFT SIDE TEXT SPACE ----
                const Spacer(),

                // ---- MIC ICON ----
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
                            widget.isRecording ? Colors.green : Colors.black54,
                      ),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            widget.recordingTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ---- SEND ICON ----
                GestureDetector(
                  onTap: _sendText,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _sendPressed ? Colors.green.shade400 : Colors.black12,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 26,
                      color: _sendPressed ? Colors.white : Colors.black,
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
