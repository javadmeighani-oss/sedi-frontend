import '../../../../core/locale/sedi_locale_controller.dart';

/// Gadgets / Devices presentation strings (en/fa/ar). Locale from SediLocaleController.
class DevicesL10n {
  final String lang;
  DevicesL10n([String? languageCode])
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

  String get title => _t(en: 'Gadgets', fa: 'گجت‌ها', ar: 'الأجهزة');
  String get myGadgets =>
      _t(en: 'My gadgets', fa: 'گجت‌های من', ar: 'أجهزتي');
  String get otherGadgets =>
      _t(en: 'Other gadgets', fa: 'گجت‌های دیگر', ar: 'أجهزة أخرى');
  String get unclassified =>
      _t(en: 'Unclassified', fa: 'طبقه‌بندی‌نشده', ar: 'غير مصنف');
  String get noGadgets =>
      _t(en: 'No gadgets', fa: 'گجتی نیست', ar: 'لا أجهزة');
  // ---- pilot V1 (R-034): Sedi's own specialised gadgets ----
  String get specialTitle => _t(
        en: "Sedi's specialised gadgets",
        fa: 'گجت‌های تخصصی صدی',
        ar: 'أجهزة صدی المتخصصة',
      );
  String get specialBody => _t(
        en: 'The gadgets in development belong only to Sedi and are made to care for you. For now the heart-rate gadget is being built; when it is ready you connect it right here.',
        fa: 'گجت‌هایی که در حال توسعه‌اند فقط مال صدی‌ان و برای مراقبت از تو ساخته می‌شن. فعلاً گجت ضربان قلب در دست ساخته؛ وقتی آماده شد، همین‌جا وصلش می‌کنی.',
        ar: 'الأجهزة قيد التطوير تخص صدی وحده وتُصنع للعناية بك. حاليًا يجري تطوير جهاز نبض القلب، وعندما يصبح جاهزًا تربطه هنا.',
      );

