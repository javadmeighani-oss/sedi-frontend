import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final List<String> quickReplies;

  final Function(String reply) onQuickReply;
  final VoidCallback onLike;
  final Function(String reason) onDislike;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.quickReplies,
    required this.onQuickReply,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان نوتیف
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          // متن پیام
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // پاسخ‌های سریع
          if (quickReplies.isNotEmpty)
            Wrap(
              spacing: 8,
              children: quickReplies.map((reply) {
                return GestureDetector(
                  onTap: () => onQuickReply(reply),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      reply,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // لایک و دیسلایک
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: const Icon(Icons.thumb_up_alt_rounded,
                    color: Colors.green, size: 22),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  // دیسلایک → پرسش دلیل
                  final reason = await _askReason(context);
                  if (reason != null && reason.isNotEmpty) {
                    onDislike(reason);
                  }
                },
                child: const Icon(Icons.thumb_down_alt_rounded,
                    color: Colors.red, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  //  پنجرهٔ گرفتن دلیل نارضایتی از کاربر
  // ---------------------------------------------------------
  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Why disliked?"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter reason...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
