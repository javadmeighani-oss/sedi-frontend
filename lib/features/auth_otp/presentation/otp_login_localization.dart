import '../../../core/utils/brand_name.dart';

/// Gate 2 localized strings and month names.
class OtpLoginLocalization {
  final String lang;

  const OtpLoginLocalization(this.lang);

  bool get isRtl => lang == 'fa' || lang == 'ar';

  static const persianMonths = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<String> get months {
    switch (lang) {
      case 'fa':
        return persianMonths;
      case 'ar':
        return hijriMonths;
      default:
        return englishMonths;
    }
  }

  String get confirm => _t(en: 'Confirm', fa: 'تأیید', ar: 'تأكيد');

  /// First-page welcome copy (hologram redesign). Brand spelling via [sediBrandName].
  String get welcomeHeadline => _t(
        en: "Hi, I'm ${sediBrandName('en')}",
        fa: 'سلام، من ${sediBrandName('fa')}‌ام',
        ar: 'مرحباً، أنا ${sediBrandName('ar')}',
      );

  String get welcomeTagline => _t(
        en: 'Your always-there friend — remembers what you say and looks out for how you are doing.',
        fa: 'دوستِ همیشه‌همراهت؛ حرف‌هات رو یادش می‌مونه و حواسش به حال و روزت هست.',
        ar: 'صديقك الدائم؛ يتذكّر ما تقوله ويهتمّ بحالك.',
      );

  String get welcomePromiseListen =>
      _t(en: 'I listen', fa: 'گوش می‌دم', ar: 'أستمع');

  String get welcomePromiseRemember =>
      _t(en: 'I remember', fa: 'یادم می‌مونه', ar: 'أتذكّر');

  String get welcomePromiseCare =>
      _t(en: 'I care', fa: 'مراقبتم', ar: 'أهتمّ بك');

  String get enterSediTitle => _t(
        en: 'Enter Sedi',
        fa: 'ورود به صدی',
        ar: 'الدخول إلى صدي',
      );

  String get enterSediSubtitle => _t(
        en: 'Please choose the right path',
        fa: 'لطفاً مسیر مناسب را انتخاب کنید',
        ar: 'يرجى اختيار المسار المناسب',
      );

  String get haveAccountTitle => _t(
        en: 'I already have an account',
        fa: 'قبلاً حساب کاربری دارم',
        ar: 'لدي حساب بالفعل',
      );

  String get haveAccountDesc => _t(
        en:
            'Sign in with your phone number and verification code',
        fa:
            'با شماره همراه و کد تأیید وارد می‌شوم',
        ar: 'سأدخل برقم الهاتف ورمز التحقق',
      );

  String get noAccountTitle => _t(
        en: 'I want to create an account',
        fa: 'می‌خواهم حساب کاربری بسازم',
        ar: 'أريد إنشاء حساب',
      );

  String get noAccountDesc => _t(
        en:
            'Register for the first time with your full information',
        fa: 'برای اولین بار با اطلاعات کامل ثبت‌نام می‌کنم',
        ar: 'سأسجل لأول مرة بمعلوماتي الكاملة',
      );

  String get returningTitle => _t(
        en: 'Returning User Login',
        fa: 'ورود کاربران قبلی',
        ar: 'دخول المستخدمين السابقين',
      );

  String get returningSubtitle => _t(
        en: 'Enter your mobile number so Sedi can recognize you again',
        fa: 'فقط شماره همراه خود را وارد کنید تا صدی شما را دوباره بشناسد',
        ar: 'أدخل رقم هاتفك حتى يتعرف عليك صدي مرة أخرى',
      );

  String get newUserTitle => _t(
        en: 'New User Registration',
        fa: 'ثبت‌نام کاربر جدید',
        ar: 'تسجيل مستخدم جديد',
      );

