/// پیام‌های چندزبانه برنامه
class AppMessages {
  /// پیام خوشامدگویی بر اساس زبان
  static String getWelcomeMessage(String language) {
    switch (language) {
      case 'fa':
        return 'سلام! من صدی هستم 😊\nچطور می‌تونم کمکت کنم؟';
      case 'ar':
        return 'مرحبا! أنا صدي 😊\nكيف يمكنني مساعدتك؟';
      case 'en':
      default:
        return 'Hello! I\'m Sedi 😊\nHow can I help you?';
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
}

