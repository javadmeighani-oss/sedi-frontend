import 'brand_name.dart';

/// پیام‌های چندزبانه برنامه
class AppMessages {
  /// پیام خوشامدگویی بر اساس زبان (نام برند از brand_name)
  static String getWelcomeMessage(String language) {
    final brand = sediBrandName(language);
    switch (language) {
      case 'fa':
        return 'سلام! من $brand هستم 😊\nچطور می‌تونم کمکت کنم؟';
      case 'ar':
        return 'مرحبا! أنا $brand 😊\nكيف يمكنني مساعدتك؟';
      case 'en':
      default:
        return 'Hello! I\'m $brand 😊\nHow can I help you?';
    }
  }
  
  /// پیام درخواست نام
  static String getNameRequest(String language) {
    switch (language) {
      case 'fa':
        return 'لطفاً نام خود را وارد کنید:';
      case 'ar':
        return 'يرجى إدخال اسمك:';
      case 'en':
      default:
        return 'Please enter your name:';
    }
  }
  
  /// پیام درخواست رمز
  static String getPasswordRequest(String language) {
    switch (language) {
      case 'fa':
        return 'لطفاً یک کلمه یا جمله برای رمز ورود انتخاب کنید:';
      case 'ar':
        return 'يرجى اختيار كلمة أو جملة ككلمة مرور:';
      case 'en':
      default:
        return 'Please choose a word or phrase as your password:';
    }
  }
  
  /// پیام تایید ورود
  static String getWelcomeBack(String language, String name) {
    switch (language) {
      case 'fa':
        return 'خوش برگشتید $name! 😊';
      case 'ar':
        return 'مرحباً بعودتك $name! 😊';
      case 'en':
      default:
        return 'Welcome back $name! 😊';
    }
  }

  // --- Get-to-know-you onboarding (Stage 24 UX Pack 02) ---

  static String getPreferredNameLabel(String language) {
    switch (language) {
      case 'fa':
        return 'نام دلخواه';
      case 'ar':
        return 'الاسم المفضل';
      case 'en':
      default:
        return 'Preferred name';
    }
  }

  static String getLanguageLabel(String language) {
    switch (language) {
      case 'fa':
        return 'زبان';
      case 'ar':
        return 'اللغة';
      case 'en':
      default:
        return 'Language';
    }
  }

  static String getGoalsLabel(String language) {
    switch (language) {
      case 'fa':
        return 'اهداف (حداکثر ۳)';
      case 'ar':
        return 'الأهداف (٣ كحد أقصى)';
      case 'en':
      default:
        return 'Goals (up to 3)';
    }
  }

  static String getLanguageAuto(String language) {
    switch (language) {
      case 'fa':
        return 'خودکار';
      case 'ar':
        return 'تلقائي';
      case 'en':
      default:
        return 'Auto';
    }
  }

  static String getGoalBetterSleep(String lang) {
    switch (lang) {
      case 'fa': return 'خواب بهتر';
      case 'ar': return 'نوم أفضل';
      default: return 'Better sleep';
    }
  }

  static String getGoalLessStress(String lang) {
    switch (lang) {
      case 'fa': return 'کمتر استرس';
      case 'ar': return 'توتر أقل';
      default: return 'Less stress';
    }
  }

  static String getGoalReducePain(String lang) {
    switch (lang) {
      case 'fa': return 'کاهش درد';
      case 'ar': return 'تقليل الألم';
      default: return 'Reduce pain';
    }
  }

  static String getGoalMoreEnergy(String lang) {
    switch (lang) {
      case 'fa': return 'انرژی بیشتر';
      case 'ar': return 'طاقة أكثر';
      default: return 'More energy';
    }
  }

  static String getGoalWeightManagement(String lang) {
    switch (lang) {
      case 'fa': return 'مدیریت وزن';
      case 'ar': return 'إدارة الوزن';
      default: return 'Weight management';
    }
  }

  static String getGoalHealthyHabits(String lang) {
    switch (lang) {
      case 'fa': return 'عادت‌های سالم';
      case 'ar': return 'عادات صحية';
      default: return 'Healthy habits';
    }
  }
}

