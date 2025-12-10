/// سرویس تشخیص زبان
/// 
/// این کلاس برای تشخیص زبان کاربر از روی متن استفاده می‌شود
class LanguageDetector {
  /// تشخیص زبان از روی متن
  /// 
  /// Returns: 'en' برای انگلیسی، 'fa' برای فارسی، 'ar' برای عربی
  static String detectLanguage(String text) {
    if (text.trim().isEmpty) return 'en';
    
    // تشخیص فارسی (کاراکترهای فارسی)
    final persianRegex = RegExp(r'[\u0600-\u06FF]');
    if (persianRegex.hasMatch(text)) {
      return 'fa';
    }
    
    // تشخیص عربی (کاراکترهای عربی)
    final arabicRegex = RegExp(r'[\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    if (arabicRegex.hasMatch(text)) {
      return 'ar';
    }
    
    // پیش‌فرض: انگلیسی
    return 'en';
  }
  
  /// بررسی اینکه آیا متن فارسی است
  static bool isPersian(String text) {
    return detectLanguage(text) == 'fa';
  }
  
  /// بررسی اینکه آیا متن عربی است
  static bool isArabic(String text) {
    return detectLanguage(text) == 'ar';
  }
  
  /// بررسی اینکه آیا متن انگلیسی است
  static bool isEnglish(String text) {
    return detectLanguage(text) == 'en';
  }
}

