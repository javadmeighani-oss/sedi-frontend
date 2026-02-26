import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// مدیریت تنظیمات کاربر
class UserPreferences {
  static const String _userNameKey = 'user_name';
  static const String _userPasswordKey = 'user_password';
  static const String _userLanguageKey = 'user_language';
  static const String _isFirstTimeKey = 'is_first_time';
  static const String _hasSeenIntroGreetingKey = 'has_seen_intro_greeting';

  // Get-to-know-you onboarding (Stage 24 UX Pack 02)
  static const String _preferredNameKey = 'preferred_name';
  static const String _languagePrefKey = 'language_pref'; // "auto"|"en"|"fa"|"ar"
  static const String _goalsKey = 'goals'; // JSON array of strings
  static const String _getToKnowYouCompletedKey = 'get_to_know_you_completed';
  
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
  
  /// Whether the user has seen the approved intro greeting (no duplicate on reopen).
  static Future<bool> hasSeenIntroGreeting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenIntroGreetingKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setHasSeenIntroGreeting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_hasSeenIntroGreetingKey, value);
    } catch (e) {
      return false;
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

  // --- Get-to-know-you onboarding (Stage 24 UX Pack 02) ---

  static Future<String?> getPreferredName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_preferredNameKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> savePreferredName(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_preferredNameKey, value.trim());
    } catch (e) {
      return false;
    }
  }

  static Future<String> getLanguagePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languagePrefKey) ?? 'auto';
    } catch (e) {
      return 'auto';
    }
  }

  static Future<bool> saveLanguagePref(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languagePrefKey, value);
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_goalsKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveGoals(List<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_goalsKey, jsonEncode(value));
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasCompletedGetToKnowYou() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_getToKnowYouCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setGetToKnowYouCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_getToKnowYouCompletedKey, value);
    } catch (e) {
      return false;
    }
  }
}

