import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================
/// InputBar - چت باکس صدی
/// ============================================
/// 
/// CONTRACT:
/// - فقط یک کادر (بدون box داخلی)
/// - مستطیل با گوشه‌های کمی گرد
/// - سمت چپ: hint text
/// - سمت راست: آیکن ارسال (اول) + آیکن اسپیکر (دوم)
/// - هنگام فوکوس ارتفاع افزایش یابد
/// - رنگ‌ها: فقط مشکی و خاکستری
/// ============================================
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
  bool _isExpanded = false;
  bool _sendPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isExpanded = _focusNode.hasFocus && !widget.isRecording;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant InputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      setState(() {
        _isExpanded = _focusNode.hasFocus && !widget.isRecording;
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
    final hasText = _textController.text.trim().isNotEmpty;
    final height = _isExpanded ? 120.0 : 56.0;

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isExpanded 
                ? AppTheme.primaryBlack 
                : AppTheme.metalGrey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ================= سمت چپ: TextField یا Recording Timer =================
            Expanded(
              child: widget.isRecording
                  ? Row(
                      children: [
                        // آیکن ضبط (قرمز)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // تایمر ضبط (حتماً نمایش داده شود)
                        Text(
                          widget.recordingTime,
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !widget.isRecording,
                      maxLines: _isExpanded ? 4 : 1,
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: AppTheme.metalGrey.withOpacity(0.6),
                          fontSize: 15,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 15,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                    ),
            ),

            const SizedBox(width: 12),

            // ================= سمت راست: آیکن‌ها =================
            // ترتیب: آیکن ارسال (اول) + آیکن اسپیکر (دوم)
            
            // آیکن ارسال (دایره کم‌رنگ، هنگام لمس پررنگ)
            GestureDetector(
              onTap: hasText ? _sendText : () {},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 40,
                height: 40,
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

            const SizedBox(width: 12),

            // آیکن اسپیکر (هنگام ضبط خاکستری، هنگام ارسال مشکی)
            GestureDetector(
              onLongPressStart: widget.isRecording 
                  ? null 
                  : (_) => widget.onStartRecording(),
              onLongPressEnd: widget.isRecording 
                  ? (_) => widget.onStopRecordingAndSend() 
                  : null,
              child: Icon(
                Icons.mic_rounded,
                size: 28,
                color: widget.isRecording
                    ? AppTheme.metalGrey
                    : AppTheme.primaryBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
