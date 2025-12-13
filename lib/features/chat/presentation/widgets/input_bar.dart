import 'dart:async';
import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final Future<void> Function(String text) onSendText;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecordingAndSend;

  /// Placeholder (dynamic based on detected language)
  final String hintText;

  const InputBar({
    super.key,
    required this.onSendText,
    required this.onStartRecording,
    required this.onStopRecordingAndSend,
    required this.hintText,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isRecording = false;
  Timer? _timer;
  Duration _recordDuration = Duration.zero;

  static const double _collapsedHeight = 56;
  static const double _expandedHeight = 56 * 4;

  bool get _isExpanded =>
      _focusNode.hasFocus || _controller.text.isNotEmpty || _isRecording;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _recordDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordDuration += const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await widget.onSendText(text);

    _controller.clear();
    _focusNode.unfocus();
    setState(() {});
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _startTimer();
    widget.onStartRecording();
  }

  void _stopRecordingAndSend() {
    _stopTimer();
    setState(() => _isRecording = false);
    widget.onStopRecordingAndSend();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // RTL only when hint is Persian/Arabic; otherwise LTR
    final bool isRtl = RegExp(r'[\u0600-\u06FF]').hasMatch(widget.hintText);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _isExpanded ? _expandedHeight : _collapsedHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Expanded(
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.hintText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_isRecording)
                Text(
                  _format(_recordDuration),
                  style: const TextStyle(fontSize: 14),
                ),

              const Spacer(),

              // SEND – بزرگ‌تر و مشکی (اول از سمت راست)
              IconButton(
                icon: const Icon(Icons.send_rounded),
                iconSize: 30,
                color: Colors.black,
                onPressed: _sendText,
              ),

              // MIC – نگه‌داشتن برای ضبط + رها کردن برای ارسال
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecordingAndSend(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
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
