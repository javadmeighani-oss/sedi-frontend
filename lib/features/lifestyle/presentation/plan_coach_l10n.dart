import '../../../core/locale/sedi_locale_controller.dart';
import 'lifestyle_l10n.dart';

/// Strings of the plan coach screens (pilot V1 screen 6: Nutrition / Exercise). en / fa / ar, brand «صدی».
/// Short, warm, one idea per line.
class PlanCoachL10n {
  final String lang;
  final LifestyleL10n base;

  PlanCoachL10n([String? languageCode])
      : lang = languageCode ?? SediLocaleController.instance.languageCode,
        base = LifestyleL10n(languageCode);

  bool get isRtl => base.isRtl;

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

  String n(Object v) => base.digits(v);

  // ---- coach card ----
  String coachEmpty(bool nutrition) => nutrition
      ? _t(
          en: "Let's build your meal plan together. A few short questions and it is ready.",
          fa: 'بیا با هم برنامه‌ی غذاییت رو بسازیم. فقط چند سؤال کوتاه.',
          ar: 'لنبنِ خطتك الغذائية معًا. بضعة أسئلة قصيرة وتصبح جاهزة.',
        )
      : _t(
          en: "Let's build your exercise plan together. A few short questions and it is ready.",
          fa: 'بیا با هم برنامه‌ی ورزشت رو بسازیم. فقط چند سؤال کوتاه.',
          ar: 'لنبنِ خطتك الرياضية معًا. بضعة أسئلة قصيرة وتصبح جاهزة.',
        );

  String coachToday(int done, int total) => done >= total && total > 0
      ? _t(
          en: 'You finished everything planned for today. Well done!',
          fa: 'همه‌ی برنامه‌ی امروزت انجام شد. آفرین!',
          ar: 'أنجزت كل ما هو مخطط اليوم. أحسنت!',
        )
      : _t(
          en: 'Today: ${n(done)} of ${n(total)} done. I am with you.',
          fa: 'امروز ${n(done)} از ${n(total)} انجام شده. من کنارتم.',
          ar: 'اليوم: ${n(done)} من ${n(total)}. أنا معك.',
        );

  String get coachNothingToday => _t(
        en: 'Nothing is planned for today. Enjoy the rest.',
        fa: 'امروز برنامه‌ای نداری. از استراحتت لذت ببر.',
        ar: 'لا شيء مخطط اليوم. استمتع بالراحة.',
      );

  String get coachReviewDue => _t(
        en: 'This week is over. Shall we plan the next one?',
        fa: 'این هفته تموم شد. هفته‌ی بعد رو بچینیم؟',
        ar: 'انتهى هذا الأسبوع. هل نخطط للتالي؟',
      );

  String get setupButton => _t(en: 'Set up plan', fa: 'تنظیم برنامه', ar: 'ضبط الخطة');
  String get buildNow => _t(en: 'Build my plan', fa: 'برنامه‌ام رو بساز', ar: 'ابنِ خطتي');
  String get chatWithSedi => _t(en: 'Talk to Sedi', fa: 'گفتگو با صدی', ar: 'تحدث مع صدي');
  String get weekTitle => _t(en: 'This week', fa: 'این هفته', ar: 'هذا الأسبوع');
  String get restDay => _t(en: 'Rest day', fa: 'روز استراحت', ar: 'يوم راحة');
  String get nothingThisDay => _t(en: 'Nothing planned.', fa: 'برنامه‌ای نیست.', ar: 'لا شيء مخطط.');
  String get doneTick => _t(en: 'Done', fa: 'انجام شد', ar: 'تم');

  // ---- weekly review ----
  String get reviewTitle => _t(en: 'Weekly review', fa: 'مرور هفته', ar: 'مراجعة الأسبوع');
  String reviewCount(int done, int total) => _t(
        en: '${n(done)} of ${n(total)} done',
        fa: '${n(done)} از ${n(total)} انجام شد',
        ar: '${n(done)} من ${n(total)}',
      );
  String reviewBest(String weekday) => _t(
        en: 'Best day: $weekday',
        fa: 'بهترین روزت: $weekday',
        ar: 'أفضل يوم: $weekday',
      );
  String reviewDelta(int delta) => delta >= 0
      ? _t(
          en: '+${n(delta)}% vs last week',
          fa: '${n(delta)}٪ بیشتر از هفته‌ی قبل',
          ar: '+${n(delta)}٪ عن الأسبوع الماضي',
        )
      : _t(
          en: '${n(delta)}% vs last week',
          fa: '${n(-delta)}٪ کمتر از هفته‌ی قبل',
          ar: '${n(delta)}٪ عن الأسبوع الماضي',
        );
  String get reviewChat => _t(en: 'Talk about my week', fa: 'درباره‌ی هفته‌ام حرف بزنیم', ar: 'لنتحدث عن أسبوعي');
  String get reviewChatMessage => _t(
        en: 'Let us talk about how my plan went this week.',
        fa: 'بیا درباره‌ی این‌که برنامه‌م این هفته چطور گذشت حرف بزنیم.',
        ar: 'لنتحدث عن كيف مضت خطتي هذا الأسبوع.',
      );

