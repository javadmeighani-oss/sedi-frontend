/// Push notification registration and feedback (Stage 16.6).
/// Uses ApiClient with auth headers.
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository({String? baseUrl, ApiClient? apiClient})
      : _client = apiClient ?? ApiClient(baseUrl: baseUrl ?? AppConfig.baseUrl);

  /// POST /notifications/push/register — register FCM token with backend
  Future<ApiResponse<Map<String, dynamic>?>> registerToken({
    required int userId,
    required String fcmToken,
    String? deviceId,
    String? appVersion,
  }) async {
    debugPrint('[FCM] registerToken => POST /notifications/push/register');
    return _client.post<Map<String, dynamic>?>(
      '/notifications/push/register',
      body: {
        'user_id': userId,
        'platform': 'android',
        'fcm_token': fcmToken,
        if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId,
        if (appVersion != null && appVersion.isNotEmpty) 'app_version': appVersion,
      },
      parser: (v) =>
          v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// POST /notifications/push/unregister — deactivate FCM token
  Future<ApiResponse<Map<String, dynamic>?>> unregisterToken({
    required int userId,
    required String fcmToken,
  }) async {
    return _client.post<Map<String, dynamic>?>(
      '/notifications/push/unregister',
      queryParams: {
        'user_id': userId.toString(),
        'fcm_token': fcmToken,
      },
      parser: (v) =>
          v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }

  /// POST /notifications/{id}/feedback — Stage 16.6 action-based feedback
  /// action: like | dislike | open_chat | dismissed
  ///
  /// [recoverSessionOn401] must be false from background isolates so a failed
  /// refresh never forces UI navigation / logout.
  /// Tray buttons of a nutrition / exercise plan follow-up ("did you do it?").
  static const Set<String> planFollowUpActions = {'done', 'plan_not_done', 'later'};

  Future<ApiResponse<Map<String, dynamic>?>> sendFeedback({
    required int notificationId,
    required String action,
    String? clientTs,
    Map<String, dynamic>? meta,
    String? reason,
    bool recoverSessionOn401 = true,
  }) async {
    final body = <String, dynamic>{
      'action': action,
      // P8: plan follow-up answers (done / plan_not_done / later) use the contract path the backend binds to the plan item.
      if (planFollowUpActions.contains(action)) ...{'reaction': 'interact', 'action_id': action},
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (clientTs != null) 'client_ts': clientTs,
      if (meta != null && meta.isNotEmpty) 'meta': meta,
    };
    return _client.post<Map<String, dynamic>?>(
      '/notifications/$notificationId/feedback',
      body: body,
      recoverSessionOn401: recoverSessionOn401,
      parser: (v) =>
          v == null ? null : Map<String, dynamic>.from(v as Map),
    );
  }
}
