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
  String get mySchedule => _t(en: 'My Schedule', fa: 'برنامه من', ar: 'جدولي');
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
  String get availableTo =>
      _t(en: 'Available to', fa: 'موجود تا', ar: 'متاح إلى');
  String get noHrData => _t(
      en: 'No heart-rate data yet.',
      fa: 'هنوز داده ضربان نیست.',
      ar: 'لا بيانات نبض بعد.');

  String get recentConversations => _t(
        en: 'Recent conversations',
        fa: 'گفتگوهای اخیر',
        ar: 'المحادثات الأخيرة',
      );
  String get sediSummaries =>
      _t(en: 'Sedi summaries', fa: 'خلاصه‌های صدی', ar: 'ملخصات صدی');
  String get historyExplain => _t(
        en: 'This is a read-only archive of conversations from the last 30 days and Sedi summaries.',
        fa: 'این بایگانی فقط‌خواندنی گفتگوهای ۳۰ روز گذشته و خلاصه‌های صدی است.',
        ar: 'هذا أرشيف للقراءة فقط لمحادثات الثلاثين يوماً الماضية وملخصات صدی.',
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
      _t(en: 'Talk to Sedi', fa: 'صحبت با صدی', ar: 'تحدث إلى صدی');

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
  String get noEvents => _t(
      en: 'No scheduled items.', fa: 'رویدادی نیست.', ar: 'لا عناصر مجدولة.');

  // ---- R-026: reminders from chat + notification settings on My Schedule
  String get scheduleHeroTitle =>
      _t(en: 'Just tell Sedi', fa: 'فقط به صدی بگو', ar: 'قل لصدی فقط');
  String get scheduleHeroBody => _t(
        en: 'In the chat say “remind me tomorrow at 10 am to …”. Sedi saves it here and sends you a notification on time.',
        fa: 'توی چت بگو «فردا ساعت ۱۰ صبح یادم بنداز ...». صدی همین‌جا ثبتش می‌کنه و سر وقتش برات نوتیف می‌فرسته.',
        ar: 'في المحادثة قل «ذكّرني غداً الساعة 10 صباحاً بـ ...». سيسجّلها صدی هنا ويرسل لك إشعاراً في وقته.',
      );
  String get addReminder =>
      _t(en: 'Add a reminder', fa: 'افزودن یادآور', ar: 'إضافة تذكير');
  String get reminderWhat => _t(
        en: 'What should I remind you of?',
        fa: 'چی رو یادت بندازم؟',
        ar: 'بماذا أذكّرك؟',
      );
  String get reminderDate => _t(en: 'Date', fa: 'تاریخ', ar: 'التاريخ');
  String get reminderTime => _t(en: 'Time', fa: 'ساعت', ar: 'الوقت');
  String get reminderWhen =>
      _t(en: 'Notify me', fa: 'کِی خبرم کنی', ar: 'متى تنبّهني');
  String get save => _t(en: 'Save', fa: 'ثبت', ar: 'حفظ');
  String get cancel => _t(en: 'Cancel', fa: 'انصراف', ar: 'إلغاء');
  String get deleteItem => _t(en: 'Delete', fa: 'حذف', ar: 'حذف');
  String get fromChat => _t(en: 'From chat', fa: 'از چت', ar: 'من المحادثة');

  // ---- R-031: My Schedule redesign (categories, done, add by type, notification wording)
  String get healthAlertAlwaysOn => _t(
        en: 'Stays on for emergencies, always.',
        fa: 'برای موارد اضطراری همیشه روشن می‌مونه.',
        ar: 'يبقى مفعّلاً للطوارئ دائماً.',
      );
  String get notifLearningLine => _t(
        en: 'If you dislike a message, I change my timing and wording myself; I do not stop.',
        fa: 'اگه یه پیام رو نپسندی، خودم زمان و جمله‌هام رو عوض می‌کنم؛ قطع نمی‌کنم.',
        ar: 'إذا لم تعجبك رسالة، أغيّر وقتها وصياغتها بنفسي؛ ولا أتوقف.',
      );
  String get nextUp => _t(en: 'Next', fa: 'بعدی', ar: 'التالي');
  String get nothingToday => _t(
        en: 'Nothing planned for today.',
        fa: 'امروز برنامه‌ای نداری.',
        ar: 'لا شيء مخطط لليوم.',
      );
  String get allDoneToday => _t(
        en: 'Everything for today is done.',
        fa: 'کارهای امروز همه انجام شد.',
        ar: 'تم كل شيء لليوم.',
      );
  String catAll(int n) =>
      _t(en: 'All · $n', fa: 'همه · ${_n(n)}', ar: 'الكل · ${_n(n)}');
  String get catMedication => _t(en: 'Medication', fa: 'دارو', ar: 'الدواء');
  String get catAppointment =>
      _t(en: 'Appointments', fa: 'نوبت و دکتر', ar: 'المواعيد');
  String get catMeeting =>
      _t(en: 'Meetings & work', fa: 'جلسه و کار', ar: 'اجتماعات وعمل');
  String get catOther => _t(en: 'Other', fa: 'دیگر', ar: 'أخرى');
  String get markDone => _t(en: 'Mark as done', fa: 'انجام شد', ar: 'تم');
  String get undoDone => _t(en: 'Undo', fa: 'برگردان', ar: 'تراجع');
  String get doneLabel => _t(en: 'Done', fa: 'انجام شد', ar: 'تم');
  String get rememberedBySedi => _t(
        en: "Saved in Sedi's memory",
        fa: 'در حافظه‌ی صدی ثبت شد',
        ar: 'حُفظ في ذاكرة صدی',
      );
  String get doneSaved => _t(en: 'Saved', fa: 'ثبت شد', ar: 'تم الحفظ');
  String get addToSchedule => _t(
        en: 'Add to my schedule',
        fa: 'افزودن به برنامه‌ام',
        ar: 'أضف إلى جدولي',
      );
  String get addWhatTitle =>
      _t(en: 'What shall we add?', fa: 'چی اضافه کنیم؟', ar: 'ماذا نضيف؟');
  String get typeMedication => _t(en: 'Medication', fa: 'دارو', ar: 'دواء');
  String get typeAppointment =>
      _t(en: 'Doctor visit', fa: 'نوبت دکتر', ar: 'موعد طبيب');
  String get typeMeeting => _t(en: 'Meeting', fa: 'جلسه', ar: 'اجتماع');
  String get typeFree => _t(en: 'Other', fa: 'آزاد', ar: 'حر');
  String get medName =>
      _t(en: 'Medication name', fa: 'اسم دارو', ar: 'اسم الدواء');
  String get medTimes =>
      _t(en: 'At what times?', fa: 'چه ساعت‌هایی؟', ar: 'في أي أوقات؟');
  String get addTime => _t(en: '+ time', fa: '+ ساعت', ar: '+ وقت');
  String get medSave =>
      _t(en: 'Save medication', fa: 'ثبت دارو', ar: 'حفظ الدواء');
  String get medNeedName => _t(
        en: 'Please write the medication name.',
        fa: 'اسم دارو رو بنویس.',
        ar: 'اكتب اسم الدواء.',
      );
  String get medNeedTime => _t(
        en: 'Add at least one time.',
        fa: 'حداقل یه ساعت اضافه کن.',
        ar: 'أضف وقتاً واحداً على الأقل.',
      );
  String get medHint => _t(
        en: 'I will tell you on time and ask "did you take it?". Your answer stays in my memory so I can look after you.',
        fa: 'سر وقت بهت خبر می‌دم و می‌پرسم «خوردی؟». جوابت توی حافظه‌ی من می‌مونه که بتونم حواسم بهت باشه.',
        ar: 'سأنبّهك في الوقت وأسأل «هل أخذته؟». يبقى جوابك في ذاكرتي لأعتني بك.',
      );
  String get notifRowTitle =>
      _t(en: 'Notifications', fa: 'اعلان‌ها', ar: 'الإشعارات');
  String get upcoming => _t(en: 'Coming up', fa: 'بعداً', ar: 'قادم');
  String get medsEmptyHint => _t(
        en: 'Tell Sedi in chat or add your medication here.',
        fa: 'توی چت به صدی بگو یا دارویت رو همین‌جا اضافه کن.',
        ar: 'قل لصدی في المحادثة أو أضف دواءك هنا.',
      );
  String hubToday(int total, int done) => total == 0
      ? nothingToday
      : _t(
          en: '$total for today · $done done',
          fa: '${_n(total)} کار داری · ${_n(done)} تا انجام شد',
          ar: '${_n(total)} مهام اليوم · أنجزت ${_n(done)}',
        );
  String hubNext(String title, String hhmm) => _t(
        en: 'Next: $title · $hhmm',
        fa: 'بعدی: $title · $hhmm',
        ar: 'التالي: $title · $hhmm',
      );
  String hubScheduleLine(int open) => open == 0
      ? _t(
          en: 'All clear for today',
          fa: 'امروز همه‌چیز انجام شده',
          ar: 'كل شيء منجز اليوم',
        )
      : _t(
          en: '$open left today',
          fa: '${_n(open)} کار مونده',
          ar: 'بقي ${_n(open)} اليوم',
        );

  /// Eastern digits for fa/ar.
  String _n(Object v) {
    final s = '$v';
    if (lang != 'fa' && lang != 'ar') return s;
    const latin = '0123456789';
    const eastern = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = latin.indexOf(ch);
      b.write(i < 0 ? ch : eastern[i]);
    }
    return b.toString();
  }

  String timeText(DateTime t) => _n(
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');

  /// "in 2 h" / «۲ ساعت دیگه» / "now".
  String relativeIn(Duration d) {
    final mins = d.inMinutes;
    if (mins <= 0) return _t(en: 'now', fa: 'الان', ar: 'الآن');
    if (mins < 60) {
      return _t(
        en: 'in $mins min',
        fa: '${_n(mins)} دقیقه دیگه',
        ar: 'بعد ${_n(mins)} دقيقة',
      );
    }
    final h = (mins / 60).round();
    return _t(en: 'in $h h', fa: '${_n(h)} ساعت دیگه', ar: 'بعد ${_n(h)} ساعة');
  }

  // ---- DEBT-044: repeating reminders asked for in chat
  /// «هر روز · 08:00» / «Every Monday · 08:00» for a stored rule (`FREQ=DAILY`, `FREQ=WEEKLY;BYDAY=MO`); null = one-off.
  String? repeatLabel(String? rule, String? startsAtIso) {
    if (rule == null || !rule.startsWith('FREQ=')) return null;
    final parsed =
        startsAtIso == null ? null : DateTime.tryParse(startsAtIso.trim());
    final time = parsed == null
        ? ''
        : ' · ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    if (rule.contains('FREQ=DAILY')) {
      return '${_t(en: 'Every day', fa: 'هر روز', ar: 'كل يوم')}$time';
    }
    if (rule.contains('FREQ=WEEKLY')) {
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final match = RegExp(r'BYDAY=([A-Z]{2})').firstMatch(rule);
      final i = match == null ? -1 : codes.indexOf(match.group(1)!);
      if (i < 0) {
        return '${_t(en: 'Every week', fa: 'هر هفته', ar: 'كل أسبوع')}$time';
      }
      final day = _t(
        en: const [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][i],
        fa: const [
          'دوشنبه',
          'سه‌شنبه',
          'چهارشنبه',
          'پنجشنبه',
          'جمعه',
          'شنبه',
          'یکشنبه',
        ][i],
        ar: const [
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
          'الأحد',
        ][i],
      );
      return '${_t(en: 'Every', fa: 'هر', ar: 'كل')} $day$time';
    }
    return null;
  }
  String get pickFutureTime => _t(
        en: 'Please choose a time in the future.',
        fa: 'یه زمان در آینده انتخاب کن.',
        ar: 'اختر وقتاً في المستقبل.',
      );
  String get reminderNeedsTitle => _t(
        en: 'Write what to remind you of.',
        fa: 'بنویس چی رو یادت بندازم.',
        ar: 'اكتب ما أذكّرك به.',
      );
  String get saveFailed => _t(
        en: 'Could not save. Try again.',
        fa: 'ذخیره نشد؛ دوباره امتحان کن.',
        ar: 'تعذّر الحفظ. حاول مجدداً.',
      );
  String get notifSettingsTitle => _t(
        en: 'When and what should Sedi tell you?',
        fa: 'صدی کِی و چی بهت خبر بده؟',
        ar: 'متى وبماذا يخبرك صدی؟',
      );
  String get notifSettingsSubtitle => _t(
        en: 'Turn off anything you do not like',
        fa: 'هر چیزی که دوست نداری، خودت خاموشش کن',
        ar: 'أوقف أي شيء لا يعجبك',
      );
  String get chCompanion => _t(
        en: 'Check-ins from Sedi',
        fa: 'احوال‌پرسی و همراهی',
        ar: 'اطمئنان ومرافقة',
      );
  String get chAppointment => _t(
        en: 'Appointments and meetings',
        fa: 'نوبت‌ها و جلسه‌ها',
        ar: 'المواعيد والاجتماعات',
      );
  String get chMedication =>
      _t(en: 'Medication', fa: 'دارو', ar: 'الدواء');
  String get chSystem =>
      _t(en: 'System reminders', fa: 'یادآورهای سیستم', ar: 'تذكيرات النظام');
  String get chHealthAlert =>
      _t(en: 'Health alerts', fa: 'هشدارهای سلامت', ar: 'تنبيهات الصحة');
  String get quietHours =>
      _t(en: 'Quiet hours', fa: 'ساعت آرامش', ar: 'ساعات الهدوء');
  String get quietHoursHint => _t(
        en: 'No messages in this window, except emergencies.',
        fa: 'در این بازه پیام نمی‌فرستم، مگر اورژانس.',
        ar: 'لا رسائل في هذه الفترة، إلا الطوارئ.',
      );
  String get quietFrom => _t(en: 'From', fa: 'از', ar: 'من');
  String get quietTo => _t(en: 'To', fa: 'تا', ar: 'إلى');
  String get engagementTitle => _t(
        en: 'How much should I write?',
        fa: 'چقدر برات بنویسم؟',
        ar: 'كم أكتب لك؟',
      );
  String get engagementLow => _t(en: 'Less', fa: 'کمتر', ar: 'أقل');
  String get engagementNormal => _t(en: 'Normal', fa: 'معمولی', ar: 'عادي');
  String get engagementHigh => _t(en: 'More', fa: 'بیشتر', ar: 'أكثر');
  String get appointmentOffWarning => _t(
        en: 'Appointment and meeting reminders are off, so these will not notify you.',
        fa: 'یادآور نوبت‌ها و جلسه‌ها خاموشه؛ برای این برنامه‌ها خبرت نمی‌کنم.',
        ar: 'تذكير المواعيد والاجتماعات متوقف، لذلك لن أنبّهك لهذه العناصر.',
      );

  /// Localized label for the stored event type; null for "other"/unknown (no chip).
  String? eventTypeLabel(String? type) {
    switch (type) {
      case 'doctor_visit':
        return _t(en: 'Doctor visit', fa: 'نوبت دکتر', ar: 'موعد طبيب');
      case 'lab_test':
        return _t(en: 'Lab test', fa: 'آزمایش', ar: 'تحليل');
      case 'exam':
        return _t(en: 'Exam', fa: 'امتحان', ar: 'اختبار');
      case 'work_meeting':
        return _t(en: 'Meeting', fa: 'جلسه', ar: 'اجتماع');
      case 'deadline':
        return _t(en: 'Deadline', fa: 'مهلت', ar: 'موعد نهائي');
      default:
        return null;
    }
  }

  String get settingsLoadFailed => _t(
        en: 'Settings are not available right now.',
        fa: 'الان تنظیمات در دسترس نیست.',
        ar: 'الإعدادات غير متاحة الآن.',
      );

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
        ar: 'تحدث إلى صدی لإنشاء خطتك.',
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
        ar: 'انتهت دورتك الحالية. راجع مع صدی عندما تكون جاهزاً.',
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
        en: 'If you like, we can review your nutrition plan together and improve it for your goals. Where would you like to start?',
        fa: 'اگر بخواهی، می‌توانیم برنامه تغذیه‌ات را با هم مرور کنیم و متناسب با هدفت بهترش کنیم. دوست داری از کجا شروع کنیم؟',
        ar: 'إذا رغبت، يمكننا مراجعة خطة تغذيتك معًا وتحسينها بما يناسب هدفك. من أين تحب أن نبدأ؟',
      );
  String get exerciseChatStarter => _t(
        en: 'If you like, we can review your exercise plan together and adjust it to your situation and goals. Where would you like to start?',
        fa: 'اگر بخواهی، می‌توانیم برنامه ورزشی‌ات را با هم مرور کنیم و متناسب با شرایط و هدفت تنظیمش کنیم. دوست داری از کجا شروع کنیم؟',
        ar: 'إذا رغبت، يمكننا مراجعة خطة تمرينك معًا وتعديلها بما يناسب وضعك وهدفك. من أين تحب أن نبدأ؟',
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

  String get whySkippedTitle => _t(
      en: 'Why could not you do it?',
      fa: 'چرا انجام نشد؟',
      ar: 'لماذا لم تتمكن؟');

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
        return _t(
            en: 'Not feeling well', fa: 'حالم خوب نبود', ar: 'لم أشعر بخير');
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
        return _t(
            en: 'Chair exercise', fa: 'تمرین روی صندلی', ar: 'تمرين الكرسي');
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
