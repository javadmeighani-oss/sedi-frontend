/// NotificationCard - Apple-like minimal UI.
/// Like/Dislike with selected state; dislike opens reason picker (V1: too_frequent, irrelevant, unclear).
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/notification.dart' as sedi;
import '../../../../data/models/notification_feedback.dart';
import '../../utils/notification_ui_mapping.dart';

enum SelectedReaction { none, like, dislike }

/// Dislike reason labels (FA): خیلی زیاد بود, مرتبط نبود, واضح نبود
const Map<String, String> _dislikeReasonLabels = {
  'too_frequent': 'خیلی زیاد بود',
  'irrelevant': 'مرتبط نبود',
  'unclear': 'واضح نبود',
};

class NotificationCard extends StatelessWidget {
  final sedi.Notification notification;
  final SelectedReaction selectedReaction;
  /// When set, overrides notification.isRead for showing the unread dot (e.g. after markRead).
  final bool? displayAsUnread;
  final VoidCallback? onTap;
  final void Function(NotificationFeedback) onLike;
  final void Function(NotificationFeedback) onDislike;

  const NotificationCard({
    super.key,
    required this.notification,
    this.selectedReaction = SelectedReaction.none,
    this.displayAsUnread,
    this.onTap,
    required this.onLike,
    required this.onDislike,
  });

  String get _displayTitle {
    if (notification.title != null && notification.title!.isNotEmpty) {
      return notification.title!;
    }
    return defaultTitleForNotificationType(notification.type);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundWhite,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.borderInactive.withOpacity(0.6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayAsUnread ?? !notification.isRead)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.pistachioGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _timeLabel(notification.createdAt),
                            const Spacer(),
                            _likeButton(context),
                            const SizedBox(width: 12),
                            _dislikeButton(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeLabel(String createdAt) {
    String label = createdAt;
    try {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inMinutes < 60) label = '${diff.inMinutes}m ago';
        else if (diff.inHours < 24) label = '${diff.inHours}h ago';
        else if (diff.inDays < 7) label = '${diff.inDays}d ago';
        else label = '${dt.month}/${dt.day}';
      }
    } catch (_) {}
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: AppTheme.textSecondary.withOpacity(0.8),
      ),
    );
  }

  Widget _likeButton(BuildContext context) {
    final isSelected = selectedReaction == SelectedReaction.like;
    return GestureDetector(
      onTap: () {
        final feedback = NotificationFeedback.create(
          notificationId: notification.id,
          actionId: actionTapLike,
          reaction: FeedbackReaction.like,
        );
        onLike(feedback);
      },
      child: Icon(
        Icons.thumb_up_alt_outlined,
        size: 20,
        color: isSelected ? AppTheme.pistachioGreen : AppTheme.iconInactive,
      ),
    );
  }

  Widget _dislikeButton(BuildContext context) {
    final isSelected = selectedReaction == SelectedReaction.dislike;
    return GestureDetector(
      onTap: () => _openDislikeReasonPicker(context),
      child: Icon(
        Icons.thumb_down_alt_outlined,
        size: 20,
        color: isSelected ? AppTheme.metalGrey : AppTheme.iconInactive,
      ),
    );
  }

  Future<void> _openDislikeReasonPicker(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'مفید نبود',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...kFeedbackReasonValues.map((value) {
                final label = _dislikeReasonLabels[value] ?? value;
                return ListTile(
                  title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
                  onTap: () => Navigator.of(ctx).pop(value),
                );
              }),
              ListTile(
                title: Text(
                  'بدون دلیل',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        ),
      ),
    );
    final feedback = NotificationFeedback.create(
      notificationId: notification.id,
      actionId: actionTapDislike,
      reaction: FeedbackReaction.dislike,
      reason: reason,
    );
    onDislike(feedback);
  }
}
