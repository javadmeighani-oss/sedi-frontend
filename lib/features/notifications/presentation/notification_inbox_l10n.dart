import '../../../core/copy/sedi_copy.dart';
import '../../../core/locale/sedi_locale_controller.dart';

/// A4 Smart Notifications Inbox localization (en/fa/ar). Presentation only.
/// Does not translate backend-supplied notification title/body content.
class NotificationInboxL10n {
  final String lang;
  NotificationInboxL10n([String? languageCode])
      : lang = languageCode ?? SediLocaleController.instance.languageCode;

  bool get isRtl => lang == 'fa' || lang == 'ar';

  String _t({required String en, required String fa, required String ar}) {
    switch (lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  String get title => SediCopy.t('inbox.title', lang);

  String get filterAll => SediCopy.t('inbox.filterAll', lang);

  String get filterUnread =>
      SediCopy.t('inbox.filterUnread', lang);

  /// Top-control Delete enters selection mode (standalone Select removed).
  String get filterDelete => SediCopy.t('inbox.filterDelete', lang);

  String get cancelSelection =>
      SediCopy.t('inbox.cancelSelection', lang);

  String get deleteSelected =>
      SediCopy.t('inbox.deleteSelected', lang);

  String get deleteConfirmTitle => SediCopy.t('inbox.deleteConfirmTitle', lang);

  String get deleteConfirmBody => SediCopy.t('inbox.deleteConfirmBody', lang);

  String get deleteConfirmAction =>
      SediCopy.t('inbox.deleteConfirmAction', lang);

  String get likeAction => SediCopy.t('inbox.likeAction', lang);

  String get dislikeAction =>
      SediCopy.t('inbox.dislikeAction', lang);

  String get dislikeReasonTitle =>
      SediCopy.t('inbox.dislikeReasonTitle', lang);

  String get dislikeReasonHint => SediCopy.t('inbox.dislikeReasonHint', lang);

  String dislikeReasonLabel(String code) {
    switch (code) {
      case 'busy_now':
        return SediCopy.t('inbox.dislikeReasonLabel.busy_now', lang);
      case 'rest_time':
        return SediCopy.t('inbox.dislikeReasonLabel.rest_time', lang);
      case 'not_in_mood':
        return SediCopy.t('inbox.dislikeReasonLabel.not_in_mood', lang);
      case 'too_frequent':
        return SediCopy.t('inbox.dislikeReasonLabel.too_frequent', lang);
      case 'irrelevant':
        return SediCopy.t('inbox.dislikeReasonLabel.irrelevant', lang);
      case 'unclear':
        return SediCopy.t('inbox.dislikeReasonLabel.unclear', lang);
      case 'not_helpful':
        return SediCopy.t('inbox.dislikeReasonLabel.not_helpful', lang);
      default:
        return SediCopy.t('inbox.dislikeReasonLabel.default', lang);
    }
  }

  String get planNotDoneTitle =>
      SediCopy.t('inbox.planNotDoneTitle', lang);

  String get planNotDoneHint => SediCopy.t('inbox.planNotDoneHint', lang);

  String planReasonLabel(String code) {
    switch (code) {
      case 'no_time':
        return SediCopy.t('inbox.planReasonLabel.no_time', lang);
      case 'dont_like':
        return SediCopy.t('inbox.planReasonLabel.dont_like', lang);
      default:
        return SediCopy.t('inbox.planReasonLabel.default', lang);
    }
  }

  String get talkToSedi => SediCopy.t('inbox.talkToSedi', lang);

  String get groupToday => SediCopy.t('inbox.groupToday', lang);

  String get groupYesterday =>
      SediCopy.t('inbox.groupYesterday', lang);

  String get actionFailed => SediCopy.t('inbox.actionFailed', lang);

  String get hideFailed => SediCopy.t('inbox.hideFailed', lang);

  String get loading => SediCopy.t('inbox.loading', lang);

  String get emptyTitle => SediCopy.t('inbox.emptyTitle', lang);

  String get emptySubtitle => SediCopy.t('inbox.emptySubtitle', lang);

  String get fallbackTitle =>
      SediCopy.t('inbox.fallbackTitle', lang);

  String get noDetails =>
      SediCopy.t('inbox.noDetails', lang);

  String get markAsRead =>
      SediCopy.t('inbox.markAsRead', lang);

  String get now => SediCopy.t('inbox.now', lang);

  String minutesAgo(int n) => _t(
        en: '${n}m',
        fa: '$nد',
        ar: '$nد',
      );

  String hoursAgo(int n) => _t(
        en: '${n}h',
        fa: '$nس',
        ar: '$nس',
      );

  String daysAgo(int n) => _t(
        en: '${n}d',
        fa: '$nر',
        ar: '$nي',
      );

  String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return now;
    if (diff.inMinutes < 60) return minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return hoursAgo(diff.inHours);
    if (diff.inDays < 7) return daysAgo(diff.inDays);
    return '${dt.month}/${dt.day}';
  }

  /// Presentation-only category label. Never returns raw enum casing.
  String categoryLabel(String? rawCategoryOrChannel) {
    final key = _canonicalCategoryKey(rawCategoryOrChannel);
    switch (key) {
      case 'daily_status':
        return SediCopy.t('inbox.categoryLabel.daily_status', lang);
      case 'reminder':
        return SediCopy.t('inbox.categoryLabel.reminder', lang);
      case 'event_reminder':
        return SediCopy.t('inbox.categoryLabel.event_reminder', lang);
      case 'medication_reminder':
        return SediCopy.t('inbox.categoryLabel.medication_reminder', lang);
      case 'care_follow_up':
        return SediCopy.t('inbox.categoryLabel.care_follow_up', lang);
      case 'care_recommendation':
        return SediCopy.t('inbox.categoryLabel.care_recommendation', lang);
      case 'engagement_checkin':
        return SediCopy.t('inbox.categoryLabel.engagement_checkin', lang);
      case 'health_status':
        return SediCopy.t('inbox.categoryLabel.health_status', lang);
      case 'device_alert':
        return SediCopy.t('inbox.categoryLabel.device_alert', lang);
      case 'critical_alert':
        return SediCopy.t('inbox.categoryLabel.critical_alert', lang);
      case 'chat_continuation':
        return SediCopy.t('inbox.categoryLabel.chat_continuation', lang);
      case 'system':
        return SediCopy.t('inbox.categoryLabel.system', lang);
      default:
        return fallbackTitle;
    }
  }

  static String _canonicalCategoryKey(String? raw) {
    final s = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    if (s.isEmpty) return '';
    const known = {
      'daily_status',
      'reminder',
      'event_reminder',
      'medication_reminder',
      'care_follow_up',
      'care_recommendation',
      'engagement_checkin',
      'health_status',
      'device_alert',
      'critical_alert',
      'chat_continuation',
      'system',
    };
    if (known.contains(s)) return s;
    // Channel/type fallbacks for presentation only.
    if (s.contains('morning') || s == 'daily' || s.contains('digest')) {
      return 'daily_status';
    }
    if (s.contains('medication')) return 'medication_reminder';
    if (s.contains('event')) return 'event_reminder';
    if (s.contains('reminder')) return 'reminder';
    if (s.contains('engagement') || s.contains('companion') || s.contains('ping')) {
      return 'engagement_checkin';
    }
    if (s.contains('health') || s.contains('care')) return 'health_status';
    if (s.contains('device')) return 'device_alert';
    if (s.contains('critical')) return 'critical_alert';
    if (s.contains('chat')) return 'chat_continuation';
    if (s.contains('system')) return 'system';
    return '';
  }
}
