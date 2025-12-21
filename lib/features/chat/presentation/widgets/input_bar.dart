import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
  bool _sendPressed = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _expanded = _focusNode.hasFocus || widget.isRecording;
    });
  }

  @override
  void didUpdateWidget(covariant InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // keep expanded while recording
    if (oldWidget.isRecording != widget.isRecording) {
      setState(() {
        _expanded = widget.isRecording || _focusNode.hasFocus;
      });
    }
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

    setState(() => _sendPressed = true);

    widget.onSendText(text);
    _textController.clear();
    _focusNode.unfocus();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _sendPressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: _expanded ? 150 : 64,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: _expanded ? AppTheme.borderActive : AppTheme.borderInactive,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            // ================= TEXT INPUT =================
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: _expanded ? 4 : 1,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration.collapsed(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // ================= ACTIONS =================
            Row(
              children: [
                const Spacer(),

                // -------- Mic --------
                GestureDetector(
                  onTap: widget.isRecording
                      ? widget.onStopRecordingAndSend
                      : widget.onStartRecording,
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        size: 28,
                        color: widget.isRecording
                            ? AppTheme.iconActive
                            : AppTheme.iconInactive,
                      ),
                      if (widget.isRecording)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            widget.recordingTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // -------- Send --------
                GestureDetector(
                  onTap: _sendText,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sendPressed
                          ? AppTheme.primaryBlack
                          : AppTheme.metalGrey.withOpacity(0.25),
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 24,
                      color: _sendPressed
                          ? AppTheme.backgroundWhite
                          : AppTheme.primaryBlack,
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
