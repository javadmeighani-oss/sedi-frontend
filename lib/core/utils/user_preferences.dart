import 'package:shared_preferences/shared_preferences.dart';

/// مدیریت تنظیمات کاربر
class UserPreferences {
  static const String _userNameKey = 'user_name';
  static const String _userPasswordKey = 'user_password';
  static const String _userLanguageKey = 'user_language';
  static const String _isFirstTimeKey = 'is_first_time';
  
  /// بررسی اینکه آیا اولین بار است که کاربر وارد می‌شود
  static Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isFirstTimeKey) ?? true;
    } catch (e) {
      return true;
    }
  }
  
  /// تنظیم اینکه کاربر دیگر اولین بار نیست
  static Future<bool> setNotFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_isFirstTimeKey, false);
    } catch (e) {
      return false;
    }
  }
  
  /// ذخیره نام کاربر
  static Future<bool> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userNameKey, name);
    } catch (e) {
      return false;
    }
  }
  
  /// دریافت نام کاربر
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      return null;
    }
  }
  
  /// ذخیره رمز کاربر
  static Future<bool> saveUserPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userPasswordKey, password);
    } catch (e) {
      return false;
    }
  }
  
  /// دریافت رمز کاربر
  static Future<String?> getUserPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userPasswordKey);
    } catch (e) {
      return null;
    }
  }
  
  /// ذخیره زبان کاربر
  static Future<bool> saveUserLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userLanguageKey, language);
    } catch (e) {
      return false;
    }
  }
  
  /// دریافت زبان کاربر
  static Future<String> getUserLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userLanguageKey) ?? 'en';
    } catch (e) {
      return 'en';
    }
  }
  
  /// بررسی رمز کاربر
  static Future<bool> verifyPassword(String password) async {
    try {
      final savedPassword = await getUserPassword();
      return savedPassword == password;
    } catch (e) {
      return false;
    }
  }
}

