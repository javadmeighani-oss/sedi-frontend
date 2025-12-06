class AppConfig {
  /// آدرس بک‌اند (در صورت لزوم با IP لوکال جایگزین شود)
  static const String baseUrl = "http://91.107.168.130:8000";

  /// اجرای لوکال با پاسخ‌های Mock => true
  /// اتصال به بک‌اند واقعی => false
  static const bool useLocalMode = false;
}
