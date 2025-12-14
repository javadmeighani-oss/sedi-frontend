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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: _expanded ? 150 : 64,
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black87,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= TEXT INPUT =================
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration.collapsed(
                  hintText: widget.hintText,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),

            // ================= ACTIONS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ---------- Mic ----------
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
                            widget.isRecording ? Colors.black : Colors.black54,
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
                const SizedBox(width: 12),

                // ---------- Send ----------
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.text.isEmpty
                          ? Colors.grey.shade300
                          : Colors.black,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _controller.text.isEmpty
                          ? Colors.black54
                          : Colors.white,
                      size: 22,
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