  // ---- setup sheet (three calm steps) ----
  String stepTitle(int step, bool nutrition) {
    switch (step) {
      case 0:
        return nutrition
            ? _t(en: 'Goal and foods to avoid', fa: 'هدف و غذاهای کنار گذاشته', ar: 'الهدف والأطعمة المتجنَّبة')
            : _t(en: 'Your goal', fa: 'هدفت', ar: 'هدفك');
      case 1:
        return nutrition
            ? _t(en: 'Meals and times', fa: 'وعده‌ها و ساعتشون', ar: 'الوجبات وأوقاتها')
            : _t(en: 'Time and days', fa: 'ساعت و روزها', ar: 'الوقت والأيام');
      default:
        return _t(en: 'Reminders and weekly review', fa: 'یادآوری و مرور هفتگی', ar: 'التذكير والمراجعة الأسبوعية');
    }
  }

  String stepOf(int step) => _t(
        en: 'Step ${n(step + 1)} of ${n(3)}',
        fa: 'مرحله‌ی ${n(step + 1)} از ${n(3)}',
        ar: 'الخطوة ${n(step + 1)} من ${n(3)}',
      );

  String get next => _t(en: 'Next', fa: 'بعدی', ar: 'التالي');
  String get back => _t(en: 'Back', fa: 'قبلی', ar: 'السابق');
  String get allergyQuestion =>
      _t(en: 'Any food allergy?', fa: 'آلرژی غذایی داری؟', ar: 'هل لديك حساسية غذائية؟');
  String get noAllergy => _t(en: 'No allergy', fa: 'آلرژی ندارم', ar: 'لا حساسية');
  String get allergyHint => _t(en: 'Which foods?', fa: 'به چی؟', ar: 'من أي أطعمة؟');
  String get allergyNeeded => _t(
        en: 'Please tell me about allergies first, so the plan is safe for you.',
        fa: 'اول آلرژی‌هات رو بگو تا برنامه برات امن باشه.',
        ar: 'أخبرني عن الحساسية أولًا ليكون البرنامج آمنًا لك.',
      );
  String get avoidMore => _t(en: 'Anything else to avoid?', fa: 'چیز دیگه‌ای کنار بذارم؟', ar: 'شيء آخر نتجنبه؟');
  String get exerciseTimeQuestion =>
      _t(en: 'When do you usually move?', fa: 'معمولاً کی حرکت می‌کنی؟', ar: 'متى تتحرك عادةً؟');
  String get remindDaysQuestion =>
      _t(en: 'Remind me on these days', fa: 'این روزها یادآوری کن', ar: 'ذكّرني في هذه الأيام');
  String get leadQuestion => _t(en: 'How early?', fa: 'چقدر زودتر؟', ar: 'قبل كم؟');
  String leadLabel(int? lead) {
    if (lead == null) return _t(en: 'Off', fa: 'خاموش', ar: 'إيقاف');
    if (lead == 0) return _t(en: 'On time', fa: 'سر وقت', ar: 'في الوقت');
    return _t(en: '${n(lead)} min before', fa: '${n(lead)} دقیقه قبل', ar: 'قبل ${n(lead)} د');
  }

  String get reviewDayQuestion =>
      _t(en: 'Weekly review day', fa: 'روز مرور هفتگی', ar: 'يوم المراجعة الأسبوعية');
  String get reviewTimeQuestion => _t(en: 'At what time?', fa: 'چه ساعتی؟', ar: 'في أي ساعة؟');
  String get buildAndSave => _t(en: 'Save and build', fa: 'ذخیره و ساخت برنامه', ar: 'حفظ وبناء الخطة');
  String get saveOnly => _t(en: 'Save', fa: 'ذخیره', ar: 'حفظ');
  String get buildOk => _t(
        en: 'Your plan is ready. I will remind you on time.',
        fa: 'برنامه‌ت آماده‌ست. سر وقت یادآوری می‌کنم.',
        ar: 'خطتك جاهزة. سأذكّرك في الموعد.',
      );
  String get settingsSaved => _t(en: 'Saved.', fa: 'ثبت شد.', ar: 'تم الحفظ.');
  String get buildFailed => _t(
        en: 'Could not build it now. Try again in a moment, or tell me in chat.',
        fa: 'الان نشد بسازم. یه لحظه دیگه دوباره امتحان کن یا تو چت بهم بگو.',
        ar: 'تعذّر البناء الآن. حاول بعد قليل أو أخبرني في الدردشة.',
      );
  String get consentNeeded => _t(
        en: 'To remember your answers I need memory turned on in your profile.',
        fa: 'برای اینکه جواب‌هات رو یادم بمونه، حافظه باید توی پروفایلت روشن باشه.',
        ar: 'لأتذكر إجاباتك يجب تفعيل الذاكرة في ملفك.',
      );
}
