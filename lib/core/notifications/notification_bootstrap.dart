import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../navigation/app_gate_router.dart';
import '../navigation/session_gate_resolver.dart';
import '../navigation/app_navigator.dart';
import 'fcm_setup.dart';
import 'local_notifications_service.dart';
import 'pending_notification_actions.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/notifications/inbox_refresh_bus.dart';
import '../../services/push/push_service.dart';

/// A4 notification / FCM bootstrap — presentation/interaction only.
class NotificationBootstrap {
  NotificationBootstrap._();

  /// Session-local open_chat navigation dedupe (feedback durability uses pending queue).
  static final Set<int> _openChatNavigatedIds = <int>{};
  static const int _maxNavDedup = 50;
  static bool _draining = false;

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
      _navigateToChatFromMessage(message);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        InboxRefreshBus.instance.triggerDebounced();
        _navigateToChatFromMessage(initialMessage);
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
      await PendingNotificationActions.enqueue(
        notificationId: id,
        actionId: action,
      );
      // Navigate for open_chat after session check (same as foreground path).
      if (action == 'open_chat') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToChat(notificationId: id);
        });
      }
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

    // Body tap → same open_chat seam.
    final action = (actionId == null || actionId.isEmpty) ? 'open_chat' : actionId;

    // Persist then drain so process-death / slow network remain correct.
    // ignore: discarded_futures
    PendingNotificationActions.enqueue(
      notificationId: notificationId,
      actionId: action,
    ).then((_) => drainPendingActions());

    InboxRefreshBus.instance.triggerDebounced();

    if (action == 'open_chat') {
      _navigateToChat(notificationId: notificationId);
    }
  }

  static Future<void> drainPendingActions() async {
    if (_draining) return;
    _draining = true;
    try {
      final hasSession = await SessionGateResolver.hasValidSession();
      if (!hasSession) return;

      final repo = NotificationRepository();
      await PendingNotificationActions.drain((item) async {
        final resp = await repo.sendFeedback(
          notificationId: item.notificationId,
          action: item.actionId,
          clientTs: item.clientTs,
        );
        return resp.ok;
      });
    } catch (e) {
      debugPrint('[FCM] drainPendingActions error: $e');
    } finally {
      _draining = false;
    }
  }

  static void _navigateToChatFromMessage(RemoteMessage message) {
    final data = message.data;
    final notificationIdStr = data['notification_id']?.toString() ??
        data['source_notification_id']?.toString();
    final notificationId = int.tryParse(notificationIdStr ?? '');
    final id = (notificationId ?? 0) > 0 ? notificationId : null;
    InboxRefreshBus.instance.triggerDebounced();
    if (id != null) {
      // ignore: discarded_futures
      PendingNotificationActions.enqueue(
        notificationId: id,
        actionId: 'open_chat',
      ).then((_) => drainPendingActions());
    }
    _navigateToChat(notificationId: id);
  }

  static Future<void> _navigateToChat({int? notificationId}) async {
    if (notificationId != null && notificationId > 0) {
      if (_openChatNavigatedIds.contains(notificationId)) return;
      _openChatNavigatedIds.add(notificationId);
      if (_openChatNavigatedIds.length > _maxNavDedup) {
        _openChatNavigatedIds.remove(_openChatNavigatedIds.first);
      }
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final hasSession = await SessionGateResolver.hasValidSession();
    if (!context.mounted) return;

    if (!hasSession) {
      AppGateRouter.goToLogin(context);
      return;
    }

    AppGateRouter.goToHeart(
      context,
      fromNotification: true,
      notificationId: notificationId,
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