  String get name => _t(en: 'Name', fa: 'نام کاربر', ar: 'اسم المستخدم');
  String get gender => _t(en: 'Gender', fa: 'جنسیت', ar: 'الجنس');
  String get dateOfBirth =>
      _t(en: 'Date of Birth', fa: 'تاریخ تولد', ar: 'تاريخ الميلاد');
  String get selectDateOfBirth => _t(
        en: 'Select your date of birth',
        fa: 'تاریخ تولد خود را انتخاب کنید',
        ar: 'اختر تاريخ ميلادك',
      );

  String get day => _t(en: 'Day', fa: 'روز', ar: 'اليوم');
  String get month => _t(en: 'Month', fa: 'ماه', ar: 'الشهر');
  String get year => _t(en: 'Year', fa: 'سال', ar: 'السنة');

  String get mobileNumber => _t(
        en: 'Mobile Number',
        fa: 'شماره تلفن همراه',
        ar: 'رقم الهاتف المحمول',
      );

  String get send => _t(en: 'Send', fa: 'ارسال', ar: 'إرسال');
  String get sentCode => _t(
        en: 'Sent Code',
        fa: 'کد ارسال شده',
        ar: 'الرمز المرسل',
      );

  String genderLabel(String value) {
    switch (value) {
      case 'male':
        return _t(en: 'Male', fa: 'مرد', ar: 'ذكر');
      case 'female':
        return _t(en: 'Female', fa: 'زن', ar: 'أنثى');
      case 'other':
        return _t(en: 'Other', fa: 'دیگر', ar: 'آخر');
      default:
        return selectGender;
    }
  }

  String get selectGender =>
      _t(en: 'Select gender', fa: 'انتخاب جنسیت', ar: 'اختر الجنس');

  String get nameRequired =>
      _t(en: 'Name is required', fa: 'نام الزامی است', ar: 'الاسم مطلوب');

  String get genderRequired => _t(
        en: 'Please select gender',
        fa: 'لطفاً جنسیت را انتخاب کنید',
        ar: 'يرجى اختيار الجنس',
      );

  String get dobRequired => _t(
        en: 'Please select date of birth',
        fa: 'لطفاً تاریخ تولد را انتخاب کنید',
        ar: 'يرجى اختيار تاريخ الميلاد',
      );

  String get invalidPhone => _t(
        en: 'Enter a valid phone number',
        fa: 'شماره تلفن معتبر وارد کنید',
        ar: 'أدخل رقم هاتف صالحًا',
      );

  String get otpIncomplete => _t(
        en: 'Please enter the 6-digit code.',
        fa: 'لطفاً کد ۶ رقمی را وارد کنید.',
        ar: 'يرجى إدخال الرمز المكون من 6 أرقام.',
      );

  String get userIdMissing => _t(
        en: 'User ID is missing in verification response.',
        fa: 'شناسه کاربر در پاسخ تأیید یافت نشد.',
        ar: 'معرف المستخدم مفقود في استجابة التحقق.',
      );

  String get pleaseWait =>
      _t(en: 'Please wait...', fa: 'لطفاً صبر کنید...', ar: 'يرجى الانتظار...');

  String get networkError => _t(
        en: 'Connection lost. Please check your internet and try again.',
        fa:
            'اتصال قطع شد. لطفاً اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.',
        ar: 'انقطع الاتصال. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.',
      );

  String get serverUnavailable => _t(
        en: 'Sedi server is currently unavailable. Please try again in a few minutes.',
        fa:
            'سرور صدی در حال حاضر در دسترس نیست. لطفاً چند دقیقه دیگر دوباره تلاش کنید.',
        ar: 'خادم Sedi غير متاح حاليًا. يرجى المحاولة مرة أخرى بعد بضع دقائق.',
      );

  String get tooManyOtp => _t(
        en: 'Too many requests. Please wait a few minutes and try again.',
        fa:
            'درخواست‌های زیاد. لطفاً چند دقیقه صبر کنید و دوباره تلاش کنید.',
        ar: 'طلبات كثيرة. يرجى الانتظار بضع دقائق والمحاولة مرة أخرى.',
      );

