/// Background-isolate Like/Dislike ACK helper (A4 FE-01.1).
///
/// Entry path for [notificationTapBackground] only:
/// persist pending → authenticated feedback with recoverSessionOn401:false →
/// on ACK remove pending + dismiss tray; on failure keep pending + restore
/// original actionable tray for start/resume drain.
/// Never navigates, never force-logouts, never opens UI from the isolate.
/// open_chat / body tap: enqueue only (foreground ACK-before-nav unchanged).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/notification_repository.dart';
import '../auth/auth_service.dart';
import 'local_notifications_service.dart';
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

    var showedProcessing = false;
    try {
      final clientTs = DateTime.now().toUtc().toIso8601String();
      // Persist pending BEFORE network attempt.
      await PendingNotificationActions.enqueue(
        notificationId: id,
        actionId: action,
        clientTs: clientTs,
      );

      // Body / Talk-to-Sedi: queue only — foreground drain owns ACK + nav.
      // No processing rewrite for Talk (ACK-before-nav remains foreground).
      if (action != 'like' && action != 'dislike') return;

      // Transient selected/processing on SAME tray id (Android-supported).
      await _showProcessingIsolated(
        notificationId: id,
        actionId: action,
        payload: payload,
        payloadJson: response.payload,
      );
      showedProcessing = true;

      final ok = await _attemptLikeDislikeAck(
        notificationId: id,
        actionId: action,
        clientTs: clientTs,
      );
      if (!ok && showedProcessing) {
        await _restoreOriginalIsolated(id);
      }
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  /// Returns true on ACK; false keeps pending (caller restores tray).
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
        debugPrint('[FCM-bg] feedback failed; keep pending+tray');
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
      // Keep pending + tray for start/resume drain.
      return false;
    }
  }

  /// Isolate-local processing rewrite — same notification ID, no action buttons.
  /// Does not imply backend success; keeps tray for failure retention.
  static Future<void> _showProcessingIsolated({
    required int notificationId,
    required String actionId,
    required Map<String, dynamic> payload,
    String? payloadJson,
  }) async {
    try {
      final language = payload['language']?.toString() ?? 'en';
      final channelRaw = payload['channel']?.toString() ?? 'engagement';
      final channelId = resolveAndroidChannelId(channelRaw);
      final processing = trayProcessingLabel(actionId, language);
      final stored = await TrayNotificationSnapshotStore.get(notificationId);
      final title = (stored?.title.isNotEmpty == true)
          ? stored!.title
          : processing;
      final originalBody = stored?.body ?? '';
      final body = originalBody.trim().isEmpty
          ? processing
          : '$originalBody · $processing';
      final plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidInit);
      await plugin.initialize(settings);
      final android = AndroidNotificationDetails(
        channelId,
        LocalNotificationsService.channelDisplayName(channelId),
        channelDescription: 'Sedi notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        actions: const <AndroidNotificationAction>[],
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      );
      await plugin.show(
        _notificationIdToInt(notificationId),
        title,
        body,
        NotificationDetails(android: android, iOS: darwin),
        payload: payloadJson,
      );
    } catch (e) {
      debugPrint('[FCM-bg] processing tray update failed: $e');
    }
  }

  /// Restore original same-ID actionable tray from durable snapshot.
  static Future<void> _restoreOriginalIsolated(int notificationId) async {
    try {
      final stored = await TrayNotificationSnapshotStore.get(notificationId);
      if (stored == null) {
        debugPrint('[FCM-bg] no snapshot to restore for $notificationId');
        return;
      }
      final channelId = resolveAndroidChannelId(stored.channel);
      final actions = resolveNotificationActions(
        data: stored.actionData(),
        language: stored.language,
      );
      final plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidInit);
      await plugin.initialize(settings);
      final android = AndroidNotificationDetails(
        channelId,
        LocalNotificationsService.channelDisplayName(channelId),
        channelDescription: 'Sedi notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        actions: actions,
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      );
      await plugin.show(
        _notificationIdToInt(notificationId),
        stored.title,
        stored.body,
        NotificationDetails(android: android, iOS: darwin),
        payload: stored.payloadJson,
      );
      debugPrint('[FCM-bg] restored original actionable tray');
    } catch (e) {
      debugPrint('[FCM-bg] restore tray failed: $e');
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
