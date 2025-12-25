/// ============================================
/// UserProfileManager - User Profile Persistence
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Save/load user profile from SharedPreferences
/// - Manage user information
/// ============================================

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_profile.dart';

class UserProfileManager {
  static const String _profileKey = 'user_profile';

  /// Load user profile from storage
  static Future<UserProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson == null) {
        return UserProfile(); // Return empty profile
      }

      final json = jsonDecode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      return UserProfile(); // Return empty profile on error
    }
  }

  /// Save user profile to storage
  static Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toJson());
      return await prefs.setString(_profileKey, json);
    } catch (e) {
      return false;
    }
  }

  /// Update profile with new values
  static Future<bool> updateProfile(UserProfile Function(UserProfile) updater) async {
    try {
      final current = await loadProfile();
      final updated = updater(current);
      return await saveProfile(updated);
    } catch (e) {
      return false;
    }
  }

  /// Clear profile (logout)
  static Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_profileKey);
    } catch (e) {
      return false;
    }
  }
}

