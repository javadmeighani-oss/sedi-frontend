import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSedi;
  final bool showOnlyLast;
  final bool isLast;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSedi,
    required this.showOnlyLast,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // اگر فقط آخرین پیام باید نمایش داده شود
    if (showOnlyLast && !isLast) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 17,
          height: 1.4,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
