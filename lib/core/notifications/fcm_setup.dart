/// FCM setup: background handler and payload helpers.
/// Stage 16.6 / A4: Gate4 Android is data-only — Flutter local renderer owns tray.
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notifications_service.dart';

/// Top-level background handler. Must be top-level for Firebase isolate.
/// Shows exactly one local notification per message (no second system path for Gate4).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await LocalNotificationsService.init();
    await LocalNotificationsService.showRemoteNotification(message);
  } catch (e) {
    // ignore: avoid_print
    print('[FCM] Background handler error: $e');
  }
}

/// Parse payload JSON from notification response.
Map<String, dynamic>? parseNotificationPayload(String? payloadJson) {
  return parseLocalNotificationPayload(payloadJson);
}

/// True when FCM data marks Gate4 (Flutter should be sole Android renderer).
bool isGate4FcmData(Map<String, dynamic> data) {
  final gate = (data['gate'] ?? '').toString().trim().toLowerCase();
  if (gate == 'gate4') return true;
  final actions = data['gate4_actions'];
  return actions != null && actions.toString().trim().isNotEmpty;
}

Map<String, dynamic>? tryDecodeJsonMap(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}
