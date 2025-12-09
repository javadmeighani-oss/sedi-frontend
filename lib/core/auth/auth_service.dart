import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت احراز هویت
///
/// این کلاس برای مدیریت توکن احراز هویت کاربر استفاده می‌شود.
/// توکن در SharedPreferences ذخیره می‌شود.
class AuthService {
  static const String _tokenKey = 'auth_token';

  /// دریافت توکن احراز هویت
  ///
  /// Returns: توکن احراز هویت یا null در صورت عدم وجود
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      // در صورت خطا، null برمی‌گرداند
      return null;
    }
  }

  /// ذخیره توکن احراز هویت
  ///
  /// [token] توکن احراز هویت برای ذخیره
  /// Returns: true در صورت موفقیت، false در صورت خطا
  static Future<bool> setToken(String token) async {
    try {
      if (token.isEmpty) {
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  /// حذف توکن (خروج از حساب)
  ///
  /// Returns: true در صورت موفقیت، false در صورت خطا
  static Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokenKey);
    } catch (e) {
      return false;
    }
  }

  /// بررسی وجود توکن
  ///
  /// Returns: true اگر توکن وجود داشته باشد، false در غیر این صورت
  static Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
