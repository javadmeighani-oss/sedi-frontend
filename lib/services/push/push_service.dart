/// Push (FCM) token registration with backend.
/// Single entry point: registerFcmTokenToBackend(token).
/// Uses existing ApiClient via NotificationRepository; optionally stores token in preferences.
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_response.dart';
import '../../core/utils/user_profile_manager.dart';
import '../../data/repositories/notification_repository.dart';

const String _prefKeyFcmToken = 'fcm_token';

/// Stage 19.2: Ensure we only run ensureFcmRegisteredAfterLogin once per app session.
bool _didEnsureFcmAfterLogin = false;

String _maskToken(String t) {
  if (t.length <= 10) return '***';
  return '${t.substring(0, 6)}...${t.substring(t.length - 4)}';
}

/// Register the given FCM token with the backend (POST /notifications/push/register).
/// Requires a logged-in user (userId from UserProfileManager). Uses existing API client.
/// Returns ApiResponse for caller to log statusCode (Stage 19); ok indicates success.
Future<ApiResponse<Map<String, dynamic>?>> registerFcmTokenToBackend(String token) async {
  debugPrint('[FCM] registerFcmTokenToBackend enter');
  debugPrint('[FCM] baseUrl=${AppConfig.baseUrl}');
  if (token.isEmpty) {
    return ApiResponse(ok: false, statusCode: null);
  }
  try {
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    debugPrint('[FCM] userId(current)=$userId');
    if (userId == null) {
      debugPrint('[FCM] userId is null -> SKIP backend register (will retry after login)');
      return ApiResponse(ok: false, statusCode: null);
    }

    debugPrint('[FCM] calling NotificationRepository.registerToken(userId=$userId, platform=android, app_version=1.0.0)');
    final repo = NotificationRepository();
    final response = await repo.registerToken(
      userId: userId,
      fcmToken: token,
      appVersion: '1.0.0',
    );
    debugPrint('[FCM] repo.registerToken result: status=${response.statusCode ?? '?'} ok=${response.ok} error=${response.error?.message}');
    return response;
  } catch (e) {
    print('[PushService] registerFcmTokenToBackend error: $e');
    return ApiResponse(ok: false, statusCode: null);
  }
}

/// Optionally store FCM token in app preferences.
Future<void> saveTokenToPreferences(String? token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_prefKeyFcmToken);
    } else {
      await prefs.setString(_prefKeyFcmToken, token);
    }
  } catch (e) {
    print('[PushService] saveTokenToPreferences error: $e');
  }
}

/// Read stored FCM token from preferences (optional; may be stale after refresh).
Future<String?> getTokenFromPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyFcmToken);
  } catch (e) {
    print('[PushService] getTokenFromPreferences error: $e');
    return null;
  }
}

/// Guarantee: after login (userId persisted), always attempt to register FCM token (Stage 19.1).
/// Uses stored token from prefs, or fetches fresh via getToken() if none stored.
Future<void> ensureFcmRegisteredAfterLogin() async {
  try {
    if (_didEnsureFcmAfterLogin) {
      debugPrint('[FCM] ensure after login: already done this session -> skip');
      return;
    }
    debugPrint('[FCM] ensureFcmRegisteredAfterLogin enter');
    final profile = await UserProfileManager.loadProfile();
    final userId = profile.userId;
    debugPrint('[FCM] ensure after login userId=$userId');
    if (userId == null) {
      debugPrint('[FCM] ensure after login: userId still null -> abort');
      return;
    }

    String? token = await getTokenFromPreferences();
    if (token == null || token.trim().isEmpty) {
      debugPrint('[FCM] ensure after login: no stored token -> getToken()');
      final fresh = await FirebaseMessaging.instance.getToken();
      if (fresh == null || fresh.trim().isEmpty) {
        debugPrint('[FCM] ensure after login: getToken returned null/empty');
        return;
      }
      await saveTokenToPreferences(fresh);
      token = fresh;
      debugPrint('[FCM] ensure after login: token saved, registering...');
    } else {
      debugPrint('[FCM] ensure after login: found stored token ${_maskToken(token)} -> registering...');
    }
    await registerFcmTokenToBackend(token);
    _didEnsureFcmAfterLogin = true;
  } catch (e) {
    debugPrint('[FCM] ensure after login error: $e');
  }
}

/// Call after login/onboarding when profile (userId) has just been saved.
/// Delegates to ensureFcmRegisteredAfterLogin for guaranteed register attempt.
Future<void> tryRegisterStoredTokenAfterLogin() async {
  await ensureFcmRegisteredAfterLogin();
}
