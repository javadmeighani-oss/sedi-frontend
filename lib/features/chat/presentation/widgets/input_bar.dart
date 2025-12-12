import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InputBar extends StatefulWidget {
  final Function(String) onSendText; // ارسال متن
  final VoidCallback onVoiceTap; // لمس میکروفن
  final Color brandColor; // رنگ سبز پسته‌ای

  const InputBar({
    super.key,
    required this.onSendText,
    required this.onVoiceTap,
    required this.brandColor,
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
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _isExpanded ? 120 : 56,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isExpanded 
                ? widget.brandColor 
                : AppTheme.metalGray.withOpacity(0.5),
            width: _isExpanded ? 2.0 : 1.5,
          ),
          boxShadow: _isExpanded
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
          children: [
            // ============================================
            // متن "Talk to Sedi" (سمت چپ)
            // ============================================
            if (!_isExpanded && !hasText)
              Text(
                "Talk to Sedi",
                style: TextStyle(
                  color: AppTheme.textBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              )
            else
              // ============================================
              // فیلد تایپ پیام (وقتی در حال تایپ است)
              // ============================================
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Talk to Sedi",
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
                  maxLines: _isExpanded ? 4 : 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),

            const Spacer(),

            // ============================================
            // آیکن ارسال (راست) - فقط وقتی متن وجود دارد
            // ============================================
            if (hasText)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.send_rounded,
                      color: AppTheme.textBlack,
                      size: 20,
                    ),
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // ============================================
            // آیکن اسپیکر/میکروفن (راست)
            // ============================================
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppTheme.textBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

