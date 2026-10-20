import '../../../../core/locale/sedi_locale_controller.dart';

/// Lifestyle hub localization (en/fa/ar). Presentation only.
class LifestyleL10n {
  final String lang;
  LifestyleL10n([String? languageCode])
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

  String get title => _t(en: 'Lifestyle', fa: 'سبک زندگی', ar: 'نمط الحياة');
  String get health => _t(en: 'Health', fa: 'سلامت', ar: 'الصحة');
  String get myHistory => _t(en: 'My History', fa: 'تاریخچه من', ar: 'سجلي');
  String get mySchedule =>
      _t(en: 'My Schedule', fa: 'برنامه من', ar: 'جدولي');
  String get nutritionPlan =>
      _t(en: 'Nutrition Plan', fa: 'برنامه تغذیه', ar: 'خطة التغذية');
  String get exercisePlan =>
      _t(en: 'Exercise Plan', fa: 'برنامه ورزش', ar: 'خطة التمرين');

  String get healthSubtitle => _t(
        en: 'Health trends and recent measurements',
        fa: 'روندها و اندازه‌گیری‌های اخیر سلامت',
        ar: 'اتجاهات الصحة والقياسات الأخيرة',
      );
  String get historySubtitle => _t(
        en: 'Summaries and previous conversations',
        fa: 'خلاصه‌ها و گفتگوهای گذشته',
        ar: 'الملخصات والمحادثات السابقة',
      );
  String get scheduleSubtitle => _t(
        en: 'Events, plans and reminders',
        fa: 'رویدادها، برنامه‌ها و یادآورها',
        ar: 'الأحداث والخطط والتذكيرات',
      );
  String get nutritionSubtitle => _t(
        en: 'Your weekly nutrition plan',
        fa: 'برنامه هفتگی تغذیه شما',
        ar: 'خطتك الأسبوعية للتغذية',
      );
  String get exerciseSubtitle => _t(
        en: 'Your weekly exercise plan',
        fa: 'برنامه هفتگی ورزش شما',
        ar: 'خطتك الأسبوعية للتمرين',
      );

  List<String> get sectionTitles =>
      [health, myHistory, mySchedule, nutritionPlan, exercisePlan];

  List<String> get sectionSubtitles => [
        healthSubtitle,
        historySubtitle,
        scheduleSubtitle,
        nutritionSubtitle,
        exerciseSubtitle,
      ];

  String get hrStable =>
      _t(en: 'Stable pattern', fa: 'الگوی پایدار', ar: 'نمط مستقر');
  String get hrUnstable =>
      _t(en: 'Unstable pattern', fa: 'الگوی ناپایدار', ar: 'نمط غير مستقر');
  String get hrChanged =>
      _t(en: 'Change detected', fa: 'تغییر مشاهده شد', ar: 'تم رصد تغيير');
  String get hrInsufficient =>
      _t(en: 'Not enough data', fa: 'داده کافی نیست', ar: 'بيانات غير كافية');
  String get latestHr =>
      _t(en: 'Latest heart rate', fa: 'آخرین ضربان', ar: 'آخر معدل نبض');
  String get lastReceived =>
      _t(en: 'Last received', fa: 'آخرین دریافت', ar: 'آخر استلام');
  String get historyRange =>
      _t(en: 'History range', fa: 'بازه تاریخچه', ar: 'نطاق السجل');
  String get range7d => _t(en: '7 days', fa: '۷ روز', ar: '٧ أيام');
  String get range30d => _t(en: '30 days', fa: '۳۰ روز', ar: '٣٠ يوماً');
  String get range3m => _t(en: '3 months', fa: '۳ ماه', ar: '٣ أشهر');
  String get range1y =>
      _t(en: '1 year / available', fa: '۱ سال / موجود', ar: 'سنة / المتاح');
  String get availableFrom =>
      _t(en: 'Available from', fa: 'موجود از', ar: 'متاح من');
  String get availableTo => _t(en: 'Available to', fa: 'موجود تا', ar: 'متاح إلى');
  String get noHrData =>
      _t(en: 'No heart-rate data yet.', fa: 'هنوز داده ضربان نیست.', ar: 'لا بيانات نبض بعد.');

