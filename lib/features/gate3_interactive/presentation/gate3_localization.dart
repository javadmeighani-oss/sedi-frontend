import '../../../core/locale/sedi_locale_registry.dart';

/// Gate 3 localized strings — presentation adaptor only.
/// Language authority is [SediLocaleController] / Account.preferred_language.
class Gate3Localization {
  final String lang;

  const Gate3Localization(this.lang);

  bool get isRtl => SediLocaleRegistry.resolve(lang).isRtl;

  String get notifications =>
      _t(en: 'Notifications', fa: 'اعلان‌ها', ar: 'الإشعارات');

  String get healthCare =>
      _t(en: 'Health Care', fa: 'مراقبت سلامت', ar: 'الرعاية الصحية');

  String get lifestyle =>
      _t(en: 'Lifestyle', fa: 'سبک زندگی', ar: 'نمط الحياة');

  String get gadgets => _t(en: 'Gadgets', fa: 'گجت‌ها', ar: 'الأجهزة');

  String get history => _t(en: 'History', fa: 'تاریخچه', ar: 'السجل');

  String get settings => _t(en: 'Settings', fa: 'تنظیمات', ar: 'الإعدادات');

  String get memoryAndPrivacy => _t(
        en: 'Memory & Privacy',
        fa: 'حافظه و حریم خصوصی',
        ar: 'الذاكرة والخصوصية',
      );

  String get memoryConsentInvitation => _t(
        en: 'Sedi can remember helpful details across conversations if you allow Memory.',
        fa: 'اگر اجازه حافظه را بدهید، صدی می‌تواند جزئیات مفید را در گفتگوها به خاطر بسپارد.',
        ar: 'يمكن لصدی تذكّر التفاصيل المفيدة عبر المحادثات إذا سمحت بالذاكرة.',
      );

  String get memoryConsentGrant =>
      _t(en: 'Allow Memory', fa: 'اجازه حافظه', ar: 'السماح بالذاكرة');

  String get memoryConsentRevoke =>
      _t(en: 'Revoke Memory', fa: 'لغو حافظه', ar: 'إلغاء الذاكرة');

  String get memoryConsentNotNow =>
      _t(en: 'Not now', fa: 'بعداً', ar: 'ليس الآن');

  String get memoryConsentStatusLabel =>
      _t(en: 'Current status', fa: 'وضعیت فعلی', ar: 'الحالة الحالية');

  String get memoryConsentBusy =>
      _t(en: 'Updating…', fa: 'در حال به‌روزرسانی…', ar: 'جارٍ التحديث…');

  String get memoryConsentLoadError => _t(
        en: 'Could not load Memory status. Try again.',
        fa: 'وضعیت حافظه بارگذاری نشد. دوباره تلاش کنید.',
        ar: 'تعذر تحميل حالة الذاكرة. حاول مرة أخرى.',
      );

  String get memoryConsentActionError => _t(
        en: 'Could not update Memory consent. Try again.',
        fa: 'به‌روزرسانی رضایت حافظه انجام نشد. دوباره تلاش کنید.',
        ar: 'تعذر تحديث موافقة الذاكرة. حاول مرة أخرى.',
      );

  String get memoryControlOn =>
      _t(en: 'Memory on', fa: 'حافظه روشن', ar: 'الذاكرة قيد التشغيل');

  String get memoryControlOff =>
      _t(en: 'Memory off', fa: 'حافظه خاموش', ar: 'الذاكرة متوقفة');

  String get memoryOffConfirmTitle => _t(
        en: 'Turn off Sedi Memory?',
        fa: 'خاموش کردن حافظه صدی؟',
        ar: 'إيقاف ذاكرة صدی؟',
      );

  String get memoryOffConfirmBody => _t(
        en:
            'If you turn Memory off, Sedi will not store new conversation details for later use from this moment, and will not use stored memory for conversation continuity. Care continuity, personalization, and companion accuracy will decrease. Are you sure?',
        fa:
            'با خاموش کردن حافظه، از این لحظه صدی اطلاعات جدید گفتگو را برای استفاده در دفعات بعد ذخیره نمی‌کند و از حافظه ذخیره‌شده برای پیوستگی گفتگو استفاده نخواهد کرد. در نتیجه پیوستگی مراقبت، شخصی‌سازی و دقت همراهی صدی کاهش می‌یابد. آیا مطمئن هستید؟',
        ar:
            'بإيقاف الذاكرة، لن يخزّن صدی من هذه اللحظة تفاصيل المحادثة الجديدة للاستخدام لاحقًا ولن يستخدم الذاكرة المخزّنة لاستمرار المحادثة. لذلك تنخفض استمرارية الرعاية والتخصيص ودقة مرافقة صدی. هل أنت متأكد؟',
      );

