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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _isExpanded ? 120 : 56, // بزرگ شدن هنگام تایپ
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite, // داخل سفید
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isExpanded 
                ? widget.brandColor 
                : AppTheme.metalGray, // کادر خاکستری متال
            width: _isExpanded ? 2 : 1.5,
          ),
          boxShadow: _isExpanded
              ? [
                  BoxShadow(
                    color: widget.brandColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ============================================
            // آیکن بلندگو (مثل ChatGPT)
            // ============================================
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.mic_rounded,
                    color: widget.brandColor,
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ============================================
            // فیلد تایپ پیام
            // ============================================
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "با صدی صحبت کن", // placeholder
                  hintStyle: TextStyle(
                    color: AppTheme.metalGray,
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  color: AppTheme.textBlack,
                  fontSize: 16,
                ),
                minLines: 1,
                maxLines: _isExpanded ? 4 : 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),

            const SizedBox(width: 8),

            // ============================================
            // آیکن سند (مثل ChatGPT) - فقط وقتی متن وجود دارد
            // ============================================
            if (_controller.text.trim().isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.brandColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.brandColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              )
            else
              // آیکن سند غیرفعال
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: null,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.attach_file_rounded,
                      color: AppTheme.metalGray,
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