  String get active => _t(en: 'Active', fa: 'فعال', ar: 'نشط');
  String get revoked => _t(en: 'Revoked', fa: 'باطل‌شده', ar: 'ملغى');
  String get rename => _t(en: 'Rename', fa: 'تغییر نام', ar: 'إعادة تسمية');
  String get save => _t(en: 'Save', fa: 'ذخیره', ar: 'حفظ');
  String get cancel => _t(en: 'Cancel', fa: 'لغو', ar: 'إلغاء');
  String get category => _t(en: 'Category', fa: 'دسته‌بندی', ar: 'الفئة');
  String get selfCategory => _t(en: 'SELF', fa: 'SELF', ar: 'SELF');
  String get otherCategory => _t(en: 'OTHER', fa: 'OTHER', ar: 'OTHER');
  String get labelHint => _t(
        en: 'Label (required for OTHER)',
        fa: 'برچسب (برای OTHER لازم است)',
        ar: 'التسمية (مطلوبة لـ OTHER)',
      );
  String get pleaseWait =>
      _t(en: 'Please wait.', fa: 'لطفاً صبر کنید.', ar: 'يرجى الانتظار.');
  String get connectComingSoon => _t(
        en: 'Connect (coming soon)',
        fa: 'اتصال (به‌زودی)',
        ar: 'اتصال (قريباً)',
      );
  String get connect => _t(en: 'Connect', fa: 'اتصال', ar: 'اتصال');
  String get disconnect => _t(en: 'Disconnect', fa: 'قطع اتصال', ar: 'قطع');
  String get scanning => _t(en: 'Scanning…', fa: 'در حال جستجو…', ar: 'جارٍ البحث…');
  String get setupCodeHint => _t(
        en: '4-digit Setup Code',
        fa: 'کد راه‌اندازی ۴ رقمی',
        ar: 'رمز الإعداد المكوّن من 4 أرقام',
      );
  String get selectDevice =>
      _t(en: 'Select gadget', fa: 'انتخاب گجت', ar: 'اختر الجهاز');
  String get bleConnected =>
      _t(en: 'Connected', fa: 'متصل', ar: 'متصل');
  String get bleConnecting =>
      _t(en: 'Connecting', fa: 'در حال اتصال', ar: 'جارٍ الاتصال');
  String get bleReconnecting =>
      _t(en: 'Reconnecting', fa: 'اتصال مجدد', ar: 'إعادة الاتصال');
  String get bleOutOfRange =>
      _t(en: 'Out of range', fa: 'خارج محدوده', ar: 'خارج النطاق');
  String get bleDisconnected =>
      _t(en: 'Disconnected', fa: 'قطع‌شده', ar: 'غير متصل');
  String get battery => _t(en: 'Battery', fa: 'باتری', ar: 'البطارية');
  String get contact => _t(en: 'Contact', fa: 'تماس', ar: 'التلامس');
  String get contactOk =>
      _t(en: 'Contact OK', fa: 'تماس برقرار', ar: 'التلامس جيد');
  String get contactNotOk =>
      _t(en: 'No contact', fa: 'بدون تماس', ar: 'بدون تلامس');
  String get lastSync =>
      _t(en: 'Last sync', fa: 'آخرین همگام‌سازی', ar: 'آخر مزامنة');
  String get neverSynced =>
      _t(en: 'Never', fa: 'هرگز', ar: 'أبداً');
  String get permissionDenied => _t(
        en: 'Bluetooth permission is required to find gadgets.',
        fa: 'برای یافتن گجت‌ها اجازه بلوتوث لازم است.',
        ar: 'يلزم إذن البلوتوث للعثور على الأجهزة.',
      );
  String get permissionPermanentlyDenied => _t(
        en: 'Bluetooth permission is blocked. Open settings to allow it.',
        fa: 'اجازه بلوتوث مسدود است. از تنظیمات فعالش کنید.',
        ar: 'إذن البلوتوث محظور. فعّله من الإعدادات.',
      );
  String get presentationUpdated => _t(
        en: 'Presentation updated',
        fa: 'نمایش به‌روز شد',
        ar: 'تم تحديث العرض',
      );

  String transportLabel(String state) {
    switch (state) {
      case 'connected':
        return bleConnected;
      case 'connecting':
        return bleConnecting;
      case 'reconnecting':
        return bleReconnecting;
      case 'outOfRange':
        return bleOutOfRange;
      default:
        return bleDisconnected;
    }
  }

  String statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'revoked') return revoked;
    return active;
  }

  String contactLabel(bool ok) => ok ? contactOk : contactNotOk;

  String batteryLabel(int percent) => '${battery} $percent%';

  /// Human-readable relative last-sync — never raw ISO.
  String formatLastSync(DateTime? at, {DateTime? now}) {
    if (at == null) return '$lastSync: $neverSynced';
    final n = now ?? DateTime.now();
    final diff = n.difference(at.toLocal());
    final String rel;
    if (diff.inMinutes < 1) {
      rel = _t(en: 'Just now', fa: 'همین الان', ar: 'الآن');
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      rel = _t(
        en: '${m}m ago',
        fa: '$m دقیقه پیش',
        ar: 'منذ $m د',
      );
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      rel = _t(
        en: '${h}h ago',
        fa: '$h ساعت پیش',
        ar: 'منذ $h س',
      );
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      rel = _t(
        en: '${d}d ago',
        fa: '$d روز پیش',
        ar: 'منذ $d ي',
      );
    } else {
      final local = at.toLocal();
      rel = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    }
    return '$lastSync: $rel';
  }

  String permissionMessage(String? connectError) {
    if (connectError == 'BLE_PERMISSION_PERMANENTLY_DENIED') {
      return permissionPermanentlyDenied;
    }
    if (connectError == 'BLE_PERMISSION_DENIED') {
      return permissionDenied;
    }
    return connectError ?? noGadgets;
  }
}
