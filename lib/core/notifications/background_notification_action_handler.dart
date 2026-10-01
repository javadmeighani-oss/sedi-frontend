/// Background-isolate Like/Dislike ACK helper (A4 FE-01.1).
///
/// Entry path for [notificationTapBackground] only:
/// persist pending → authenticated feedback with recoverSessionOn401:false →
/// on ACK remove pending + dismiss tray; on failure keep both for start/resume drain.
/// Never navigates, never force-logouts, never opens UI from the isolate.
/// open_chat / body tap: enqueue only (foreground ACK-before-nav unchanged).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/notification_repository.dart';
import '../auth/auth_service.dart';
import 'local_notifications_service.dart';
import 'pending_notification_actions.dart';

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

      // Transient selected/processing on SAME tray id (Android-supported).
      await _showProcessingIsolated(
        notificationId: id,
        actionId: action,
        payload: payload,
        payloadJson: response.payload,
      );

      // Body / Talk-to-Sedi: queue only — foreground drain owns ACK + nav.
      if (action != 'like' && action != 'dislike') return;

      await _attemptLikeDislikeAck(
        notificationId: id,
        actionId: action,
        clientTs: clientTs,
      );
    } finally {
      _inFlightKeys.remove(key);
    }
  }

  static Future<void> _attemptLikeDislikeAck({
    required int notificationId,
    required String actionId,
    required String clientTs,
  }) async {
    try {
      final hasToken = await AuthService.hasToken();
      if (!hasToken) {
        debugPrint('[FCM-bg] no token; keep pending for resume drain');
        return;
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
        return;
      }

      await PendingNotificationActions.remove(
        notificationId: notificationId,
        actionId: actionId,
      );
      await _dismissTrayIsolated(notificationId);
      debugPrint('[FCM-bg] ACK ok; pending removed + tray dismissed');
    } catch (e) {
      debugPrint('[FCM-bg] ACK error (retained): $e');
      // Keep pending + tray for start/resume drain.
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
        processing,
        processing,
        NotificationDetails(android: android, iOS: darwin),
        payload: payloadJson,
      );
    } catch (e) {
      debugPrint('[FCM-bg] processing tray update failed: $e');
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