  String get memoryOffConfirmKeepOn => _t(
        en: 'No, keep Memory on',
        fa: 'خیر، حافظه روشن بماند',
        ar: 'لا، لتبقَ الذاكرة قيد التشغيل',
      );

  String get memoryOffConfirmTurnOff => _t(
        en: 'Yes, turn Memory off',
        fa: 'بله، حافظه خاموش شود',
        ar: 'نعم، أوقف الذاكرة',
      );

  String get editProfile => _t(
        en: 'Edit profile',
        fa: 'ویرایش پروفایل',
        ar: 'تعديل الملف الشخصي',
      );

  String get expandDestinations => _t(
        en: 'Show destinations',
        fa: 'نمایش مقصدها',
        ar: 'إظهار الوجهات',
      );

  String get collapseDestinations => _t(
        en: 'Hide destinations',
        fa: 'پنهان کردن مقصدها',
        ar: 'إخفاء الوجهات',
      );

  String get profileTitle =>
      _t(en: 'Profile', fa: 'پروفایل', ar: 'الملف الشخصي');

  String get userInformationSection => _t(
        en: 'User information',
        fa: 'اطلاعات کاربر',
        ar: 'معلومات المستخدم',
      );

  String get userSummarySection => _t(
        en: 'User summary',
        fa: 'خلاصه کاربر',
        ar: 'ملخص المستخدم',
      );

  String get userSummaryEmpty => _t(
        en:
            'There is not enough information about you in Sedi memory yet. As you continue chatting and using Sedi, this section will gradually become more complete.',
        fa:
            'در حال حاضر، اطلاعات کافی از شما در حافظه صدی ثبت نشده است. با ادامه گفت‌وگو و استفاده از صدی، این بخش به‌تدریج کامل‌تر می‌شود.',
        ar:
            'لا تتوفر حاليًا معلومات كافية عنك في ذاكرة صدی. مع مواصلة المحادثة واستخدام صدی، سيكتمل هذا القسم تدريجيًا.',
      );

  String get profileLanguageLabel =>
      _t(en: 'Preferred language', fa: 'زبان ترجیحی', ar: 'اللغة المفضلة');

  String get logout => _t(en: 'Log out', fa: 'خروج', ar: 'تسجيل الخروج');

  String get logoutApp =>
      _t(en: 'Log out of app', fa: 'خروج از برنامه', ar: 'تسجيل الخروج من التطبيق');

  String get profileNameLabel =>
      _t(en: 'Name', fa: 'نام', ar: 'الاسم');
  String get profileDobLabel =>
      _t(en: 'Date of birth', fa: 'تاریخ تولد', ar: 'تاريخ الميلاد');
  String get profileSexLabel =>
      _t(en: 'Sex', fa: 'جنسیت', ar: 'الجنس');
  String get profilePhoneLabel =>
      _t(en: 'Phone', fa: 'شماره همراه', ar: 'الهاتف');

  /// Presentation-only sex label from backend canonical codes.
  String profileSexValue(String? code) {
    switch ((code ?? '').trim().toLowerCase()) {
      case 'male':
        return _t(en: 'Male', fa: 'مرد', ar: 'ذكر');
      case 'female':
        return _t(en: 'Female', fa: 'زن', ar: 'أنثى');
      case 'other':
        return _t(en: 'Other', fa: 'سایر', ar: 'آخر');
      default:
        return '—';
    }
  }

  /// Localized label for a backend summary row key (presentation only).
  String summaryRowLabel(String key) {
    switch (key) {
      case 'memory_consent':
        return _t(
          en: 'Memory consent',
          fa: 'رضایت حافظه',
          ar: 'موافقة الذاكرة',
        );
      case 'memory_write':
        return _t(
          en: 'Memory write',
          fa: 'نوشتن حافظه',
          ar: 'كتابة الذاكرة',
        );
      case 'memory_read':
        return _t(
          en: 'Memory read',
          fa: 'خواندن حافظه',
          ar: 'قراءة الذاكرة',
        );
      case 'daily_plan':
        return _t(
          en: "Today's plan",
          fa: 'برنامه امروز',
          ar: 'خطة اليوم',
        );
      case 'plan_actions':
        return _t(
          en: 'Plan actions',
          fa: 'اقدامات برنامه',
          ar: 'إجراءات الخطة',
        );
      default:
        return key;
    }
  }

