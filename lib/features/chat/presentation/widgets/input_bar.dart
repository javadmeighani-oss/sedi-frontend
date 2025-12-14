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

class _InputBarState extends State<InputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get _hasText => _textController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendText() {
    if (!_hasText) return;
    widget.onSendText(_textController.text.trim());
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  _focusNode.hasFocus ? Colors.green.shade300 : Colors.black26,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ================= TEXT INPUT =================
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.multiline,
                    maxLines: _focusNode.hasFocus ? 4 : 1,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // ================= MIC =================
              GestureDetector(
                onTap: widget.isRecording
                    ? widget.onStopRecordingAndSend
                    : widget.onStartRecording,
                child: Row(
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      size: 30,
                      color: widget.isRecording ? Colors.black : Colors.black38,
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

              const SizedBox(width: 8),

              // ================= SEND =================
              GestureDetector(
                onTap: _hasText ? _sendText : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasText ? Colors.green.shade400 : Colors.black12,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: _hasText ? Colors.white : Colors.black38,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