  String get recentConversations => _t(
        en: 'Recent conversations',
        fa: 'گفتگوهای اخیر',
        ar: 'المحادثات الأخيرة',
      );
  String get sediSummaries =>
      _t(en: 'Sedi summaries', fa: 'خلاصه‌های صدی', ar: 'ملخصات سدي');
  String get historyExplain => _t(
        en:
            'This is a read-only archive of conversations from the last 30 days and Sedi summaries.',
        fa:
            'این بایگانی فقط‌خواندنی گفتگوهای ۳۰ روز گذشته و خلاصه‌های صدی است.',
        ar:
            'هذا أرشيف للقراءة فقط لمحادثات الثلاثين يوماً الماضية وملخصات سدي.',
      );
  String get conversationsLast30Days => _t(
        en: 'Conversations from the last 30 days',
        fa: 'گفتگوهای ۳۰ روز گذشته',
        ar: 'محادثات الثلاثين يوماً الماضية',
      );
  String turnCount(int n) => _t(
        en: n == 1 ? '1 turn' : '$n turns',
        fa: n == 1 ? '۱ گفتگو' : '$n گفتگو',
        ar: n == 1 ? 'محادثة واحدة' : '$n محادثات',
      );
  String get noConversations => _t(
        en: 'No conversations in this period.',
        fa: 'گفتگویی در این بازه نیست.',
        ar: 'لا محادثات في هذه الفترة.',
      );
  String get archiveTemporarilyUnavailable => _t(
        en: 'Archive temporarily unavailable.',
        fa: 'بایگانی فعلاً در دسترس نیست.',
        ar: 'الأرشيف غير متاح مؤقتاً.',
      );
  String get daily => _t(en: 'Daily', fa: 'روزانه', ar: 'يومي');
  String get weekly => _t(en: 'Weekly', fa: 'هفتگی', ar: 'أسبوعي');
  String get monthly => _t(en: 'Monthly', fa: 'ماهانه', ar: 'شهري');
  String get yearly => _t(en: 'Yearly', fa: 'سالانه', ar: 'سنوي');
  String get noSummary =>
      _t(en: 'No summary yet.', fa: 'هنوز خلاصه‌ای نیست.', ar: 'لا ملخص بعد.');
  String get openChat =>
      _t(en: 'Talk to Sedi', fa: 'صحبت با صدی', ar: 'تحدث إلى سدي');

  String get today => _t(en: 'Today', fa: 'امروز', ar: 'اليوم');
  String get tomorrow => _t(en: 'Tomorrow', fa: 'فردا', ar: 'غداً');
  String get thisWeek => _t(en: 'This week', fa: 'این هفته', ar: 'هذا الأسبوع');
  String get later => _t(en: 'Later', fa: 'بعداً', ar: 'لاحقاً');
  String get governedActions => _t(
        en: 'Governed actions',
        fa: 'اقدامات هدایت‌شده',
        ar: 'إجراءات محكومة',
      );
  String get reminder => _t(en: 'Reminder', fa: 'یادآور', ar: 'تذكير');
  String get reminderOff => _t(en: 'Off', fa: 'خاموش', ar: 'إيقاف');
  String get reminderAtTime =>
      _t(en: 'At event time', fa: 'در زمان رویداد', ar: 'وقت الحدث');
  String get reminder15 =>
      _t(en: '15 min before', fa: '۱۵ دقیقه قبل', ar: 'قبل ١٥ دقيقة');
  String get reminder30 =>
      _t(en: '30 min before', fa: '۳۰ دقیقه قبل', ar: 'قبل ٣٠ دقيقة');
  String get reminder1h =>
      _t(en: '1 hour before', fa: '۱ ساعت قبل', ar: 'قبل ساعة');
  String get reminder1d =>
      _t(en: '1 day before', fa: '۱ روز قبل', ar: 'قبل يوم');
  String get noEvents =>
      _t(en: 'No scheduled items.', fa: 'رویدادی نیست.', ar: 'لا عناصر مجدولة.');

  String get noNutrition => _t(
        en: 'No nutrition plan yet.',
        fa: 'هنوز برنامه تغذیه نیست.',
        ar: 'لا خطة تغذية بعد.',
      );
  String get noExercise => _t(
        en: 'No exercise plan yet.',
        fa: 'هنوز برنامه ورزش نیست.',
        ar: 'لا خطة تمرين بعد.',
      );
  String get talkToCreate => _t(
        en: 'Talk to Sedi to create your plan.',
        fa: 'برای ساخت برنامه با صدی صحبت کنید.',
        ar: 'تحدث إلى سدي لإنشاء خطتك.',
      );
  String get breakfast => _t(en: 'Breakfast', fa: 'صبحانه', ar: 'فطور');
  String get lunch => _t(en: 'Lunch', fa: 'ناهار', ar: 'غداء');
  String get dinner => _t(en: 'Dinner', fa: 'شام', ar: 'عشاء');
  String get snack => _t(en: 'Snack', fa: 'میان‌وعده', ar: 'وجبة خفيفة');