  /// Localized label for a backend summary status code (presentation only).
  String summaryStatusLabel(String status) {
    switch (status) {
      case 'granted':
        return _t(en: 'Granted', fa: 'اعطا شده', ar: 'ممنوحة');
      case 'not_granted':
        return _t(en: 'Not granted', fa: 'اعطا نشده', ar: 'غير ممنوحة');
      case 'revoked':
        return _t(en: 'Revoked', fa: 'لغو شده', ar: 'ملغاة');
      case 'expired':
        return _t(en: 'Expired', fa: 'منقضی', ar: 'منتهية');
      case 'allowed':
        return _t(en: 'Allowed', fa: 'مجاز', ar: 'مسموح');
      case 'denied':
        return _t(en: 'Not allowed', fa: 'غیرمجاز', ar: 'غير مسموح');
      case 'active':
        return _t(en: 'Active', fa: 'فعال', ar: 'نشطة');
      case 'none':
        return _t(en: 'None', fa: 'وجود ندارد', ar: 'لا يوجد');
      case 'unavailable':
        return _t(en: 'Unavailable', fa: 'در دسترس نیست', ar: 'غير متاح');
      case 'no_actions':
        return _t(en: 'No actions', fa: 'بدون اقدام', ar: 'لا إجراءات');
      case 'in_progress':
        return _t(en: 'In progress', fa: 'در حال انجام', ar: 'قيد التنفيذ');
      case 'completed':
        return _t(en: 'Completed', fa: 'تکمیل شده', ar: 'مكتملة');
      case 'partial':
        return _t(en: 'Partial', fa: 'ناقص', ar: 'جزئي');
      default:
        return status;
    }
  }
  String get changePhone =>
      _t(en: 'Change phone', fa: 'تغییر شماره', ar: 'تغيير الهاتف');
  String get newPhoneLabel =>
      _t(en: 'New phone number', fa: 'شماره جدید', ar: 'رقم جديد');
  String get sendPhoneOtp =>
      _t(en: 'Send code', fa: 'ارسال کد', ar: 'إرسال الرمز');
  String get verifyPhoneOtp =>
      _t(en: 'Verify', fa: 'تأیید', ar: 'تحقق');
  String get otpCodeLabel =>
      _t(en: 'OTP code', fa: 'کد تأیید', ar: 'رمز التحقق');
  String get phoneChangeSuccess => _t(
        en: 'Phone updated.',
        fa: 'شماره به‌روز شد.',
        ar: 'تم تحديث الهاتف.',
      );
  String get phoneInvalid => _t(
        en: 'Enter a valid phone number.',
        fa: 'شماره معتبر وارد کنید.',
        ar: 'أدخل رقم هاتف صالحًا.',
      );
  String get phoneSame => _t(
        en: 'That is already your current number.',
        fa: 'این همان شماره فعلی شماست.',
        ar: 'هذا هو رقمك الحالي بالفعل.',
      );
  String get phoneDuplicate => _t(
        en: 'This number is already in use.',
        fa: 'این شماره قبلاً استفاده شده است.',
        ar: 'هذا الرقم مستخدم بالفعل.',
      );
  String get phoneOtpInvalid =>
      _t(en: 'Incorrect code.', fa: 'کد نادرست است.', ar: 'رمز غير صحيح.');
  String get phoneOtpExpired =>
      _t(en: 'Code expired.', fa: 'کد منقضی شده است.', ar: 'انتهت صلاحية الرمز.');
  String get phoneOtpRateLimited => _t(
        en: 'Too many requests. Try again later.',
        fa: 'درخواست‌های زیاد. بعداً تلاش کنید.',
        ar: 'طلبات كثيرة. حاول لاحقًا.',
      );
  String get phoneChangeNetworkError => _t(
        en: 'Network error. Try again.',
        fa: 'خطای شبکه. دوباره تلاش کنید.',
        ar: 'خطأ في الشبكة. حاول مرة أخرى.',
      );
  String get cancel => _t(en: 'Cancel', fa: 'انصراف', ar: 'إلغاء');
  String get activeSubjectSelf =>
      _t(en: 'Viewing: Me', fa: 'نمایش: خودم', ar: 'العرض: أنا');
  String get activeSubjectFor =>
      _t(en: 'Viewing:', fa: 'نمایش:', ar: 'العرض:');
  String get activeSubjectUnknown =>
      _t(en: 'Viewing: —', fa: 'نمایش: —', ar: 'العرض: —');
  String get selectSubject =>
      _t(en: 'Select person', fa: 'انتخاب فرد', ar: 'اختر شخصًا');
  String get lifestyleOtherUnavailable => _t(
        en: 'Lifestyle is available for your own profile only.',
        fa: 'سبک زندگی فقط برای پروفایل خودتان در دسترس است.',
        ar: 'نمط الحياة متاح لملفك الشخصي فقط.',
      );
  String get gadgetsGroupMine =>
      _t(en: 'My devices', fa: 'دستگاه‌های من', ar: 'أجهزتي');
  String get whatSediKnows => _t(
        en: 'What Sedi knows about me',
        fa: 'آنچه صدی درباره من می‌داند',
        ar: 'ما تعرفه صدي عني',
      );
  String get whatSediKnowsEmpty => _t(
        en: 'No saved facts yet.',
        fa: 'هنوز حقیقت ذخیره‌شده‌ای نیست.',
        ar: 'لا توجد حقائق محفوظة بعد.',
      );

