/// A4 Smart Notification action lifecycle coordinator.
///
/// Shared by Android tray actions, body taps, and Inbox detail recovery.
/// Contract: persist pending → dismiss tray immediately → authenticated
/// backend feedback (silent retry). On ACK: remove pending, refresh
/// Inbox/badge. On failure keep pending and never restore the tray.
/// open_chat (Javad 2026-10-30): the user said "let's talk", so the chat opens AT ONCE (from the local token, no network
/// gate, retried until the navigator is ready); the reaction reaches the backend right after through the pending queue.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/repositories/notification_repository.dart';
import '../../services/notifications/inbox_refresh_bus.dart';
import '../auth/auth_service.dart';
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

  /// In-flight action keys (`notificationId|actionId`) — reject duplicate taps.
  static final Set<String> _inFlightKeys = <String>{};

  /// Canonical action seam used by tray body tap, action buttons, and Inbox.
  /// Returns true only when this action received backend ACK.
  static Future<bool> submit({
    required int notificationId,
    required String actionId,
    String? clientTs,
    bool navigateOnOpenChat = true,
    String? payloadJson,
    bool showTrayProcessing = true,
  }) async {
    if (notificationId <= 0) return false;
    final action = actionId.trim();
    if (action.isEmpty) return false;

    final key = '$notificationId|$action';
    if (_inFlightKeys.contains(key)) {
      debugPrint('[FCM] duplicate action rejected while processing: $key');
      return false;
    }
    _inFlightKeys.add(key);

    try {
      final ts = clientTs ?? DateTime.now().toUtc().toIso8601String();
      // Persist pending BEFORE network attempt.
      await PendingNotificationActions.enqueue(
        notificationId: notificationId,
        actionId: action,
        clientTs: ts,
      );

      // A4: dismiss tray immediately; never restore on ACK/network failure.
      // showTrayProcessing is ignored — tray must not linger for processing UX.
      await LocalNotificationsService.cancelByBackendNotificationId(
        notificationId,
      );

      // "Talk to Sedi": open the chat now - not after a network round trip that may be slow or fail.
      if (navigateOnOpenChat && action == 'open_chat') {
        unawaited(openChatNow(notificationId: notificationId));
      }

      final hasSession = await SessionGateResolver.hasValidSession();
      if (!hasSession) {
        // Pending retained; tray already dismissed; no restore.
        return false;
      }

      final item = PendingNotificationAction(
        notificationId: notificationId,
        actionId: action,
        clientTs: ts,
      );
      return await _ackOne(item, navigateOnOpenChat: false);
    } catch (e) {
      debugPrint('[FCM] submit error: $e');
      // Pending retained; tray already dismissed; no restore.
      return false;
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  /// Drain all pending actions. Safe to call on start/resume/after enqueue.
  static Future<void> drainPendingActions({
    bool navigateOnOpenChat = true,
  }) async {
    if (_draining) return;
    _draining = true;
    try {
      if (navigateOnOpenChat) {
        // A tap from the tray while the app was closed: it is waiting in the queue - open the chat first.
        final queued = await PendingNotificationActions.load();
        for (final item in queued) {
          if (item.actionId == 'open_chat' && isFreshTap(item.clientTs, DateTime.now())) {
            unawaited(openChatNow(notificationId: item.notificationId));
            break;
          }
        }
      }
      final hasSession = await SessionGateResolver.hasValidSession();
      if (!hasSession) return;

      await PendingNotificationActions.drain((item) async {
        final key = item.dedupeKey;
        if (_inFlightKeys.contains(key)) return false;
        _inFlightKeys.add(key);
        try {
          return await _ackOne(item, navigateOnOpenChat: false);
        } finally {
          _inFlightKeys.remove(key);
        }
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
      // Tray already dismissed on submit; ensure cancel remains idempotent.
      await LocalNotificationsService.cancelByBackendNotificationId(
        item.notificationId,
      );
      InboxRefreshBus.instance.triggerDebounced();
      if (navigateOnOpenChat && item.actionId == 'open_chat') {
        unawaited(openChatNow(notificationId: item.notificationId)); // deduped: a no-op when the tap already opened it
      }
      return true;
    } catch (e) {
      debugPrint('[FCM] action ACK failed: $e');
      return false;
    }
  }

  /// A tap younger than this is "the user just pressed Talk to Sedi"; an older queued one is only a late feedback retry
  /// and must never throw the user into the chat.
  static const Duration freshTapWindow = Duration(minutes: 2);

  static bool isFreshTap(String clientTs, DateTime now) {
    final at = DateTime.tryParse(clientTs);
    if (at == null) return false;
    final age = now.toUtc().difference(at.toUtc());
    return age >= Duration.zero ? age <= freshTapWindow : age.abs() <= freshTapWindow;
  }

  /// Kept for the A4 contract and its tests: the chat opens as soon as the user asks for it.
  static Future<void> navigateToChatAfterAck({int? notificationId}) => openChatNow(notificationId: notificationId);

  /// Opens A3 for a notification-origin chat. Uses the LOCAL token (no network gate: A3's own requests recover the
  /// session), waits for the navigator when the app is still starting, and counts the notification as handled only
  /// once the chat really opened.
  static Future<void> openChatNow({int? notificationId}) async {
    final id = notificationId != null && notificationId > 0 ? notificationId : null;
    if (id != null && _openChatNavigatedIds.contains(id)) return;

    final context = await _navigatorContext();
    if (context == null || !context.mounted) return;
    final hasToken = await AuthService.hasToken();
    if (!context.mounted) return;
    if (id != null) {
      if (_openChatNavigatedIds.contains(id)) return; // another path got there while we waited
      _openChatNavigatedIds.add(id);
      if (_openChatNavigatedIds.length > _maxNavDedup) {
        _openChatNavigatedIds.remove(_openChatNavigatedIds.first);
      }
    }

    if (!hasToken) {
      AppGateRouter.goToLogin(context);
      return;
    }

    AppGateRouter.goToHeart(
      context,
      fromNotification: true,
      notificationId: id,
    );
  }

  static Future<BuildContext?> _navigatorContext({Duration timeout = const Duration(seconds: 10)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final context = navigatorKey.currentContext;
      if (context != null) return context;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return navigatorKey.currentContext;
  }

  @visibleForTesting
  static void resetNavDedupeForTest() {
    _openChatNavigatedIds.clear();
  }

  @visibleForTesting
  static void resetInFlightForTest() {
    _inFlightKeys.clear();
  }

  @visibleForTesting
  static bool isInFlightForTest(int notificationId, String actionId) =>
      _inFlightKeys.contains('$notificationId|$actionId');
}
