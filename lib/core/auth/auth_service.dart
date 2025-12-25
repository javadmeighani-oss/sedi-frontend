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

  // User credentials for backend authentication
  static const String _userNameKey = 'user_name';
  static const String _secretKeyKey = 'user_secret_key';

  /// دریافت نام کاربر
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      return null;
    }
  }

  /// ذخیره نام کاربر
  static Future<bool> setUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userNameKey, userName);
    } catch (e) {
      return false;
    }
  }

  /// دریافت secret key کاربر
  static Future<String?> getSecretKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_secretKeyKey);
    } catch (e) {
      return null;
    }
  }

  /// ذخیره secret key کاربر
  static Future<bool> setSecretKey(String secretKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_secretKeyKey, secretKey);
    } catch (e) {
      return false;
    }
  }

  /// پاک کردن اطلاعات کاربر (logout)
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userNameKey);
      await prefs.remove(_secretKeyKey);
      await clearToken();
      return true;
    } catch (e) {
      return false;
    }
  }
}
