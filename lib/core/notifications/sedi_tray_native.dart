import 'dart:ui' show PluginUtilities;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sedi_tray/sedi_tray.dart';

import 'background_notification_action_handler.dart';

/// R-073: the Dart side of the native tray (Android). The native answer receiver closes the grown notification at once and
/// starts THIS entry in a headless engine to deliver the answer; nothing here is on the user's waiting path.
@pragma('vm:entry-point')
Future<void> sediTrayBackgroundEntry() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedi/tray_bg');
  channel.setMethodCallHandler((call) async {
    if (call.method != 'onAction') return false;
    try {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final answer = args['answer']?.toString() ?? '';
      if (answer.isEmpty) return false;
      await BackgroundNotificationActionHandler.handle(
        NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          id: args['id'] is int ? args['id'] as int : null,
          actionId: '${BackgroundNotificationActionHandler.reasonActionPrefix}$answer',
          payload: args['payload']?.toString(),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[SediTray] answer not delivered (kept for the next start): $e');
      return false;
    }
  });
  await channel.invokeMethod<void>('ready');
}

class SediTrayNativeBridge {
  SediTrayNativeBridge._();

  /// Tells the native receiver which Dart entry to start for a tray answer. Called at every app start; fail-open.
  static Future<void> registerBackground() async {
    if (!SediTray.supported) return;
    try {
      final handle = PluginUtilities.getCallbackHandle(sediTrayBackgroundEntry);
      if (handle != null) await SediTray.registerBackground(handle.toRawHandle());
    } catch (e) {
      debugPrint('[SediTray] background entry not registered: $e');
    }
  }

  /// Picks up what the native tray kept for the app: answers that could not be delivered at once, and the «talk with Sedi»
  /// tap (same seam as a tap on the notification body). Fail-open.
  static Future<void> pickUp({required void Function(String? actionId, String? payload) openChat}) async {
    if (!SediTray.supported) return;
    try {
      final pending = await SediTray.drainPending();
      for (final item in pending) {
        try {
          await BackgroundNotificationActionHandler.handle(
            NotificationResponse(
              notificationResponseType: NotificationResponseType.selectedNotificationAction,
              id: item.id,
              actionId: '${BackgroundNotificationActionHandler.reasonActionPrefix}${item.answer}',
              payload: item.payload,
            ),
          );
        } catch (e) {
          debugPrint('[SediTray] pending answer failed: $e');
        }
      }
      final launch = await SediTray.takeLaunch();
      if (launch != null) openChat('open_chat', launch.payload);
    } catch (e) {
      debugPrint('[SediTray] pick-up failed: $e');
    }
  }
}
