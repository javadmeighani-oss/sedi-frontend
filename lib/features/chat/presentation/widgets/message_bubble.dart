import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatefulWidget {
  final String message; // متن پیام
  final bool isSedi; // آیا فرستنده صدی است؟

  const MessageBubble({
    super.key,
    required this.message,
    this.isSedi = true,
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
      duration: const Duration(milliseconds: 400),
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
    final isUser = !widget.isSedi;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                    ? AppTheme.metalLight // پیام کاربر: خاکستری روشن متال
                    : AppTheme.backgroundWhite, // پیام صدی: سفید
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                border: Border.all(
                  color: AppTheme.metalGray.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textBlack, // فونت مشکی
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                textDirection: _getTextDirection(widget.message),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// تشخیص جهت متن (راست به چپ برای فارسی/عربی)
  TextDirection _getTextDirection(String text) {
    // تشخیص کاراکترهای فارسی یا عربی
    final persianArabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    if (persianArabicRegex.hasMatch(text)) {
      return TextDirection.rtl;
    }
    return TextDirection.ltr;
  }
}
