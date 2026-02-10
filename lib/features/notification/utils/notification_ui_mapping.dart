/// Mapping: Notification type -> default title (for UI when title is absent).
/// Used by Inbox and tests. English default; FA/AR can use l10n later.
import '../../../../data/models/notification.dart' as sedi;

/// Returns a short display title for [type] when backend does not provide title.
String defaultTitleForNotificationType(sedi.NotificationType type) {
  switch (type) {
    case sedi.NotificationType.info:
      return 'Notification';
    case sedi.NotificationType.alert:
      return 'Alert';
    case sedi.NotificationType.reminder:
      return 'Reminder';
    case sedi.NotificationType.checkIn:
      return 'Check-in';
    case sedi.NotificationType.achievement:
      return 'Achievement';
    case sedi.NotificationType.morningBrief:
      return 'Morning Brief';
    case sedi.NotificationType.connectionPing:
      return 'Connection';
    case sedi.NotificationType.healthAlert:
      return 'Health Alert';
    case sedi.NotificationType.deviceDisconnected:
      return 'Device Disconnected';
  }
}

/// Reaction sent to backend for Like: positive + action tap_like.
const String actionTapLike = 'tap_like';

/// Reaction sent to backend for Dislike: negative + action tap_dislike.
const String actionTapDislike = 'tap_dislike';
