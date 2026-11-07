/// Sedi copy catalog, app side (R-043): the ONE place for the app's own notification wording
/// (tray action labels, tray progress labels, smart-notification inbox labels) in fa / ar / en.
///
/// The text of a notification itself comes from the backend (its own catalog, `backend/app/sedi_copy.py`).
/// Rules (checked by `test/sedi_copy_quality_test.dart`): all three languages, the same `{placeholders}`,
/// Persian with half-spaces and the brand «صدی», Arabic in Arabic letters, Sedi's friendly voice.
class SediCopy {
  SediCopy._();

  static const List<String> languages = ['fa', 'ar', 'en'];

  /// `fa-IR` / `FA` -> `fa`; anything unsupported -> `en`.
  static String normalizeLanguage(String? language) {
    final code = (language ?? '').trim().toLowerCase().replaceAll('_', '-').split('-').first;
    return languages.contains(code) ? code : 'en';
  }

  /// The text for [key] in [language] (falls back to English, then to the key itself so a typo is visible).
  static String t(String key, String? language) {
    final entry = entries[key];
    if (entry == null) return key;
    return entry[normalizeLanguage(language)] ?? entry['en'] ?? key;
  }

  static const Map<String, Map<String, String>> entries = {
    'inbox.title': {
      'fa': 'اعلان‌های هوشمند',
      'ar': 'الإشعارات الذكية',
      'en': 'Smart Notifications',
    },
    'inbox.filterAll': {
      'fa': 'همه',
      'ar': 'الكل',
      'en': 'All',
    },
    'inbox.filterUnread': {
      'fa': 'خوانده‌نشده',
      'ar': 'غير مقروء',
      'en': 'Unread',
    },
    'inbox.filterDelete': {
      'fa': 'حذف',
      'ar': 'حذف',
      'en': 'Delete',
    },
    'inbox.cancelSelection': {
      'fa': 'لغو',
      'ar': 'إلغاء',
      'en': 'Cancel',
    },
    'inbox.deleteSelected': {
      'fa': 'حذف انتخاب‌شده',
      'ar': 'حذف المحدد',
      'en': 'Delete selected',
    },
    'inbox.deleteConfirmTitle': {
      'fa': 'حذف موارد انتخاب‌شده؟',
      'ar': 'حذف المحدد؟',
      'en': 'Delete selected?',
    },
    'inbox.deleteConfirmBody': {
      'fa': 'از صندوق اعلان‌ها حذف می‌شوند. این کار از اینجا قابل بازگشت نیست.',
      'ar': 'ستُزال من صندوق الوارد. لا يمكن التراجع عن ذلك هنا.',
      'en': 'They will be removed from your inbox. This cannot be undone here.',
    },
    'inbox.deleteConfirmAction': {
      'fa': 'حذف',
      'ar': 'حذف',
      'en': 'Delete',
    },
    'inbox.likeAction': {
      'fa': 'پسندیدن',
      'ar': 'إعجاب',
      'en': 'Like',
    },
    'inbox.dislikeAction': {
      'fa': 'فعلاً نه',
      'ar': 'ليس الآن',
      'en': 'Not now',
    },
    'inbox.dislikeReasonTitle': {
      'fa': 'چرا فعلاً نه؟',
      'ar': 'لماذا ليس الآن؟',
      'en': 'Why not now?',
    },
    'inbox.dislikeReasonHint': {
      'fa': 'با یک ضربه جواب بده؛ دفعه‌ی بعد زمان و شکل پیام را مناسب‌تر می‌کنم.',
      'ar': 'اختر إجابة واحدة، وسأجعل الرسالة التالية أنسب وقتًا وشكلًا.',
      'en': 'Tap one answer; I will make the next message fit you better.',
    },
    'inbox.dislikeReasonMore': {
      'fa': 'دلیل دیگر',
      'ar': 'سبب آخر',
      'en': 'Another reason',
    },
    'inbox.dislikeReasonLabel.busy_now': {
      'fa': 'الان درگیرم',
      'ar': 'مشغول الآن',
      'en': "I'm busy now",
    },
    'inbox.dislikeReasonLabel.rest_time': {
      'fa': 'وقت استراحتم است',
      'ar': 'وقت راحتي',
      'en': 'Rest time',
    },
    'inbox.dislikeReasonLabel.not_in_mood': {
      'fa': 'حوصله ندارم',
      'ar': 'لا رغبة لدي',
      'en': 'Not in the mood',
    },
    'inbox.dislikeReasonLabel.too_frequent': {
      'fa': 'زیاد پیام می‌دهی',
      'ar': 'كثيرة جداً',
      'en': 'Too many',
    },
    'inbox.dislikeReasonLabel.irrelevant': {
      'fa': 'به من ربطی ندارد',
      'ar': 'لا تخصني',
      'en': 'Not relevant to me',
    },
    'inbox.dislikeReasonLabel.unclear': {
      'fa': 'نامفهوم بود',
      'ar': 'غير واضحة',
      'en': 'Unclear',
    },
    'inbox.dislikeReasonLabel.not_helpful': {
      'fa': 'به کارم نیامد',
      'ar': 'لم تفدني',
      'en': 'Not helpful',
    },
    'inbox.dislikeReasonLabel.default': {
      'fa': 'وقتش مناسب نبود',
      'ar': 'توقيت غير مناسب',
      'en': 'Wrong time',
    },
    'inbox.planNotDoneTitle': {
      'fa': 'اشکالی ندارد. چه شد؟',
      'ar': 'لا بأس. ماذا حدث؟',
      'en': 'That is fine. What happened?',
    },
    'inbox.planNotDoneHint': {
      'fa': 'با دانستن دلیل، برنامه را برایت راحت‌تر می‌کنم.',
      'ar': 'بمعرفة السبب أجعل برنامجك أسهل عليك.',
      'en': 'Knowing why helps me make your plan easier for you.',
    },
    'inbox.planReasonLabel.no_time': {
      'fa': 'وقت نداشتم',
      'ar': 'ضيق الوقت',
      'en': 'No time',
    },
    'inbox.planReasonLabel.dont_like': {
      'fa': 'خوشم نیامد',
      'ar': 'لم يعجبني',
      'en': "Didn't like it",
    },
    'inbox.planReasonLabel.default': {
      'fa': 'حالم بد بود',
      'ar': 'لست بخير',
      'en': 'Felt unwell',
    },
    'inbox.talkToSedi': {
      'fa': 'صحبت با صدی',
      'ar': 'التحدث مع صدي',
      'en': 'Talk to Sedi',
    },
    'inbox.groupToday': {
      'fa': 'امروز',
      'ar': 'اليوم',
      'en': 'Today',
    },
    'inbox.groupYesterday': {
      'fa': 'دیروز',
      'ar': 'أمس',
      'en': 'Yesterday',
    },
    'inbox.actionFailed': {
      'fa': 'انجام عملیات ممکن نشد. دوباره تلاش کنید.',
      'ar': 'تعذر إكمال الإجراء. حاول مرة أخرى.',
      'en': 'Could not complete action. Try again.',
    },
    'inbox.hideFailed': {
      'fa': 'حذف اعلان‌ها ممکن نشد. دوباره تلاش کنید.',
      'ar': 'تعذر حذف الإشعارات. حاول مرة أخرى.',
      'en': 'Could not delete notifications. Try again.',
    },
    'inbox.loading': {
      'fa': 'در حال بارگذاری اعلان‌ها...',
      'ar': 'جاري تحميل الإشعارات...',
      'en': 'Loading notifications...',
    },
    'inbox.emptyTitle': {
      'fa': 'هیچ اعلان ارسال‌شده‌ای در این بازه تاریخچه نیست',
      'ar': 'لا إشعارات مُرسلة في نافذة السجل هذه',
      'en': 'No sent notifications in this history window',
    },
    'inbox.emptySubtitle': {
      'fa': 'اعلان‌های زمان‌بندی‌شده یا ناموفق اینجا نشان داده نمی‌شوند.',
      'ar': 'الإشعارات المجدولة أو الفاشلة لا تُعرض هنا.',
      'en': 'Scheduled or failed notifications are not shown here.',
    },
    'inbox.fallbackTitle': {
      'fa': 'اعلان',
      'ar': 'إشعار',
      'en': 'Notification',
    },
    'inbox.noDetails': {
      'fa': 'بدون جزئیات',
      'ar': 'بدون تفاصيل',
      'en': 'No details',
    },
    'inbox.markAsRead': {
      'fa': 'علامت به‌عنوان خوانده‌شده',
      'ar': 'تعيين كمقروء',
      'en': 'Mark as read',
    },
    'inbox.now': {
      'fa': 'الان',
      'ar': 'الآن',
      'en': 'Now',
    },
    'inbox.categoryLabel.daily_status': {
      'fa': 'وضعیت روزانه',
      'ar': 'الحالة اليومية',
      'en': 'Daily status',
    },
    'inbox.categoryLabel.reminder': {
      'fa': 'یادآوری',
      'ar': 'تذكير',
      'en': 'Reminder',
    },
    'inbox.categoryLabel.event_reminder': {
      'fa': 'یادآوری رویداد',
      'ar': 'تذكير بالحدث',
      'en': 'Event reminder',
    },
    'inbox.categoryLabel.medication_reminder': {
      'fa': 'یادآوری دارو',
      'ar': 'تذكير بالدواء',
      'en': 'Medication reminder',
    },
    'inbox.categoryLabel.care_follow_up': {
      'fa': 'پیگیری مراقبت',
      'ar': 'متابعة الرعاية',
      'en': 'Care follow-up',
    },
    'inbox.categoryLabel.care_recommendation': {
      'fa': 'پیشنهاد مراقبت',
      'ar': 'توصية رعاية',
      'en': 'Care recommendation',
    },
    'inbox.categoryLabel.engagement_checkin': {
      'fa': 'حال\u200cپرسی',
      'ar': 'اطمئنان',
      'en': 'Check-in',
    },
    'inbox.categoryLabel.health_status': {
      'fa': 'وضعیت سلامت',
      'ar': 'الحالة الصحية',
      'en': 'Health status',
    },
    'inbox.categoryLabel.device_alert': {
      'fa': 'هشدار دستگاه',
      'ar': 'تنبيه الجهاز',
      'en': 'Device alert',
    },
    'inbox.categoryLabel.critical_alert': {
      'fa': 'هشدار مهم',
      'ar': 'تنبيه مهم',
      'en': 'Important alert',
    },
    'inbox.categoryLabel.chat_continuation': {
      'fa': 'گفتگو',
      'ar': 'محادثة',
      'en': 'Conversation',
    },
    'inbox.categoryLabel.system': {
      'fa': 'سیستم',
      'ar': 'النظام',
      'en': 'System',
    },
    'tray.action.like': {
      'fa': 'پسندیدن',
      'ar': 'إعجاب',
      'en': 'Like',
    },
    'tray.action.dislike': {
      'fa': 'فعلاً نه',
      'ar': 'ليس الآن',
      'en': 'Not now',
    },
    // R-073: the tray answers are short (three equal buttons; Samsung cuts anything over about 12 characters).
    'tray.reason.busy_now': {
      'fa': 'الان درگیرم',
      'ar': 'مشغول الآن',
      'en': 'Busy now',
    },
    'tray.reason.rest_time': {
      'fa': 'در استراحتم',
      'ar': 'وقت راحتي',
      'en': 'Resting',
    },
    'tray.reason.not_in_mood': {
      'fa': 'حوصله ندارم',
      'ar': 'لا رغبة لدي',
      'en': 'Not in mood',
    },
    'tray.action.open_chat': {
      'fa': 'صحبت با صدی',
      'ar': 'التحدث مع صدي',
      'en': 'Talk to Sedi',
    },
    'tray.action.done': {
      'fa': 'آره، انجام شد',
      'ar': 'تم',
      'en': 'Done',
    },
    'tray.action.plan_not_done': {
      'fa': 'نشد',
      'ar': 'لم يتم',
      'en': 'Not done',
    },
    'tray.action.later': {
      'fa': 'بعداً',
      'ar': 'لاحقًا',
      'en': 'Later',
    },
    'tray.processing.like': {
      'fa': 'در حال ثبت پسندیدنت…',
      'ar': 'جارٍ تسجيل إعجابك…',
      'en': 'Sending Like…',
    },
    'tray.processing.dislike': {
      'fa': 'در حال ثبت نظرت…',
      'ar': 'جارٍ تسجيل رأيك…',
      'en': 'Sending…',
    },
    'tray.processing.open_chat': {
      'fa': 'در حال آماده\u200cسازی…',
      'ar': 'جارٍ التحضير…',
      'en': 'Preparing…',
    },
    'tray.processing.default': {
      'fa': 'در حال پردازش…',
      'ar': 'جارٍ المعالجة…',
      'en': 'Processing…',
    },
  };
}
