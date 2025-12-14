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
        height: _expanded ? 150 : 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            // =========================
            // Text Input (بدون Expanded)
            // =========================
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: false,
              enabled: true,
              readOnly: false,
              keyboardType: TextInputType.multiline,
              maxLines: _expanded ? 4 : 1,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),

            const Spacer(),

            // =========================
            // Actions
            // =========================
            Row(
              textDirection: TextDirection.rtl,
              children: [
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  iconSize: 30,
                  onPressed: _sendText,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.isRecording
                      ? widget.onStopRecordingAndSend
                      : widget.onStartRecording,
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            widget.recordingTime,
                            style: const TextStyle(fontSize: 12),
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