  String get profileSettingsPlaceholder => _t(
        en: 'Profile settings will be available here soon.',
        fa: 'تنظیمات پروفایل به‌زودی در این بخش در دسترس خواهد بود.',
        ar: 'ستتوفر إعدادات الملف الشخصي هنا قريبًا.',
      );

  String get composerPlaceholderFa => 'صحبت با صدی';

  String get composerPlaceholder {
    if (lang == 'fa') return composerPlaceholderFa;
    if (lang == 'ar') return 'تحدث مع صدي';
    return 'Talk to Sedi';
  }

  String get microphonePermissionRequired => _t(
        en: 'Microphone permission required',
        fa: 'دسترسی به میکروفون لازم است',
        ar: 'مطلوب إذن الميكروفون',
      );

  String get pressBackAgainToExit => _t(
        en: 'Press back again to exit',
        fa: 'برای خروج دوباره back بزنید',
        ar: 'اضغط رجوع مرة أخرى للخروج',
      );

  String get returnToLatest =>
      _t(en: 'Latest', fa: 'آخرین', ar: 'الأحدث');

  String get close => _t(en: 'Close', fa: 'بستن', ar: 'إغلاق');

  String get camera => _t(en: 'Camera', fa: 'دوربین', ar: 'الكاميرا');

  String get photos => _t(en: 'Photos', fa: 'تصاویر', ar: 'الصور');

  String get files => _t(en: 'Files', fa: 'فایل‌ها', ar: 'الملفات');

  String get attachmentComingSoon => _t(
        en: 'Attachments will be available here soon.',
        fa: 'پیوست‌ها به‌زودی در این بخش در دسترس خواهند بود.',
        ar: 'ستتوفر المرفقات هنا قريبًا.',
      );

  /// Non-clinical empty-state hint — not a chat transcript or Sedi reply.
  String get emptyConversationHint => _t(
        en: 'Your conversation will appear here.',
        fa: 'گفتگو اینجا نمایش داده می‌شود.',
        ar: 'ستظهر محادثتك هنا.',
      );

  String get editMessage => _t(en: 'Edit', fa: 'ویرایش', ar: 'تعديل');

  String get dayToday => _t(en: 'Today', fa: 'امروز', ar: 'اليوم');

  String get dayYesterday => _t(en: 'Yesterday', fa: 'دیروز', ar: 'أمس');

  String get readMore => _t(en: 'Read more', fa: 'بیشتر', ar: 'المزيد');

  String get readLess => _t(en: 'Read less', fa: 'کمتر', ar: 'أقل');

  String get tapToRetry => _t(
        en: 'Tap to retry',
        fa: 'برای تلاش دوباره بزن',
        ar: 'اضغط لإعادة المحاولة',
      );

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
}