  String get profileSyncFailed => _t(
        en: 'Could not save your profile on the server. Please try again.',
        fa: 'ذخیره پروفایل روی سرور انجام نشد. لطفاً دوباره تلاش کنید.',
        ar: 'تعذر حفظ ملفك الشخصي على الخادم. يرجى المحاولة مرة أخرى.',
      );

  String get languageSyncFailed => _t(
        en:
            'Could not save your language preference. Please try again before continuing.',
        fa:
            'ذخیره زبان انتخابی انجام نشد. لطفاً قبل از ادامه دوباره تلاش کنید.',
        ar:
            'تعذر حفظ تفضيل اللغة. يرجى المحاولة مرة أخرى قبل المتابعة.',
      );

  String get profileFetchFailed => _t(
        en: 'Could not load your profile from the server. Please try again.',
        fa: 'بارگذاری پروفایل از سرور انجام نشد. لطفاً دوباره تلاش کنید.',
        ar: 'تعذر تحميل ملفك الشخصي من الخادم. يرجى المحاولة مرة أخرى.',
      );

  String get profileParseFailed => _t(
        en: 'Profile data from the server could not be read. Please try again.',
        fa: 'اطلاعات پروفایل از سرور قابل خواندن نبود. لطفاً دوباره تلاش کنید.',
        ar: 'تعذر قراءة بيانات الملف الشخصي من الخادم. يرجى المحاولة مرة أخرى.',
      );

  String get sessionAuthFailed => _t(
        en: 'Your session could not be confirmed. Please verify the code again.',
        fa: 'نشست شما تأیید نشد. لطفاً دوباره کد را تأیید کنید.',
        ar: 'تعذر تأكيد جلستك. يرجى التحقق من الرمز مرة أخرى.',
      );

  String get profileIncomplete => _t(
        en: 'Profile data was not confirmed by the server.',
        fa: 'اطلاعات پروفایل از سمت سرور تأیید نشد.',
        ar: 'لم يتم تأكيد بيانات الملف الشخصي من الخادم.',
      );

  String get back => _t(en: 'Back', fa: 'بازگشت', ar: 'رجوع');

  String get backToAccountChoice => _t(
        en: 'Back to account choice',
        fa: 'بازگشت به انتخاب حساب',
        ar: 'العودة إلى اختيار الحساب',
      );

  String get changePhoneNumber => _t(
        en: 'Change phone number',
        fa: 'تغییر شماره همراه',
        ar: 'تغيير رقم الهاتف',
      );

  String get phoneVerifiedLabel => _t(
        en: 'Phone number verified',
        fa: 'شماره همراه تأیید شد',
        ar: 'تم التحقق من رقم الهاتف',
      );

  String get completeRegistration => _t(
        en: 'Complete registration',
        fa: 'تکمیل ثبت‌نام',
        ar: 'إكمال التسجيل',
      );

  String get continueToAccount => _t(
        en: 'Continue to account',
        fa: 'ادامه با این حساب',
        ar: 'المتابعة إلى الحساب',
      );

  String get returningProfileIncompleteMessage => _t(
        en:
            'Your phone number is verified, but your Sedi profile is not completed yet. You can complete registration now.',
        fa:
            'شماره همراه شما تأیید شد، اما پروفایل صدی هنوز کامل نشده است. می‌توانید ثبت‌نام را تکمیل کنید.',
        ar:
            'تم التحقق من رقم هاتفك، لكن ملفك الشخصي في صدي غير مكتمل بعد. يمكنك إكمال التسجيل الآن.',
      );

