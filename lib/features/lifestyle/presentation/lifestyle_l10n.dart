import '../../../../core/locale/calendar_date_math.dart';
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
        en: 'Search Sedi memory or pick a day. Conversations from the last 30 days can be read and corrected; older days show what Sedi remembers, not the chat text.',
        fa: 'در حافظه‌ی صدی جست‌وجو کن یا یک روز را انتخاب کن. گفتگوهای ۳۰ روز گذشته قابل خواندن و اصلاح است؛ روزهای قدیمی‌تر فقط آنچه صدی یادش مانده را نشان می‌دهد.',
        ar: 'ابحث في ذاكرة صدی أو اختر يوماً. يمكن قراءة وتصحيح محادثات الثلاثين يوماً الماضية؛ أما الأيام الأقدم فتعرض ما تتذكره صدی فقط.',
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
  String get scheduleEmptyTitle =>
      _t(en: 'Nothing on your schedule yet', fa: 'هنوز برنامه‌ای نداری', ar: 'لا يوجد شيء في جدولك بعد');
  String get scheduleEmptyHint => _t(
        en: 'Add your medication, a doctor appointment, a meeting or anything you want to remember; Sedi will remind you on time.',
        fa: 'دارو، نوبت دکتر، جلسه یا هر چیزی که می‌خوای یادت بمونه رو اضافه کن؛ صدی سر وقت بهت خبر می‌ده.',
        ar: 'أضف دواءك أو موعد الطبيب أو اجتماعاً أو أي شيء تريد تذكره؛ وستذكّرك صدی في وقته.',
      );
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
  String get typeFree => _t(en: 'Reminder', fa: 'یادآور', ar: 'تذكير');
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

  /// Digits in the language's own numerals (Eastern digits for fa/ar).
  String digits(Object v) => _n(v);

  // ---- pilot V1 (R-034): My Schedule speaks in short words ----
  String get addAction => _t(en: 'Add', fa: 'افزودن', ar: 'إضافة');
  String get titleField => _t(en: 'Title', fa: 'عنوان', ar: 'العنوان');
  String get repeatOnce => _t(en: 'Once', fa: 'یک‌بار', ar: 'مرة');
  String get repeatDaily => _t(en: 'Daily', fa: 'هر روز', ar: 'يوميًا');
  String get repeatDays => _t(en: 'Days', fa: 'روزها', ar: 'أيام');
  String get pickDays => _t(
        en: 'Pick at least one day.',
        fa: 'حداقل یک روز را انتخاب کن.',
        ar: 'اختر يومًا واحدًا على الأقل.',
      );

  /// One letter per ISO weekday (1 = Monday ... 7 = Sunday).
  String weekdayInitial(int isoWeekday) {
    final i = (isoWeekday - 1).clamp(0, 6).toInt();
    return _t(
      en: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
      fa: const ['د', 'س', 'چ', 'پ', 'ج', 'ش', 'ی'][i],
      ar: const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'][i],
    );
  }

  /// Weekday order of the picker: Saturday first in fa/ar, Monday first in en.
  List<int> get weekOrder =>
      lang == 'en' ? const [1, 2, 3, 4, 5, 6, 7] : const [6, 7, 1, 2, 3, 4, 5];

  /// Short "when to notify" chip label.
  String presetShort(int? minutes) {
    switch (minutes) {
      case 0:
        return _t(en: 'On time', fa: 'به‌موقع', ar: 'في الوقت');
      case 15:
        return _t(en: '15 m', fa: '${_n(15)} د', ar: '${_n(15)} د');
      case 30:
        return _t(en: '30 m', fa: '${_n(30)} د', ar: '${_n(30)} د');
      case 60:
        return _t(en: '1 h', fa: '${_n(1)} س', ar: '${_n(1)} س');
      case 1440:
        return _t(en: '1 day', fa: '${_n(1)} روز', ar: '${_n(1)} يوم');
      default:
        return reminderOff;
    }
  }

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
      final match = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
      final picked = match == null
          ? const <String>[]
          : match.group(1)!.split(',').where(codes.contains).toList();
      if (picked.length > 1) {
        // several weekdays at the same time: «شنبه، دوشنبه، چهارشنبه · ۲۱:۳۰»
        final names = [for (final c in picked) weekdayShort(codes.indexOf(c) + 1)];
        return '${names.join(_t(en: ', ', fa: '، ', ar: '، '))}$time';
      }
      final i = picked.isEmpty ? -1 : codes.indexOf(picked.first);
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
        en: 'Sedi notifications',
        fa: 'اعلان‌های صدی',
        ar: 'إشعارات صدی',
      );
  String get notifSettingsSubtitle => _t(
        en: 'Choose which ones you get',
        fa: 'انتخاب کن کدوم اعلان‌ها برات بیاد',
        ar: 'اختر أي الإشعارات تصلك',
      );
  String get chCompanion => _t(
        en: 'Sedi asking how you are',
        fa: 'احوال‌پرسی صدی',
        ar: 'سؤال صدی عن حالك',
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
        en: 'No notifications in this window, except emergencies.',
        fa: 'در این بازه اعلان نمی‌فرستم، مگر اورژانس.',
        ar: 'لا إشعارات في هذه الفترة، إلا الطوارئ.',
      );
  String get quietFrom => _t(en: 'From', fa: 'از', ar: 'من');
  String get quietTo => _t(en: 'To', fa: 'تا', ar: 'إلى');
  String get engagementTitle => _t(
        en: 'How many notifications a day?',
        fa: 'روزی چند اعلان بیاد؟',
        ar: 'كم إشعاراً في اليوم؟',
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

  // ---- H1: memory explorer (search, calendar, day view) ----
  String get searchMemoryHint => _t(
        en: 'Search Sedi memory',
        fa: 'جست‌وجو در حافظه‌ی صدی',
        ar: 'ابحث في ذاكرة صدی',
      );
  String get memoryDotLegend => _t(
        en: 'Days Sedi remembers something about',
        fa: 'روزی که صدی چیزی ازش یادش مونده',
        ar: 'أيام تتذكر صدی شيئاً عنها',
      );
  String get recentDays => _t(en: 'Recent days', fa: 'آخرین روزها', ar: 'الأيام الأخيرة');
  String get noteForDay => _t(en: 'Note for a day', fa: 'یادداشت برای یک روز', ar: 'ملاحظة ليوم');
  String get prevMonth => _t(en: 'Previous month', fa: 'ماه قبل', ar: 'الشهر السابق');
  String get nextMonth => _t(en: 'Next month', fa: 'ماه بعد', ar: 'الشهر التالي');
  String get dayConversations => _t(en: 'Conversations', fa: 'گفتگوها', ar: 'المحادثات');
  String get youLabel => _t(en: 'You', fa: 'تو', ar: 'أنت');
  String get sediLabel => _t(en: 'Sedi', fa: 'صدی', ar: 'صدی');
  String get todayLabel => _t(en: 'Today', fa: 'امروز', ar: 'اليوم');
  String daysAgoLabel(int n) => n <= 0
      ? todayLabel
      : _t(en: '$n days ago', fa: '$n روز پیش', ar: 'قبل $n يوماً');
  String get sediDaySummary => _t(
        en: 'Sedi summary of this day',
        fa: 'خلاصه‌ی صدی از این روز',
        ar: 'ملخص صدی لهذا اليوم',
      );
  String get eventsAndNotes =>
      _t(en: 'Events and notes', fa: 'رویدادها و یادداشت‌ها', ar: 'الأحداث والملاحظات');
  String get learnedThatDay => _t(
        en: 'What Sedi learned that day',
        fa: 'چیزهایی که صدی همان روز یاد گرفت',
        ar: 'ما تعلمته صدی في ذلك اليوم',
      );
  String get addItem => _t(en: '+ Add', fa: '+ افزودن', ar: '+ إضافة');
  String get editItem => _t(en: 'Edit', fa: 'ویرایش', ar: 'تعديل');
  String get oldDayBanner => _t(
        en: 'Chat text older than 30 days is not shown, but Sedi remembers. Here is what she kept about this day.',
        fa: 'متن گفتگوهای بیشتر از ۳۰ روز نمایش داده نمی‌شود، ولی صدی یادش هست. خلاصه‌ی اون روز رو اینجا می‌بینی.',
        ar: 'لا يُعرض نص المحادثات الأقدم من 30 يوماً، لكن صدی تتذكرها. هذا ما احتفظت به عن هذا اليوم.',
      );
  String get fixSummary => _t(
        en: 'This summary is not right? Correct it',
        fa: 'این خلاصه درست نیست؟ اصلاحش کن',
        ar: 'هذا الملخص غير صحيح؟ صححه',
      );
  String get correctionsTitle => _t(
        en: 'Your corrections and notes',
        fa: 'اصلاحیه‌ها و یادداشت‌های تو',
        ar: 'تصحيحاتك وملاحظاتك',
      );
  String get correctionExplain => _t(
        en: 'The original summary stays as it is; your correction is saved beside it and Sedi considers both.',
        fa: 'خلاصه‌ی اصلی دست نمی‌خوره؛ اصلاحیه‌ی تو کنارش ثبت می‌شه و صدی هر دو رو در نظر می‌گیره.',
        ar: 'يبقى الملخص الأصلي كما هو؛ يُحفظ تصحيحك بجانبه وتأخذ صدی الاثنين في الاعتبار.',
      );
  String get correctionLabel => _t(en: 'Correction', fa: 'اصلاحیه', ar: 'تصحيح');
  String get noteLabel => _t(en: 'Note', fa: 'یادداشت', ar: 'ملاحظة');
  String get correctionHint => _t(
        en: 'What should Sedi remember instead?',
        fa: 'صدی به‌جاش چی باید یادش بمونه؟',
        ar: 'ماذا يجب أن تتذكر صدی بدلاً من ذلك؟',
      );
  String get noteHint =>
      _t(en: 'Write a note for this day', fa: 'برای این روز یادداشت بنویس', ar: 'اكتب ملاحظة لهذا اليوم');
  String get editMessageTitle =>
      _t(en: 'Edit message', fa: 'ویرایش پیام', ar: 'تعديل الرسالة');
  String get deleteMessageQuestion => _t(
        en: 'Delete this message from Sedi memory?',
        fa: 'این پیام از حافظه‌ی صدی پاک شود؟',
        ar: 'حذف هذه الرسالة من ذاكرة صدی؟',
      );
  String get deleteItemQuestion => _t(
        en: 'Delete this item?',
        fa: 'این مورد پاک شود؟',
        ar: 'حذف هذا العنصر؟',
      );
  String get emptyDay => _t(
        en: 'Nothing is recorded for this day yet.',
        fa: 'برای این روز هنوز چیزی ثبت نشده.',
        ar: 'لا شيء مسجل لهذا اليوم بعد.',
      );
  String get memoryConsentOff => _t(
        en: 'Sedi memory is turned off, so there is nothing to show.',
        fa: 'حافظه‌ی صدی خاموش است، برای همین چیزی برای نمایش نیست.',
        ar: 'ذاكرة صدی متوقفة، لذلك لا يوجد ما يُعرض.',
      );
  String get memoryLoadFailed => _t(
        en: 'Could not load this right now.',
        fa: 'الان نشد بارگذاری کنم.',
        ar: 'تعذر التحميل الآن.',
      );
  String get searchResultsTitle => _t(en: 'Search results', fa: 'نتایج جست‌وجو', ar: 'نتائج البحث');
  String searchResultCount(int n) => _t(en: '$n results', fa: '$n نتیجه', ar: '$n نتيجة');
  String get noSearchResults =>
      _t(en: 'Nothing found.', fa: 'چیزی پیدا نشد.', ar: 'لم يتم العثور على شيء.');
  String get searchOldDaysNote => _t(
        en: 'For days older than 30, search covers summaries, events and what Sedi knows, not the chat text.',
        fa: 'برای روزهای بیشتر از ۳۰ روز پیش، جست‌وجو روی خلاصه‌ها، رویدادها و چیزهایی که صدی می‌دونه انجام می‌شه، نه متن خام گفتگو.',
        ar: 'للأيام الأقدم من 30 يوماً يشمل البحث الملخصات والأحداث وما تعرفه صدی، لا نص المحادثة.',
      );
  String get rangeAll => _t(en: 'All time', fa: 'همه‌ی زمان‌ها', ar: 'كل الأوقات');
  String get rangeThreeMonths => _t(en: '3 months', fa: '۳ ماه', ar: '3 أشهر');
  String get rangeOneMonth => _t(en: '1 month', fa: '۱ ماه', ar: 'شهر');
  String hitType(String type) {
    switch (type) {
      case 'summary':
        return _t(en: 'Day summary', fa: 'خلاصه‌ی روز', ar: 'ملخص اليوم');
      case 'event':
        return _t(en: 'Event', fa: 'رویداد', ar: 'حدث');
      case 'note':
        return _t(en: 'Note', fa: 'یادداشت', ar: 'ملاحظة');
      case 'fact':
        return _t(en: 'What Sedi knows', fa: 'چیزی که صدی می‌دونه', ar: 'ما تعرفه صدی');
      default:
        return _t(en: 'Conversation', fa: 'گفتگو', ar: 'محادثة');
    }
  }

  String monthName(String calendar, int month) {
    const jalali = [
      'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
      'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
    ];
    const hijri = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
    ];
    const gregorian = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final i = (month - 1).clamp(0, 11).toInt();
    switch (calendar) {
      case 'jalali':
        return jalali[i];
      case 'hijri':
        return hijri[i];
      default:
        return gregorian[i];
    }
  }

  // ---- P8: set up / change the Nutrition and Exercise plan inside the page ----
  String get planSetupButton => _t(
        en: 'Set up or change plan',
        fa: 'تنظیم یا تغییر برنامه',
        ar: 'إعداد الخطة أو تعديلها',
      );
  String get allWeekHeading => _t(en: 'Whole week', fa: 'کل هفته', ar: 'الأسبوع كله');
  String planSetupTitle(bool nutrition) => nutrition
      ? _t(en: 'My nutrition plan', fa: 'برنامه تغذیه‌ی من', ar: 'خطة تغذيتي')
      : _t(en: 'My exercise plan', fa: 'برنامه ورزش من', ar: 'خطة تمريني');
  String get planSetupIntro => _t(
        en: 'Sedi starts from what she already knows about you. Tell her the rest here and she builds the plan.',
        fa: 'صدی از چیزهایی که از تو می‌دونه شروع می‌کنه؛ بقیه‌اش رو همین‌جا بگو تا برنامه رو بسازه.',
        ar: 'تبدأ صدی مما تعرفه عنك. أخبرها بالباقي هنا لتبني الخطة.',
      );
  String get knownFactsTitle =>
      _t(en: 'What I already know', fa: 'این‌ها رو از قبل می‌دونم', ar: 'ما أعرفه مسبقًا');
  String get goalQuestion => _t(en: 'What is your goal?', fa: 'هدفت چیه؟', ar: 'ما هدفك؟');
  String planGoalLabel(String key) {
    switch (key) {
      case 'sugar':
        return _t(en: 'Control blood sugar', fa: 'کنترل قند خون', ar: 'ضبط سكر الدم');
      case 'weight':
        return _t(en: 'Lose weight', fa: 'کاهش وزن', ar: 'إنقاص الوزن');
      case 'strength':
        return _t(en: 'Get stronger', fa: 'قوی‌تر شدن', ar: 'زيادة القوة');
      case 'mobility':
        return _t(en: 'Stay mobile', fa: 'انعطاف و تحرک', ar: 'المرونة والحركة');
      case 'fitness':
        return _t(en: 'Fitness', fa: 'تناسب اندام', ar: 'اللياقة');
      default:
        return _t(en: 'General health', fa: 'سلامت عمومی', ar: 'صحة عامة');
    }
  }

  String get mealsQuestion =>
      _t(en: 'How many meals a day?', fa: 'چند وعده در روز؟', ar: 'كم وجبة في اليوم؟');
  String mealsOption(int n) {
    switch (n) {
      case 3:
        return _t(en: '3 meals', fa: '۳ وعده', ar: '3 وجبات');
      case 4:
        return _t(en: '3 meals + snack', fa: '۳ وعده + میان‌وعده', ar: '3 وجبات + وجبة خفيفة');
      default:
        return _t(en: '5 meals', fa: '۵ وعده', ar: '5 وجبات');
    }
  }

  String get daysQuestion => _t(
        en: 'How many days a week can you exercise?',
        fa: 'هفته‌ای چند روز می‌تونی ورزش کنی؟',
        ar: 'كم يومًا في الأسبوع تستطيع التمرن؟',
      );
  String daysOption(int n) => CalendarDateMath.localizeDigitsForLanguage(
        _t(en: '$n days', fa: '$n روز', ar: '$n أيام'),
        lang,
      );

  String get avoidQuestion => _t(
        en: 'What do you dislike or avoid?',
        fa: 'چی رو دوست نداری یا نمی‌خوری؟',
        ar: 'ما الذي لا تحبه أو تتجنبه؟',
      );
  String avoidLabel(String key) {
    switch (key) {
      case 'fish':
        return _t(en: 'Fish', fa: 'ماهی', ar: 'السمك');
      case 'dairy':
        return _t(en: 'Dairy', fa: 'لبنیات', ar: 'الألبان');
      case 'red_meat':
        return _t(en: 'Red meat', fa: 'گوشت قرمز', ar: 'اللحم الأحمر');
      default:
        return _t(en: 'Eggs', fa: 'تخم‌مرغ', ar: 'البيض');
    }
  }

  String get otherThingHint =>
      _t(en: 'Something else (optional)', fa: 'چیز دیگه‌ای هم هست؟ (اختیاری)', ar: 'شيء آخر (اختياري)');
  String get buildPlanButton =>
      _t(en: 'Sedi, build the plan', fa: 'صدی برنامه رو بساز', ar: 'يا صدی، ابني الخطة');

  /// The user message the setup sheet sends to the canonical chat (the plan composer there does the rest).
  String composeSetupMessage({
    required bool nutrition,
    required String goalKey,
    required int count,
    required List<String> avoid,
    String extra = '',
  }) {
    final goal = planGoalLabel(goalKey);
    final avoided = [for (final a in avoid) avoidLabel(a), if (extra.trim().isNotEmpty) extra.trim()];
    final sep = lang == 'en' ? ', ' : '، ';
    if (nutrition) {
      final tail = avoided.isEmpty
          ? ''
          : _t(
              en: ' I do not like or eat: ${avoided.join(sep)}.',
              fa: ' این‌ها رو دوست ندارم یا نمی‌خورم: ${avoided.join(sep)}.',
              ar: ' لا أحب أو لا آكل: ${avoided.join(sep)}.',
            );
      return _t(
        en: 'Please build me a weekly nutrition plan. My goal: $goal. I want $count meals a day.$tail',
        fa: 'یه برنامه غذایی هفتگی برام بساز. هدفم: $goal. روزی $count وعده می‌خوام.$tail',
        ar: 'ابني لي خطة تغذية أسبوعية. هدفي: $goal. أريد $count وجبات في اليوم.$tail',
      );
    }
    final tail = extra.trim().isEmpty
        ? ''
        : _t(en: ' Note: ${extra.trim()}.', fa: ' نکته: ${extra.trim()}.', ar: ' ملاحظة: ${extra.trim()}.');
    return _t(
      en: 'Please build me a weekly exercise plan. My goal: $goal. I can exercise $count days a week.$tail',
      fa: 'یه برنامه ورزشی هفتگی برام بساز. هدفم: $goal. هفته‌ای $count روز می‌تونم ورزش کنم.$tail',
      ar: 'ابني لي خطة تمرين أسبوعية. هدفي: $goal. أستطيع التمرن $count أيام في الأسبوع.$tail',
    );
  }

  // item sheet
  String get itemMoveTime => _t(en: 'Change its time', fa: 'ساعتش رو عوض کن', ar: 'غيّر وقته');
  String get itemSkipToday =>
      _t(en: 'I will skip this today', fa: 'امروز انجامش نمی‌دم', ar: 'سأتخطى هذا اليوم');
  String get itemRemove => _t(
        en: 'Remove it from this week',
        fa: 'از برنامه‌ی این هفته حذفش کن',
        ar: 'احذفه من هذا الأسبوع',
      );
  String get itemRemoveQuestion => _t(
        en: 'Remove this item from this week?',
        fa: 'این مورد از برنامه‌ی این هفته حذف شود؟',
        ar: 'حذف هذا العنصر من هذا الأسبوع؟',
      );
  String get itemAskAlternative => _t(
        en: 'Ask Sedi for an alternative',
        fa: 'از صدی جایگزین بخواه',
        ar: 'اطلب بديلًا من صدی',
      );
  String alternativeMessage(String title) => _t(
        en: 'Please suggest an alternative to "$title" that fits my plan.',
        fa: 'یه جایگزین مناسب برای «$title» پیشنهاد بده که با برنامه‌ام جور باشه.',
        ar: 'اقترحي بديلًا مناسبًا لـ «$title» يناسب خطتي.',
      );

  // ---- P8b: alternatives and corrections inside the page ----
  String get alternativesTitle => _t(
        en: 'Alternatives that fit your plan',
        fa: 'جایگزین‌هایی که با برنامه‌ات جور درمیاد',
        ar: 'بدائل تناسب خطتك',
      );
  String get alternativesEmpty => _t(
        en: 'I could not find a fitting alternative right now; you can ask Sedi below.',
        fa: 'الان جایگزین مناسبی پیدا نکردم؛ می‌تونی پایین از صدی بخوای.',
        ar: 'لم أجد بديلاً مناسباً الآن؛ يمكنك أن تسأل صدی أدناه.',
      );
  String get applyChange => _t(en: 'Apply change', fa: 'ثبت تغییر', ar: 'تطبيق التغيير');
  String get itemEdit => _t(en: 'Edit text and duration', fa: 'ویرایش متن و مدت', ar: 'تعديل النص والمدة');
  String get editTitleHint => _t(en: 'Title', fa: 'عنوان', ar: 'العنوان');
  String get editNoteHint => _t(en: 'Note', fa: 'توضیح', ar: 'ملاحظة');
  String get editDurationHint => _t(en: 'Duration (minutes)', fa: 'مدت (دقیقه)', ar: 'المدة (دقائق)');
  String get planChangedSnack => _t(
        en: 'Saved. Sedi knows about it too.',
        fa: 'ثبت شد؛ صدی هم می‌دونه.',
        ar: 'تم الحفظ، وصدی تعرف ذلك أيضاً.',
      );

  // ---- Health: the simple three-line average (Javad 2026-10-28) ----
  String get avgHeartRateTitle => _t(en: 'Average heart rate', fa: 'میانگین ضربان قلب', ar: 'متوسط نبض القلب');
  String get avgLastWeek => _t(en: 'Last week', fa: 'هفته‌ی اخیر', ar: 'الأسبوع الأخير');
  String get avgLastMonth => _t(en: 'Last month', fa: 'ماه اخیر', ar: 'الشهر الأخير');
  String get avgLastYear => _t(en: 'Last year', fa: 'سال اخیر', ar: 'السنة الأخيرة');
}
