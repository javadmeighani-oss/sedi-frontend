import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final String message; // متن پیام
  final bool isSedi; // آیا فرستنده صدی است؟
  final Duration fadeDuration; // مدت Fade

  const MessageBubble({
    super.key,
    required this.message,
    this.isSedi = true,
    this.fadeDuration = const Duration(milliseconds: 400),
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: Offset(widget.isSedi ? -0.2 : 0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = Theme.of(context).colorScheme.primary;
    final isUser = !widget.isSedi;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? brandColor.withOpacity(0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? Border.all(
                        color: brandColor.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.black87 : Colors.black87,
                  height: 1.4,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
