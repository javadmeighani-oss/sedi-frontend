import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InputBar extends StatefulWidget {
  final Function(String) onSendText; // ارسال متن
  final VoidCallback onVoiceStart; // شروع ضبط صدا
  final VoidCallback onVoiceStop; // توقف ضبط صدا
  final Color brandColor; // رنگ سبز پسته‌ای
  final bool isRecording; // آیا در حال ضبط است؟
  final String recordingTime; // زمان ضبط

  const InputBar({
    super.key,
    required this.onSendText,
    required this.onVoiceStart,
    required this.onVoiceStop,
    required this.brandColor,
    this.isRecording = false,
    this.recordingTime = '00:00',
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
    
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    // چت باکس فقط هنگام تایپ بزرگ می‌شود، نه هنگام ضبط صدا
    final shouldExpand = _isExpanded && !widget.isRecording;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: shouldExpand ? 120 : 56,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(16), // مستطیل با گوشه‌های گرد
          border: Border.all(
            color: shouldExpand 
                ? widget.brandColor 
                : AppTheme.metalGray.withOpacity(0.5),
            width: shouldExpand ? 2.0 : 1.5,
          ),
          boxShadow: shouldExpand
              ? [
                  BoxShadow(
                    color: widget.brandColor.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ============================================
            // محتوای سمت چپ
            // ============================================
            Expanded(
              child: widget.isRecording
                  ? // حالت ضبط صدا - آیکن ضبط و تایمر
                  Row(
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
                        // تایمر
                        Text(
                          widget.recordingTime,
                          style: const TextStyle(
                            color: AppTheme.textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : // TextField برای تایپ
                      TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: !widget.isRecording,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Talk to Sedi...", // انگلیسی
                            hintStyle: TextStyle(
                              color: AppTheme.metalGray.withOpacity(0.6),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            color: AppTheme.textBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          minLines: 1,
                          maxLines: shouldExpand ? 4 : 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          onChanged: (text) {
                            if (text.isNotEmpty && !_isExpanded) {
                              _focusNode.requestFocus();
                            }
                          },
                        ),
            ),

            // ============================================
            // آیکن‌های سمت راست - داخل چت باکس
            // ترتیب: ابتدا ارسال (40px)، سپس اسپیکر (40px)
            // ============================================
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // آیکن ارسال متن (اول - سمت راست) - 40px
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasText ? _send : () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.send_rounded,
                        color: hasText 
                            ? AppTheme.textBlack 
                            : AppTheme.metalGray.withOpacity(0.4),
                        size: 40, // دو برابر (20 * 2 = 40)
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // آیکن اسپیکر (دوم - بعد از ارسال) - 40px
                // استفاده از GestureDetector برای onLongPress
                GestureDetector(
                  onLongPressStart: widget.isRecording 
                      ? null 
                      : (_) => widget.onVoiceStart(),
                  onLongPressEnd: widget.isRecording 
                      ? (_) => widget.onVoiceStop() 
                      : null,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.isRecording 
                          ? widget.onVoiceStop 
                          : () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          widget.isRecording 
                              ? Icons.mic_rounded 
                              : Icons.mic_rounded,
                          color: widget.isRecording 
                              ? Colors.red 
                              : AppTheme.textBlack,
                          size: 40, // دو برابر (20 * 2 = 40)
                        ),
                      ),
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
