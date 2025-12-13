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

  static const double _collapsedHeight = 56;
  static const double _expandedHeight = 140; // ارتفاع امن و قابل تایپ

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
    _focusNode.unfocus(); // جمع شدن بعد از ارسال
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _expanded ? _expandedHeight : _collapsedHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                hintText: widget.hintText, // 👈 اینجا placeholder
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),

          // ---------- Actions ----------
          Row(
            textDirection: TextDirection.rtl, // قفل ترتیب آیکن‌ها
            children: [
              // SEND – اول از راست
              IconButton(
                icon: const Icon(Icons.send_rounded),
                iconSize: 30,
                color: Colors.black,
                onPressed: _send,
              ),

              // MIC – بعدش
              GestureDetector(
                onLongPress: widget.onStartRecording,
                onLongPressUp: widget.onStopRecordingAndSend,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.mic_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
