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

  String get title =>
      _t(en: 'Notifications', fa: 'اعلان‌ها', ar: 'الإشعارات');

  String get filterAll => _t(en: 'All', fa: 'همه', ar: 'الكل');

  String get filterUnread =>
      _t(en: 'Unread', fa: 'خوانده‌نشده', ar: 'غير مقروء');

  String get loading => _t(
        en: 'Loading notifications...',
        fa: 'در حال بارگذاری اعلان‌ها...',
        ar: 'جاري تحميل الإشعارات...',
      );

  String get emptyTitle => _t(
        en: 'No sent notifications in this history window',
        fa: 'هیچ اعلان ارسال‌شده‌ای در این بازه تاریخچه نیست',
        ar: 'لا إشعارات مُرسلة في نافذة السجل هذه',
      );

  String get emptySubtitle => _t(
        en: 'Scheduled or failed notifications are not shown here.',
        fa: 'اعلان‌های زمان‌بندی‌شده یا ناموفق اینجا نشان داده نمی‌شوند.',
        ar: 'الإشعارات المجدولة أو الفاشلة لا تُعرض هنا.',
      );

  String get fallbackTitle =>
      _t(en: 'Notification', fa: 'اعلان', ar: 'إشعار');

  String get noDetails =>
      _t(en: 'No details', fa: 'بدون جزئیات', ar: 'بدون تفاصيل');

  String get markAsRead =>
      _t(en: 'Mark as read', fa: 'علامت به‌عنوان خوانده‌شده', ar: 'تعيين كمقروء');

  String get now => _t(en: 'Now', fa: 'الان', ar: 'الآن');

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
        return _t(en: 'Daily status', fa: 'وضعیت روزانه', ar: 'الحالة اليومية');
      case 'reminder':
        return _t(en: 'Reminder', fa: 'یادآوری', ar: 'تذكير');
      case 'event_reminder':
        return _t(en: 'Event reminder', fa: 'یادآوری رویداد', ar: 'تذكير بالحدث');
      case 'medication_reminder':
        return _t(
            en: 'Medication reminder',
            fa: 'یادآوری دارو',
            ar: 'تذكير بالدواء');
      case 'care_follow_up':
        return _t(en: 'Care follow-up', fa: 'پیگیری مراقبت', ar: 'متابعة الرعاية');
      case 'care_recommendation':
        return _t(
            en: 'Care recommendation',
            fa: 'پیشنهاد مراقبت',
            ar: 'توصية رعاية');
      case 'engagement_checkin':
        return _t(
            en: 'Check-in', fa: 'پیگیری ارتباط', ar: 'تسجيل حضور');
      case 'health_status':
        return _t(en: 'Health status', fa: 'وضعیت سلامت', ar: 'الحالة الصحية');
      case 'device_alert':
        return _t(en: 'Device alert', fa: 'هشدار دستگاه', ar: 'تنبيه الجهاز');
      case 'critical_alert':
        return _t(
            en: 'Important alert', fa: 'هشدار مهم', ar: 'تنبيه مهم');
      case 'chat_continuation':
        return _t(
            en: 'Conversation', fa: 'گفتگو', ar: 'محادثة');
      case 'system':
        return _t(en: 'System', fa: 'سیستم', ar: 'النظام');
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
