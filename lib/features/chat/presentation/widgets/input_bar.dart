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

  void _sendText() {
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
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        height: _expanded ? 140 : 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _expanded ? Colors.black : Colors.black38,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            // ================= TEXT FIELD =================
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration.collapsed(
                  hintText: widget.hintText,
                ),
              ),
            ),

            const SizedBox(height: 6),

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
                        size: 26,
                        color:
                            widget.isRecording ? Colors.black : Colors.black38,
                      ),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            widget.recordingTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ---------- Send ----------
                GestureDetector(
                  onTap: _sendText,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.text.trim().isNotEmpty
                          ? Colors.black12
                          : Colors.black12.withOpacity(0.4),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 24,
                      color: _controller.text.trim().isNotEmpty
                          ? Colors.black
                          : Colors.black38,
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
