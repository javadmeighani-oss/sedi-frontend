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
import '../../features/notifications/presentation/notification_inbox_l10n.dart';
import '../auth/auth_service.dart';
import '../theme/sedi_palette.dart';
import 'local_notifications_service.dart';
import 'pending_dislike_reasons.dart';
import 'pending_notification_actions.dart';
import 'tray_notification_snapshot_store.dart';

class BackgroundNotificationActionHandler {
  BackgroundNotificationActionHandler._();

  /// Action ids of the "why?" buttons shown INSIDE the notification after a tray Dislike (P7, Javad 2026-10-28).
  static const String reasonActionPrefix = 'reason:';

  /// Android shows at most three buttons: the reasons that change Sedi's behaviour the most. The other two reasons
  /// (unclear / not helpful) are inferred by the backend when the user answers nothing.
  static const List<String> promptReasons = <String>[
    'too_frequent',
    'wrong_timing',
    'irrelevant',
  ];

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

    // The user answered the in-notification "why?" question: send the reason, close the prompt. No app screen.
    if (action.startsWith(reasonActionPrefix)) {
      await _handleReasonAnswer(id, action.substring(reasonActionPrefix.length));
      return;
    }

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
      // The reason is asked inside a fresh notification (3 buttons); only when it cannot be shown does the chat page
      // ask later (fallback).
      if (action == 'dislike') {
        final shown = await _showReasonPrompt(notificationId: id, payload: payload);
        if (!shown) {
          try {
            await PendingDislikeReasons.add(id);
          } catch (e) {
            debugPrint('[FCM-bg] pending dislike reason not stored: $e');
          }
        }
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

  static String _lang(Map<String, dynamic> payload) {
    final raw = (payload['language'] ?? 'fa').toString().toLowerCase().split('-').first;
    return (raw == 'fa' || raw == 'ar' || raw == 'en') ? raw : 'fa';
  }

  /// Replaces the tray entry with a short question («چرا نپسندیدی؟») and three reason buttons. Auto-dismisses after 90 s.
  static Future<bool> _showReasonPrompt({
    required int notificationId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final lang = _lang(payload);
      final l10n = NotificationInboxL10n(lang);
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(androidBrandSmallIcon),
        ),
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      final channelRaw = (payload['channel'] ?? 'engagement').toString();
      final channelId = resolveAndroidChannelId(channelRaw);
      final actions = <AndroidNotificationAction>[
        for (final r in promptReasons)
          AndroidNotificationAction(
            '$reasonActionPrefix$r',
            l10n.dislikeReasonLabel(r),
            showsUserInterface: false,
            cancelNotification: true,
          ),
      ];
      await plugin.show(
        _notificationIdToInt(notificationId),
        l10n.dislikeReasonTitle,
        l10n.dislikeReasonHint,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            LocalNotificationsService.channelDisplayName(channelId),
            icon: androidBrandSmallIcon,
            color: SediPalette.pistachio900,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            playSound: false,
            enableVibration: false,
            onlyAlertOnce: true,
            autoCancel: true,
            timeoutAfter: 90000,
            actions: actions,
          ),
        ),
        payload: jsonEncode({
          'notification_id': '$notificationId',
          'source_notification_id': '$notificationId',
          'channel': channelRaw,
          'language': lang,
          'reason_prompt': true,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('[FCM-bg] reason prompt not shown: $e');
      return false;
    }
  }

  static Future<void> _handleReasonAnswer(int id, String reason) async {
    if (!promptReasons.contains(reason)) return;
    try {
      if (await AuthService.hasToken()) {
        await NotificationRepository().sendFeedback(
          notificationId: id,
          action: 'dislike',
          reason: reason,
          clientTs: DateTime.now().toUtc().toIso8601String(),
          recoverSessionOn401: false,
        );
      }
    } catch (e) {
      debugPrint('[FCM-bg] reason feedback failed (best effort): $e');
    }
    await _dismissTrayIsolated(id);
  }

  /// Dismiss exact local notification without registering UI/response callbacks.
  static Future<void> _dismissTrayIsolated(int notificationId) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings(androidBrandSmallIcon);
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
