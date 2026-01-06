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
      print('[UserProfileManager] ========== LOAD PROFILE START ==========');
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson == null) {
        print('[UserProfileManager] No profile found, returning empty profile');
        print('[UserProfileManager] ========== LOAD PROFILE END ==========');
        return UserProfile(); // Return empty profile
      }

      print('[UserProfileManager] Profile JSON found: $profileJson');
      final json = jsonDecode(profileJson) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(json);
      
      print('[UserProfileManager] Loaded profile:');
      print('[UserProfileManager]   - name: "${profile.name}"');
      print('[UserProfileManager]   - userId: ${profile.userId}');
      print('[UserProfileManager]   - language: ${profile.preferredLanguage}');
      print('[UserProfileManager]   - hasSecurityPassword: ${profile.hasSecurityPassword}');
      print('[UserProfileManager]   - isVerified: ${profile.isVerified}');
      print('[UserProfileManager] ========== LOAD PROFILE END ==========');
      
      return profile;
    } catch (e, stackTrace) {
      print('[UserProfileManager] ❌ ERROR loading profile: $e');
      print('[UserProfileManager] Stack trace: $stackTrace');
      print('[UserProfileManager] Returning empty profile');
      return UserProfile(); // Return empty profile on error
    }
  }

  /// Save user profile to storage
  static Future<bool> saveProfile(UserProfile profile) async {
    try {
      print('[UserProfileManager] ========== SAVE PROFILE START ==========');
      print('[UserProfileManager] Profile to save:');
      print('[UserProfileManager]   - name: "${profile.name}"');
      print('[UserProfileManager]   - userId: ${profile.userId}');
      print('[UserProfileManager]   - language: ${profile.preferredLanguage}');
      print('[UserProfileManager]   - hasSecurityPassword: ${profile.hasSecurityPassword}');
      print('[UserProfileManager]   - isVerified: ${profile.isVerified}');
      
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toJson());
      print('[UserProfileManager] JSON to save: $json');
      
      final result = await prefs.setString(_profileKey, json);
      print('[UserProfileManager] Save result: $result');
      
      // Verify save
      final savedJson = prefs.getString(_profileKey);
      if (savedJson != null) {
        print('[UserProfileManager] ✅ Profile saved successfully');
        print('[UserProfileManager] Saved JSON: $savedJson');
      } else {
        print('[UserProfileManager] ❌ ERROR: Profile not found after save!');
      }
      
      print('[UserProfileManager] ========== SAVE PROFILE END ==========');
      return result;
    } catch (e, stackTrace) {
      print('[UserProfileManager] ❌ ERROR saving profile: $e');
      print('[UserProfileManager] Stack trace: $stackTrace');
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

