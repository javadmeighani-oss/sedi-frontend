import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecordingAndSend;

  const InputBar({
    super.key,
    required this.hintText,
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
      setState(() => _expanded = _focusNode.hasFocus);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
    _focusNode.unfocus(); // جمع شدن چت‌باکس
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: _expanded ? 220 : 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // ---------- Text Input ----------
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
              ),
            ),
          ),

          // ---------- Actions ----------
          Row(
            children: [
              const Spacer(),

              // SEND (اول از راست، بزرگ‌تر)
              IconButton(
                icon: const Icon(Icons.send_rounded),
                iconSize: 30,
                color: Colors.black,
                onPressed: _send,
              ),

              // MIC (بعد از send)
              GestureDetector(
                onLongPress: widget.onStartRecording,
                onLongPressUp: widget.onStopRecordingAndSend,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
