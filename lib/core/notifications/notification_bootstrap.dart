import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'fcm_setup.dart';
import 'local_notifications_service.dart';
import 'notification_action_coordinator.dart';
import 'pending_notification_actions.dart';
import '../../services/notifications/inbox_refresh_bus.dart';
import '../../services/push/push_service.dart';

/// A4 notification / FCM bootstrap — presentation/interaction only.
class NotificationBootstrap {
  NotificationBootstrap._();

  static Future<void> setup() async {
    debugPrint('[FCM] setup start');
    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] permission status: ${permission.authorizationStatus}');

    await LocalNotificationsService.init(
      onResponse: _handleNotificationResponse,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LocalNotificationsService.showRemoteNotification(message);
      InboxRefreshBus.instance.triggerDebounced();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      InboxRefreshBus.instance.triggerDebounced();
      _openChatFromMessage(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        InboxRefreshBus.instance.triggerDebounced();
        _openChatFromMessage(initialMessage);
      });
    }

    // Local-notification terminated launch (Gate4 data-only path).
    await _recoverLocalNotificationLaunch();

    // Drain any pending actions from background/terminated taps.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      drainPendingActions();
    });

    _registerTokenOnStart();
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      debugPrint('[FCM] onTokenRefresh fired: ${_maskToken(newToken)}');
      _registerTokenOnStart();
    });
  }

  /// Call on app resume to retry transient feedback failures.
  static Future<void> onAppResumed() => drainPendingActions();

  static Future<void> drainPendingActions() =>
      NotificationActionCoordinator.drainPendingActions();

  static Future<void> _recoverLocalNotificationLaunch() async {
    try {
      final details =
          await LocalNotificationsService.getNotificationAppLaunchDetails();
      if (details == null || details.didNotificationLaunchApp != true) return;
      final response = details.notificationResponse;
      if (response == null) return;
      final payload = parseNotificationPayload(response.payload);
      if (payload == null) return;
      final id = int.tryParse(payload['notification_id']?.toString() ?? '');
      if (id == null || id <= 0) return;
      final action = (response.actionId == null || response.actionId!.isEmpty)
          ? 'open_chat'
          : response.actionId!;
      // Persist only — navigate/dismiss after backend ACK via drain.
      await PendingNotificationActions.enqueue(
        notificationId: id,
        actionId: action,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        drainPendingActions();
      });
    } catch (e) {
      debugPrint('[FCM] local launch recover failed: $e');
    }
  }

  static void _handleNotificationResponse(
    String? actionId,
    String? payloadJson,
  ) {
    final payload = parseNotificationPayload(payloadJson);
    if (payload == null) return;

    final notificationIdStr = payload['notification_id']?.toString();
    if (notificationIdStr == null || notificationIdStr.isEmpty) return;

    final notificationId = int.tryParse(notificationIdStr);
    if (notificationId == null) return;

    // Body tap → same open_chat seam as Talk to Sedi.
    final action =
        (actionId == null || actionId.isEmpty) ? 'open_chat' : actionId;

    // Persist then drain. Navigate/dismiss ONLY after backend ACK.
    // ignore: discarded_futures
    NotificationActionCoordinator.submit(
      notificationId: notificationId,
      actionId: action,
      payloadJson: payloadJson,
      showTrayProcessing: true,
    );
  }

  static void _openChatFromMessage(RemoteMessage message) {
    final data = message.data;
    final notificationIdStr = data['notification_id']?.toString() ??
        data['source_notification_id']?.toString();
    final notificationId = int.tryParse(notificationIdStr ?? '');
    final id = (notificationId ?? 0) > 0 ? notificationId : null;
    InboxRefreshBus.instance.triggerDebounced();
    if (id == null) return;
    // Same ACK-before-nav seam as tray body tap / open_chat action.
    // ignore: discarded_futures
    NotificationActionCoordinator.submit(
      notificationId: id,
      actionId: 'open_chat',
    );
  }

  static String _maskToken(String t) {
    if (t.length <= 10) return '***';
    return '${t.substring(0, 6)}...${t.substring(t.length - 4)}';
  }

  static Future<void> _registerTokenOnStart() async {
    try {
      debugPrint('[FCM] getToken() called');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      debugPrint('[FCM] token acquired (masked): ${_maskToken(token)}');
      debugPrint('[FCM] saving token to prefs');
      await saveTokenToPreferences(token);
      debugPrint('[FCM] saved token to prefs');
      debugPrint('[FCM] registerFcmTokenToBackend() called');
      final res = await registerFcmTokenToBackend(token);
      debugPrint(
          '[FCM] register result: status=${res.statusCode ?? '?'} ok=${res.ok}');
    } catch (e) {
      debugPrint('[FCM] Token register error: $e');
    }
  }
}
