import 'gate3_localization.dart';

/// Strings of "My memory" and chat attachments / voice (R-021 / M1, M4). An extension keeps the large
/// Gate3Localization file untouched; the brand is always «صدی» in FA/AR (R-007).
extension Gate3MemoryL10n on Gate3Localization {
  String _p({required String en, required String fa, required String ar}) {
    switch (lang) {
      case 'fa':
        return fa;
      case 'ar':
        return ar;
      default:
        return en;
    }
  }

  String get memoryOpen => _p(en: 'My memory', fa: 'حافظه‌ی من', ar: 'ذاكرتي');

  String get memoryPageIntro => _p(
        en: 'This is what Sedi remembers about you. Correct or delete anything that is not right — your word is final.',
        fa: 'این چیزهایی است که صدی درباره‌ی تو به یاد دارد. هر چیزی که درست نیست را اصلاح یا پاک کن؛ حرف تو آخرین حرف است.',
        ar: 'هذا ما تتذكره صدی عنك. صحّح أو احذف أي شيء غير صحيح؛ كلمتك هي الأخيرة.',
      );

  String get memoryFactsSection => _p(
        en: 'What I know about you',
        fa: 'چیزهایی که از تو می‌دانم',
        ar: 'ما أعرفه عنك',
      );

  String get memoryTimelineSection => _p(
        en: 'Your life story',
        fa: 'مسیر زندگی و اتفاق‌های مهم',
        ar: 'قصة حياتك',
      );

  String get memoryEmpty => _p(
        en: 'Nothing is remembered yet. As we talk, this fills in.',
        fa: 'هنوز چیزی ثبت نشده. با ادامه‌ی گفت‌وگو، این بخش پر می‌شود.',
        ar: 'لا شيء محفوظ بعد. مع استمرار حديثنا يمتلئ هذا القسم.',
      );

  String get memoryConsentOff => _p(
        en: 'Memory is off. Turn it on from your profile so Sedi can remember you.',
        fa: 'حافظه خاموش است. برای اینکه صدی تو را به یاد بسپارد، آن را از پروفایل روشن کن.',
        ar: 'الذاكرة متوقفة. شغّلها من ملفك ليتذكرك صدی.',
      );

  String get memoryLoadFailed => _p(
        en: 'Could not load your memory. Try again.',
        fa: 'حافظه‌ات بارگذاری نشد. دوباره تلاش کن.',
        ar: 'تعذّر تحميل ذاكرتك. حاول مجدداً.',
      );

  String get memoryEdit => _p(en: 'Edit', fa: 'ویرایش', ar: 'تعديل');
  String get memoryDelete => _p(en: 'Delete', fa: 'پاک کردن', ar: 'حذف');
  String get memorySave => _p(en: 'Save', fa: 'ذخیره', ar: 'حفظ');
  String get memoryCancel => _p(en: 'Cancel', fa: 'انصراف', ar: 'إلغاء');
  String get memoryAddEvent =>
      _p(en: 'Add an event', fa: 'افزودن یک اتفاق مهم', ar: 'إضافة حدث مهم');
  String get memoryEventHint => _p(
        en: 'e.g. I moved to a new city',
        fa: 'مثلاً: به شهر جدیدی نقل‌مکان کردم',
        ar: 'مثلاً: انتقلت إلى مدينة جديدة',
      );
  String get memoryDeleteConfirm => _p(
        en: 'Delete this from my memory?',
        fa: 'این مورد از حافظه‌ام پاک شود؟',
        ar: 'حذف هذا من ذاكرتي؟',
      );
  String get memoryActionFailed => _p(
        en: 'That did not work. Try again.',
        fa: 'انجام نشد. دوباره تلاش کن.',
        ar: 'لم تنجح العملية. حاول مجدداً.',
      );

