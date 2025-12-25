/// ============================================
/// NotificationCard - Contract-Compliant UI Component
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Render notification based on contract fields only
/// - No business logic
/// - No intelligence
/// ============================================

import 'package:flutter/material.dart';
import '../../../data/models/notification.dart';
import '../../../data/models/notification_feedback.dart';

class NotificationCard extends StatelessWidget {
  final Notification notification;
  final Function(NotificationFeedback) onFeedback;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visual style based on priority (structure only, no logic)
    final priorityColor = _getPriorityColor(notification.priority);
    final priorityBorderColor = _getPriorityBorderColor(notification.priority);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityBorderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (Contract: optional title)
          if (notification.title != null) ...[
            Text(
              notification.title!,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Message (Contract: required message)
          Text(
            notification.message,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // Actions (Contract Section 4)
          if (notification.actions != null && notification.actions!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notification.actions!.map((action) {
                return GestureDetector(
                  onTap: () => _handleAction(context, action),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: priorityBorderColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      action.label,
                      style: TextStyle(
                        color: priorityBorderColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // Feedback Actions (Contract Section 5: like/dislike)
          Row(
            children: [
              GestureDetector(
                onTap: () => _handleLike(context),
                child: const Icon(
                  Icons.thumb_up_alt_rounded,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _handleDislike(context),
                child: const Icon(
                  Icons.thumb_down_alt_rounded,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Get color based on priority (structure only)
  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.blue;
      case NotificationPriority.normal:
        return Colors.orange;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  Color _getPriorityBorderColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.blue;
      case NotificationPriority.normal:
        return Colors.orange;
      case NotificationPriority.high:
        return Colors.deepOrange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  // Handle action click (Contract Section 4)
  void _handleAction(BuildContext context, NotificationAction action) {
    final feedback = NotificationFeedback.create(
      notificationId: notification.id,
      actionId: action.id,
      reaction: FeedbackReaction.interact,
    );
    onFeedback(feedback);
  }

  // Handle like (Contract Section 5)
  void _handleLike(BuildContext context) {
    final feedback = NotificationFeedback.create(
      notificationId: notification.id,
      reaction: FeedbackReaction.like,
    );
    onFeedback(feedback);
  }

  // Handle dislike (Contract Section 5)
  void _handleDislike(BuildContext context) async {
    final reason = await _askReason(context);
    final feedback = NotificationFeedback.create(
      notificationId: notification.id,
      reaction: FeedbackReaction.dislike,
      feedbackText: reason,
    );
    onFeedback(feedback);
  }

  // Get feedback text for dislike (Contract Section 5)
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
