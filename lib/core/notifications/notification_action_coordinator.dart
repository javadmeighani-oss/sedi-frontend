/// A4 Smart Notification action lifecycle coordinator.
///
/// Shared by Android tray actions, body taps, and Inbox detail recovery.
/// Contract: persist pending → authenticated backend feedback → on ACK only:
/// remove pending, dismiss local tray, refresh Inbox/badge, and (for open_chat)
/// navigate to A3 once. On failure keep pending + tray; retry on resume/start.

import 'package:flutter/foundation.dart';

import '../../data/repositories/notification_repository.dart';
import '../../services/notifications/inbox_refresh_bus.dart';
import '../navigation/app_gate_router.dart';
import '../navigation/app_navigator.dart';
import '../navigation/session_gate_resolver.dart';
import 'local_notifications_service.dart';
import 'pending_notification_actions.dart';

class NotificationActionCoordinator {
  NotificationActionCoordinator._();

  /// Session-local open_chat navigation dedupe (feedback durability uses pending).
  static final Set<int> _openChatNavigatedIds = <int>{};
  static const int _maxNavDedup = 50;
  static bool _draining = false;

  /// Canonical action seam used by tray body tap, action buttons, and Inbox.
  /// Returns true only when this action received backend ACK.
  static Future<bool> submit({
    required int notificationId,
    required String actionId,
    String? clientTs,
    bool navigateOnOpenChat = true,
  }) async {
    if (notificationId <= 0) return false;
    final action = actionId.trim();
    if (action.isEmpty) return false;

    final ts = clientTs ?? DateTime.now().toUtc().toIso8601String();
    await PendingNotificationActions.enqueue(
      notificationId: notificationId,
      actionId: action,
      clientTs: ts,
    );

    final hasSession = await SessionGateResolver.hasValidSession();
    if (!hasSession) return false;

    final item = PendingNotificationAction(
      notificationId: notificationId,
      actionId: action,
      clientTs: ts,
    );
    return _ackOne(item, navigateOnOpenChat: navigateOnOpenChat);
  }

  /// Drain all pending actions. Safe to call on start/resume/after enqueue.
  static Future<void> drainPendingActions({
    bool navigateOnOpenChat = true,
  }) async {
    if (_draining) return;
    _draining = true;
    try {
      final hasSession = await SessionGateResolver.hasValidSession();
      if (!hasSession) return;

      await PendingNotificationActions.drain((item) async {
        return _ackOne(item, navigateOnOpenChat: navigateOnOpenChat);
      });
    } catch (e) {
      debugPrint('[FCM] drainPendingActions error: $e');
    } finally {
      _draining = false;
    }
  }

  static Future<bool> _ackOne(
    PendingNotificationAction item, {
    required bool navigateOnOpenChat,
  }) async {
    try {
      final repo = NotificationRepository();
      final resp = await repo.sendFeedback(
        notificationId: item.notificationId,
        action: item.actionId,
        clientTs: item.clientTs,
      );
      if (!resp.ok) return false;

      await PendingNotificationActions.remove(
        notificationId: item.notificationId,
        actionId: item.actionId,
      );
      await LocalNotificationsService.cancelByBackendNotificationId(
        item.notificationId,
      );
      InboxRefreshBus.instance.triggerDebounced();
      if (navigateOnOpenChat && item.actionId == 'open_chat') {
        await navigateToChatAfterAck(notificationId: item.notificationId);
      }
      return true;
    } catch (e) {
      debugPrint('[FCM] action ACK failed: $e');
      return false;
    }
  }

  static Future<void> navigateToChatAfterAck({int? notificationId}) async {
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

  @visibleForTesting
  static void resetNavDedupeForTest() {
    _openChatNavigatedIds.clear();
  }
}
