/// ============================================
/// NotificationFeedback - Contract-Compliant Model
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Exact mirror of contract feedback structure
/// - Contract Section 5
/// ============================================

/// Reaction Enum (Contract Section 5)
enum FeedbackReaction {
  seen,
  interact,
  dismiss,
  like,
  dislike;

  static FeedbackReaction fromString(String value) {
    switch (value.toLowerCase()) {
      case 'seen':
        return FeedbackReaction.seen;
      case 'interact':
        return FeedbackReaction.interact;
      case 'dismiss':
        return FeedbackReaction.dismiss;
      case 'like':
        return FeedbackReaction.like;
      case 'dislike':
        return FeedbackReaction.dislike;
      default:
        return FeedbackReaction.seen; // Default fallback
    }
  }

  String toContractString() {
    switch (this) {
      case FeedbackReaction.seen:
        return 'seen';
      case FeedbackReaction.interact:
        return 'interact';
      case FeedbackReaction.dismiss:
        return 'dismiss';
      case FeedbackReaction.like:
        return 'like';
      case FeedbackReaction.dislike:
        return 'dislike';
    }
  }
}

/// Feedback Payload (Contract Section 5)
class NotificationFeedback {
  final String notificationId;
  final String? actionId;
  final FeedbackReaction reaction;
  final String? feedbackText;
  final String timestamp; // ISO 8601 datetime string

  NotificationFeedback({
    required this.notificationId,
    this.actionId,
    required this.reaction,
    this.feedbackText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      if (actionId != null) 'action_id': actionId,
      'reaction': reaction.toContractString(),
      if (feedbackText != null) 'feedback_text': feedbackText,
      'timestamp': timestamp,
    };
  }

  factory NotificationFeedback.create({
    required String notificationId,
    String? actionId,
    required FeedbackReaction reaction,
    String? feedbackText,
  }) {
    return NotificationFeedback(
      notificationId: notificationId,
      actionId: actionId,
      reaction: reaction,
      feedbackText: feedbackText,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

