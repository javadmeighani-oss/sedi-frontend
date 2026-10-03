/// Background-isolate Like/Dislike ACK helper (A4).
///
/// Entry path for [notificationTapBackground] only:
/// persist pending → dismiss tray immediately → authenticated feedback with
/// recoverSessionOn401:false → on ACK remove pending; on failure keep pending
/// and never restore the tray (resume drain retries silently).
/// Never navigates, never force-logouts, never opens UI from the isolate.
/// open_chat / body tap: enqueue + immediate dismiss (foreground owns ACK+nav).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/notification_repository.dart';
import '../auth/auth_service.dart';
import 'pending_notification_actions.dart';
import 'tray_notification_snapshot_store.dart';

class BackgroundNotificationActionHandler {
  BackgroundNotificationActionHandler._();

  /// Isolate-local in-flight lock (dedupeKey) — reject duplicate taps.
  static final Set<String> _inFlightKeys = <String>{};

  static Future<void> handle(NotificationResponse response) async {
    final payload = _parsePayload(response.payload);
    if (payload == null) return;
    final idStr = payload['notification_id']?.toString() ?? '';
    final id = int.tryParse(idStr);
    if (id == null || id <= 0) return;

    final action = (response.actionId == null || response.actionId!.isEmpty)
        ? 'open_chat'
        : response.actionId!.trim();
    if (action.isEmpty) return;

    final key = '$id|$action';
    if (_inFlightKeys.contains(key)) {
      debugPrint('[FCM-bg] duplicate action rejected while processing: $key');
      return;
    }
    _inFlightKeys.add(key);

    try {
      final clientTs = DateTime.now().toUtc().toIso8601String();
      // Persist pending BEFORE network attempt.
      await PendingNotificationActions.enqueue(
        notificationId: id,
        actionId: action,
        clientTs: clientTs,
      );

      // A4: dismiss tray immediately for like / dislike / open_chat.
      // Never restore on ACK/network failure.
      await _dismissTrayIsolated(id);
      await TrayNotificationSnapshotStore.remove(id);

      // Body / Talk-to-Sedi: queue only — foreground drain owns ACK + nav.
      if (action != 'like' && action != 'dislike') {
        debugPrint('[FCM-bg] open_chat enqueue+dismiss; foreground drain owns ACK');
        return;
      }

      final ok = await _attemptLikeDislikeAck(
        notificationId: id,
        actionId: action,
        clientTs: clientTs,
      );
      if (!ok) {
        // keep pending for resume drain — tray already dismissed; no restore.
        debugPrint('[FCM-bg] keep pending for resume drain');
      }
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  /// Returns true on ACK; false keeps pending (tray already dismissed).
  static Future<bool> _attemptLikeDislikeAck({
    required int notificationId,
    required String actionId,
    required String clientTs,
  }) async {
    try {
      final hasToken = await AuthService.hasToken();
      if (!hasToken) {
        debugPrint('[FCM-bg] no token; keep pending for resume drain');
        return false;
      }

      final repo = NotificationRepository();
      final resp = await repo.sendFeedback(
        notificationId: notificationId,
        action: actionId,
        clientTs: clientTs,
        // Critical: background isolate must never force logout / navigate.
        recoverSessionOn401: false,
      );
      if (!resp.ok) {
        debugPrint('[FCM-bg] feedback failed; keep pending (tray already dismissed)');
        return false;
      }

      await PendingNotificationActions.remove(
        notificationId: notificationId,
        actionId: actionId,
      );
      await _dismissTrayIsolated(notificationId);
      await TrayNotificationSnapshotStore.remove(notificationId);
      debugPrint('[FCM-bg] ACK ok; pending removed + tray dismissed');
      return true;
    } catch (e) {
      debugPrint('[FCM-bg] ACK error (retained): $e');
      // Keep pending for start/resume drain — never restore tray.
      return false;
    }
  }

  /// Dismiss exact local notification without registering UI/response callbacks.
  static Future<void> _dismissTrayIsolated(int notificationId) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await plugin.initialize(settings);
      await plugin.cancel(_notificationIdToInt(notificationId));
    } catch (e) {
      debugPrint('[FCM-bg] tray dismiss failed: $e');
    }
  }

  static int _notificationIdToInt(int id) {
    if (id > 0 && id < 2147483647) return id;
    return id.hashCode.abs() % 2147483647;
  }

  static Map<String, dynamic>? _parsePayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(payloadJson);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void resetInFlightForTest() => _inFlightKeys.clear();
}
