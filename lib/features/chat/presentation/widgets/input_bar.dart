import 'package:flutter/material.dart';

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
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        isTyping = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText(text);
    _controller.clear();
    setState(() => isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      // ارتفاع چت‌باکس → وقتی تایپ می‌کند بزرگ‌تر می‌شود
      height: isTyping ? 80 : 60,

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: widget.brandColor.withOpacity(isTyping ? 1.0 : 0.6),
            width: isTyping ? 2.5 : 2,
          ),
          boxShadow: isTyping
              ? [
                  BoxShadow(
                    color: widget.brandColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // -------------------------
            //  دکمه میکروفن
            // -------------------------
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.mic_rounded,
                    color: widget.brandColor,
                    size: 26,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // -------------------------
            // فیلد تایپ پیام
            // -------------------------
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "پیامتو بنویس...",
                ),
                minLines: 1,
                maxLines: isTyping ? 4 : 1,
              ),
            ),

            const SizedBox(width: 10),

            // -------------------------
            //  دکمه ارسال شبیه GPT (فلش ساده)
            // -------------------------
            AnimatedScale(
              scale: isTyping ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: isTyping ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isTyping ? _send : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.brandColor,
                        shape: BoxShape.circle,
                        boxShadow: isTyping
                            ? [
                                BoxShadow(
                                  color: widget.brandColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
