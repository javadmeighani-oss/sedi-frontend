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
  final TextEditingController _textController = TextEditingController();
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
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _textController.clear();
    _focusNode.unfocus();
  }

  void _ensureFocus() {
    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _ensureFocus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: _expanded ? 120 : 56,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(14), // مستطیل با گوشه کمی کرو (مثل تصویر)
            border: Border.all(
              color: Colors.black87,
              width: 1.2, // خط دور واضح
            ),
          ),
          child: Row(
            crossAxisAlignment: _expanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              // -------- Text (Left) --------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _expanded ? 10 : 0,
                    bottom: _expanded ? 10 : 0,
                    right: 6,
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.multiline,
                    maxLines: _expanded ? 4 : 1,
                    decoration: InputDecoration(
                      hintText:
                          widget.hintText, // متن “Talk to Sedi…” داخل چت‌باکس
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),

              // -------- Mic (Right) --------
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.isRecording
                    ? widget.onStopRecordingAndSend
                    : widget.onStartRecording,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded,
                          color: Colors.black, size: 22),
                      if (widget.isRecording) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.recordingTime,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // -------- Send (Far Right) --------
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _sendText,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Icon(
                    Icons.arrow_upward_rounded, // مثل تصویر (فلش رو به بالا)
                    color: Colors.black,
                    size: 22,
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
