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
      if (mounted) {
        setState(() {
          _expanded = _focusNode.hasFocus;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: _expanded ? 140 : 56,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black87,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================
            // Text Input (بدون باکس اضافه)
            // =========================
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: TextInputType.multiline,
              maxLines: _expanded ? 4 : 1,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isDense: true,
              ),
            ),

            const Spacer(),

            // =========================
            // Actions (دقیقاً مطابق طراحی)
            // =========================
            Row(
              textDirection: TextDirection.rtl,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _sendText,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 26,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.isRecording
                      ? widget.onStopRecordingAndSend
                      : widget.onStartRecording,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mic_rounded,
                        size: 22,
                        color: Colors.black,
                      ),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