  String get nutritionActive => _t(
        en: 'Your nutrition plan',
        fa: 'برنامه تغذیه شما',
        ar: 'خطة التغذية الخاصة بك',
      );
  String get exerciseActive => _t(
        en: 'Your exercise plan',
        fa: 'برنامه ورزش شما',
        ar: 'خطة التمرين الخاصة بك',
      );
  String get reviewDueTitle => _t(
        en: 'Plan review due',
        fa: 'زمان بازبینی برنامه',
        ar: 'حان وقت مراجعة الخطة',
      );
  String get reviewDueBody => _t(
        en: 'Your current cycle has ended. Review with Sedi when ready.',
        fa: 'چرخه فعلی به پایان رسیده است. وقتی آماده بودید با صدی بازبینی کنید.',
        ar: 'انتهت دورتك الحالية. راجع مع سدي عندما تكون جاهزاً.',
      );
  String get planUnavailable => _t(
        en: 'Plan unavailable',
        fa: 'برنامه در دسترس نیست',
        ar: 'الخطة غير متاحة',
      );
  String get planUnavailableBody => _t(
        en: 'Could not load your weekly plan right now.',
        fa: 'فعلاً نمی‌توان برنامه هفتگی را بارگذاری کرد.',
        ar: 'تعذر تحميل خطتك الأسبوعية الآن.',
      );
  String get noActionsThisDay => _t(
        en: 'No items for this day.',
        fa: 'موردی برای این روز نیست.',
        ar: 'لا عناصر لهذا اليوم.',
      );
  /// Contextual assistant starter (not composer draft; not auto-submitted).
  String get nutritionChatStarter => _t(
        en:
            'If you like, we can review your nutrition plan together and improve it for your goals. Where would you like to start?',
        fa:
            'اگر بخواهی، می‌توانیم برنامه تغذیه‌ات را با هم مرور کنیم و متناسب با هدفت بهترش کنیم. دوست داری از کجا شروع کنیم؟',
        ar:
            'إذا رغبت، يمكننا مراجعة خطة تغذيتك معًا وتحسينها بما يناسب هدفك. من أين تحب أن نبدأ؟',
      );
  String get exerciseChatStarter => _t(
        en:
            'If you like, we can review your exercise plan together and adjust it to your situation and goals. Where would you like to start?',
        fa:
            'اگر بخواهی، می‌توانیم برنامه ورزشی‌ات را با هم مرور کنیم و متناسب با شرایط و هدفت تنظیمش کنیم. دوست داری از کجا شروع کنیم؟',
        ar:
            'إذا رغبت، يمكننا مراجعة خطة تمرينك معًا وتعديلها بما يناسب وضعك وهدفك. من أين تحب أن نبدأ؟',
      );

  String cycleRangeLabel(String start, String end) {
    if (end.isEmpty) {
      return _t(
        en: 'Cycle from $start',
        fa: 'چرخه از $start',
        ar: 'الدورة من $start',
      );
    }
    return _t(
      en: 'Cycle $start – $end',
      fa: 'چرخه $start – $end',
      ar: 'الدورة $start – $end',
    );
  }

  /// ISO weekday: 1=Monday … 7=Sunday (from backend local_date).
  String weekdayShort(int isoWeekday) {
    switch (isoWeekday) {
      case 1:
        return _t(en: 'Mon', fa: 'دوشنبه', ar: 'الإثنين');
      case 2:
        return _t(en: 'Tue', fa: 'سه‌شنبه', ar: 'الثلاثاء');
      case 3:
        return _t(en: 'Wed', fa: 'چهارشنبه', ar: 'الأربعاء');
      case 4:
        return _t(en: 'Thu', fa: 'پنجشنبه', ar: 'الخميس');
      case 5:
        return _t(en: 'Fri', fa: 'جمعه', ar: 'الجمعة');
      case 6:
        return _t(en: 'Sat', fa: 'شنبه', ar: 'السبت');
      case 7:
        return _t(en: 'Sun', fa: 'یکشنبه', ar: 'الأحد');
      default:
        return '';
    }
  }