  /// Label of one remembered fact («علاقه‌مندی‌ها: …»).
  String memoryFactLabel(String key) {
    switch (key) {
      case 'health_concerns':
        return _p(en: 'Health', fa: 'وضعیت سلامت', ar: 'الحالة الصحية');
      case 'family_history':
        return _p(en: 'Family health history', fa: 'سابقه‌ی خانوادگی', ar: 'التاريخ الصحي للعائلة');
      case 'allergies':
        return _p(en: 'Allergies', fa: 'حساسیت‌ها', ar: 'الحساسية');
      case 'goal':
        return _p(en: 'Goal', fa: 'هدف', ar: 'الهدف');
      case 'occupation':
        return _p(en: 'Work', fa: 'شغل', ar: 'العمل');
      case 'household_context':
        return _p(en: 'Living situation', fa: 'وضعیت زندگی', ar: 'وضع المعيشة');
      case 'interests':
        return _p(en: 'Interests', fa: 'علاقه‌مندی‌ها', ar: 'الاهتمامات');
      case 'food_preferences':
        return _p(en: 'Food preferences', fa: 'ترجیح‌های غذایی', ar: 'التفضيلات الغذائية');
      case 'exercise_preferences':
        return _p(en: 'Exercise preferences', fa: 'ترجیح‌های ورزشی', ar: 'تفضيلات الرياضة');
      case 'sleep_duration_hours':
        return _p(en: 'Sleep (hours a night)', fa: 'خواب (ساعت در شب)', ar: 'النوم (ساعات في الليلة)');
      case 'sleep_quality':
        return _p(en: 'Sleep quality', fa: 'کیفیت خواب', ar: 'جودة النوم');
      case 'stress_level':
        return _p(en: 'Stress', fa: 'استرس', ar: 'الضغط النفسي');
      case 'mood':
        return _p(en: 'Mood', fa: 'حال و روحیه', ar: 'المزاج');
      default:
        return key;
    }
  }

  // ----- chat box: documents / images / voice -----
  String get attachUploading =>
      _p(en: 'Sending…', fa: 'در حال فرستادن…', ar: 'جارٍ الإرسال…');
  String get attachReading => _p(
        en: 'Sedi is reading it…',
        fa: 'صدی دارد آن را می‌خواند…',
        ar: 'صدی تقرأه الآن…',
      );
  String get attachFailed => _p(
        en: 'I could not read that. Try a clearer photo or file.',
        fa: 'نتوانستم آن را بخوانم. یک عکس یا فایل واضح‌تر امتحان کن.',
        ar: 'لم أستطع قراءته. جرّب صورة أو ملفاً أوضح.',
      );
  String get attachDisabled => _p(
        en: 'This feature is not active yet.',
        fa: 'این قابلیت هنوز فعال نشده است.',
        ar: 'هذه الميزة غير مفعّلة بعد.',
      );
  String get attachConsentNeeded => _p(
        en: 'Turn memory on in your profile first.',
        fa: 'اول حافظه را از پروفایل روشن کن.',
        ar: 'شغّل الذاكرة من ملفك أولاً.',
      );
  String get attachResultTitle =>
      _p(en: 'I read your document', fa: 'مدرکت را خواندم', ar: 'قرأت وثيقتك');
  String get attachRemember => _p(
        en: 'Keep it in my memory',
        fa: 'در حافظه‌ام نگه دار',
        ar: 'احتفظ بها في ذاكرتي',
      );
  String get attachDiscard =>
      _p(en: 'Delete it', fa: 'حذفش کن', ar: 'احذفها');
  String get attachTalk => _p(
        en: 'Talk to Sedi about it',
        fa: 'درباره‌اش با صدی حرف بزن',
        ar: 'تحدّث مع صدی عنها',
      );
  String get attachRemembered => _p(
        en: 'Saved to your memory.',
        fa: 'در حافظه‌ات ثبت شد.',
        ar: 'تم الحفظ في ذاكرتك.',
      );
  String get attachFindings =>
      _p(en: 'Printed values', fa: 'مقادیر نوشته‌شده', ar: 'القيم المكتوبة');
  String get attachNotAdvice => _p(
        en: 'I only read what is printed; I do not interpret it as a diagnosis.',
        fa: 'من فقط آنچه نوشته شده را می‌خوانم؛ تفسیر پزشکی نمی‌کنم.',
        ar: 'أقرأ فقط ما هو مكتوب ولا أفسّره طبياً.',
      );
  String attachTalkMessage(String summary) => _p(
        en: 'I sent you a document. Here is what it says: $summary',
        fa: 'یک مدرک برایت فرستادم. خلاصه‌اش این است: $summary',
        ar: 'أرسلت لك وثيقة. هذا ملخصها: $summary',
      );
  String get voiceTranscribing => _p(
        en: 'Turning your voice into text…',
        fa: 'در حال تبدیل صدایت به متن…',
        ar: 'جارٍ تحويل صوتك إلى نص…',
      );
  String get voiceFailed => _p(
        en: 'I could not understand the recording. Try again or type.',
        fa: 'صدا را متوجه نشدم. دوباره امتحان کن یا بنویس.',
        ar: 'لم أفهم التسجيل. حاول مجدداً أو اكتب.',
      );
}
