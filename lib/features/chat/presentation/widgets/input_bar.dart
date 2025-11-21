import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final bool isTyping;
  final TextEditingController controller;
  final Function(String) onTextChanged;
  final VoidCallback onSendMessage;

  const InputBar({
    Key? key,
    required this.isTyping,
    required this.controller,
    required this.onTextChanged,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: isTyping ? 60 : 48, // بزرگ‌شدن هنگام تایپ
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          /// آیکون میکروفون (فعلاً بدون عملکرد)
          GestureDetector(
            onTap: () {
              // بعداً فعال می‌شود
            },
            child: Icon(
              Icons.mic_none,
              size: 26,
              color: Colors.green.shade400,
            ),
          ),

          const SizedBox(width: 10),

          /// Input
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onTextChanged,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "پیام را بنویس...",
              ),
              onSubmitted: (_) => onSendMessage(),
            ),
          ),

          const SizedBox(width: 10),

          /// آیکون ارسال
          GestureDetector(
            onTap: onSendMessage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade400,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 22,
              ),
            ),
          )
        ],
      ),
    );
  }
}