  String mealSlotLabel(String slot) {
    switch (slot.toLowerCase()) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snack':
        return snack;
      default:
        return slot;
    }
  }

  String durationMinutes(int minutes) => _t(
        en: '$minutes min',
        fa: '$minutes دقیقه',
        ar: '$minutes دقيقة',
      );

  /// Labels for DEVICE_REPORTED STABLE|UNSTABLE only (presentation).
  String deviceReportedHrStatusLabel(String code) {
    switch (code.toUpperCase()) {
      case 'STABLE':
        return hrStable;
      case 'UNSTABLE':
        return hrUnstable;
      default:
        return hrInsufficient;
    }
  }

  String hrStatusLabel(String code) {
    switch (code) {
      case 'STABLE':
        return hrStable;
      case 'UNSTABLE':
        return hrUnstable;
      case 'UNSTABLE_OR_CHANGED':
        return hrChanged;
      default:
        return hrInsufficient;
    }
  }

  String get markDone => _t(en: 'Done', fa: 'انجام شد', ar: 'تم');

  String get markSkipped => _t(en: 'Could not', fa: 'نشد', ar: 'لم أستطع');

  String get whySkippedTitle =>
      _t(en: 'Why could not you do it?', fa: 'چرا انجام نشد؟', ar: 'لماذا لم تتمكن؟');

  String get whySkippedHint => _t(
        en: 'This helps Sedi make tomorrow fit you better.',
        fa: 'با این، صدی برنامه‌ی فردا رو مناسب‌تر می‌کنه.',
        ar: 'هذا يساعد صدی على جعل الغد أنسب لك.',
      );

  String skipReasonLabel(String code) {
    switch (code) {
      case 'no_time':
        return _t(en: 'No time', fa: 'وقت نداشتم', ar: 'لا وقت');
      case 'too_hard':
        return _t(en: 'Too hard', fa: 'سخت بود', ar: 'كان صعباً');
      case 'not_feeling_well':
        return _t(en: 'Not feeling well', fa: 'حالم خوب نبود', ar: 'لم أشعر بخير');
      case 'dont_like':
        return _t(en: 'Did not like it', fa: 'دوست نداشتم', ar: 'لم يعجبني');
      case 'forgot':
        return _t(en: 'Forgot', fa: 'یادم رفت', ar: 'نسيت');
      default:
        return _t(en: 'Other', fa: 'دلیل دیگر', ar: 'سبب آخر');
    }
  }

  String adherenceTitle(int done, int total) => _t(
        en: 'This week: $done of $total items done',
        fa: 'این هفته: $done از $total مورد انجام شد',
        ar: 'هذا الأسبوع: تم $done من $total',
      );

  String activityTypeLabel(String type) {
    switch (type) {
      case 'walking':
        return _t(en: 'Walking', fa: 'پیاده‌روی', ar: 'مشي');
      case 'stretching':
        return _t(en: 'Stretching', fa: 'کشش', ar: 'تمدد');
      case 'chair':
        return _t(en: 'Chair exercise', fa: 'تمرین روی صندلی', ar: 'تمرين الكرسي');
      case 'breathing':
        return _t(en: 'Breathing', fa: 'تنفس', ar: 'تنفس');
      case 'balance':
        return _t(en: 'Balance', fa: 'تعادل', ar: 'توازن');
      case 'strength':
        return _t(en: 'Light strength', fa: 'قدرتی سبک', ar: 'قوة خفيفة');
      case 'rest':
        return _t(en: 'Rest day', fa: 'روز استراحت', ar: 'يوم راحة');
      default:
        return type;
    }
  }

  String scheduleStatusLabel(String code) {
    switch (code.toLowerCase()) {
      case 'done':
      case 'completed':
        return _t(en: 'Done', fa: 'انجام شد', ar: 'تم');
      case 'postponed':
        return _t(en: 'Postponed', fa: 'به تعویق افتاد', ar: 'مؤجل');
      case 'cancelled':
        return _t(en: 'Cancelled', fa: 'لغو شد', ar: 'ملغى');
      default:
        return _t(en: 'Upcoming', fa: 'پیش‌رو', ar: 'قادم');
    }
  }
}