  String get newUserAlreadyRegisteredMessage => _t(
        en:
            'This phone number is already registered in Sedi. You can continue with this account.',
        fa:
            'این شماره همراه قبلاً در صدی ثبت شده است. می‌توانید با همین حساب ادامه دهید.',
        ar:
            'رقم الهاتف هذا مسجل بالفعل في صدي. يمكنك المتابعة بهذا الحساب.',
      );

  String get codeSentGeneric => _t(
        en: 'Verification code sent. Please check your messages.',
        fa: 'کد تأیید ارسال شد. لطفاً پیام‌های خود را بررسی کنید.',
        ar: 'تم إرسال رمز التحقق. يرجى التحقق من رسائلك.',
      );

  String get otpEnterAfterSend => _t(
        en: 'Enter the 6-digit code here after you tap Send.',
        fa: 'پس از زدن «ارسال»، کد ۶ رقمی را اینجا وارد کنید.',
        ar: 'بعد الضغط على «إرسال»، أدخل الرمز المكون من 6 أرقام هنا.',
      );

  String get otpVerificationInstruction => _t(
        en: 'Enter the 6-digit verification code sent to your phone.',
        fa: 'کد تأیید ۶ رقمی ارسال‌شده به گوشی خود را وارد کنید.',
        ar: 'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى هاتفك.',
      );

  String get backToRegistration => _t(
        en: 'Back to registration',
        fa: 'بازگشت به ثبت‌نام',
        ar: 'العودة إلى التسجيل',
      );

  String get genericOtpRequestFailed => _t(
        en: 'Could not send the verification code. Please try again.',
        fa: 'ارسال کد تأیید انجام نشد. لطفاً دوباره تلاش کنید.',
        ar: 'تعذر إرسال رمز التحقق. يرجى المحاولة مرة أخرى.',
      );

  String get genericOtpVerifyFailed => _t(
        en: 'Invalid or expired verification code. Please try again.',
        fa: 'کد تأیید نامعتبر یا منقضی است. لطفاً دوباره تلاش کنید.',
        ar: 'رمز التحقق غير صالح أو منتهٍ. يرجى المحاولة مرة أخرى.',
      );

  String get accountNotFoundCreateAccount => _t(
        en: 'Account not found. Create an account to continue.',
        fa: 'حساب کاربری یافت نشد. برای ادامه حساب بسازید.',
        ar: 'لم يتم العثور على الحساب. أنشئ حسابًا للمتابعة.',
      );

  String get accountExistsHaveAccount => _t(
        en: 'Account already exists. Use Have account to sign in.',
        fa: 'حساب کاربری وجود دارد. برای ورود گزینه حساب دارم را انتخاب کنید.',
        ar: 'الحساب موجود بالفعل. استخدم لدي حساب لتسجيل الدخول.',
      );

  String get otpInvalid => _t(
        en: 'The verification code is invalid. Please try again.',
        fa: 'کد تأیید نامعتبر است. لطفاً دوباره تلاش کنید.',
        ar: 'رمز التحقق غير صالح. يرجى المحاولة مرة أخرى.',
      );

  String get otpExpired => _t(
        en: 'The verification code has expired. Please request a new one.',
        fa: 'کد تأیید منقضی شده است. لطفاً دوباره درخواست کنید.',
        ar: 'انتهت صلاحية رمز التحقق. يرجى طلب رمز جديد.',
      );

  String formatDay(int day) => _formatNumber(day, minDigits: 2);
  String formatYear(int year) => _formatNumber(year, minDigits: 4);

  String _formatNumber(int value, {required int minDigits}) {
    final s = value.toString().padLeft(minDigits, '0');
    if (lang == 'fa') return _toPersianDigits(s);
    if (lang == 'ar') return _toArabicDigits(s);
    return s;
  }

  String _toPersianDigits(String input) {
    const map = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };
    return input.split('').map((c) => map[c] ?? c).join();
  }

  String _toArabicDigits(String input) {
    const map = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return input.split('').map((c) => map[c] ?? c).join();
  }

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
