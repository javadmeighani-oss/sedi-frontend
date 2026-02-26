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

/// Feedback reason (V1 optional): too_frequent | irrelevant | unclear
const List<String> kFeedbackReasonValues = ['too_frequent', 'irrelevant', 'unclear'];

/// Feedback Payload (Contract Section 5)
class NotificationFeedback {
  final String notificationId;
  final String? actionId;
  final FeedbackReaction reaction;
  final String? feedbackText;
  /// Optional V1 reason: too_frequent | irrelevant | unclear (included in toBackendJson when set).
  final String? reason;
  final String timestamp; // ISO 8601 datetime string

  NotificationFeedback({
    required this.notificationId,
    this.actionId,
    required this.reaction,
    this.feedbackText,
    this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      if (actionId != null) 'action_id': actionId,
      'reaction': reaction.toContractString(),
      if (feedbackText != null) 'feedback_text': feedbackText,
      if (reason != null) 'reason': reason,
      'timestamp': timestamp,
    };
  }

  /// Backend contract: reaction, timestamp, reason? (optional). Legacy: feedback, action still sent for compatibility.
  Map<String, dynamic> toBackendJson() {
    final reasonValue = (reason != null && reason!.isNotEmpty) ? reason : feedbackText;
    final feedback = _reactionToBackendFeedback(reaction);
    return {
      'reaction': reaction.toContractString(),
      'timestamp': timestamp,
      if (reasonValue != null && reasonValue.isNotEmpty) 'reason': reasonValue,
      if (actionId != null && actionId!.isNotEmpty) 'action_id': actionId,
      'feedback': feedback,
      if (actionId != null && actionId!.isNotEmpty) 'action': actionId,
    };
  }

  static String _reactionToBackendFeedback(FeedbackReaction r) {
    switch (r) {
      case FeedbackReaction.like:
        return 'positive';
      case FeedbackReaction.dislike:
        return 'negative';
      case FeedbackReaction.seen:
      case FeedbackReaction.interact:
      case FeedbackReaction.dismiss:
        return 'neutral';
    }
  }

  factory NotificationFeedback.create({
    required String notificationId,
    String? actionId,
    required FeedbackReaction reaction,
    String? feedbackText,
    String? reason,
  }) {
    return NotificationFeedback(
      notificationId: notificationId,
      actionId: actionId,
      reaction: reaction,
      feedbackText: feedbackText,
      reason: reason,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

