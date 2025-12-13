import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final String hintText;
  final bool isRecording;
  final String recordingTime;
  final Function(String) onSendText;
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

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => expanded = _focusNode.hasFocus);
    });
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendText(_controller.text.trim());
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: expanded ? 160 : 64,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        children: [
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
          Row(
            textDirection: TextDirection.rtl,
            children: [
              IconButton(
                icon: const Icon(Icons.send_rounded),
                iconSize: 30,
                onPressed: _send,
              ),
              GestureDetector(
                onTap: widget.isRecording
                    ? widget.onStopRecordingAndSend
                    : widget.onStartRecording,
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded),
                    if (widget.isRecording)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(widget.recordingTime),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
