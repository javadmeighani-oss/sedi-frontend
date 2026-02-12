/// FCM setup: background handler and initialization helpers.
/// Stage 16.6 push notifications.
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notifications_service.dart';

/// Top-level background handler. Must be top-level for Firebase isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await LocalNotificationsService.init();
    await LocalNotificationsService.showRemoteNotification(message);
  } catch (e) {
    print('[FCM] Background handler error: $e');
  }
}

/// Parse payload JSON from notification response.
Map<String, dynamic>? parseNotificationPayload(String? payloadJson) {
  if (payloadJson == null || payloadJson.isEmpty) return null;
  try {
    final decoded = jsonDecode(payloadJson);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}
