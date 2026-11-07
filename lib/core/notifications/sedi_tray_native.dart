import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant, PluginUtilities;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sedi_tray/sedi_tray.dart';

import 'background_notification_action_handler.dart';
import 'sedi_tray_args.dart';

/// R-073: the Dart side of the native tray (Android). The native answer receiver closes the grown notification at once and
/// starts THIS entry in a headless engine to deliver the answer; nothing here is on the user's waiting path.
@pragma('vm:entry-point')
Future<void> sediTrayBackgroundEntry() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This engine is started natively (not by `main()`): Dart-implemented plugins (shared_preferences, used by the token
  // migration and the pending-action store) are registered only when asked. Without it every answer from the grown
  // notification failed silently in the background (token unreadable -> reason never sent).
  DartPluginRegistrant.ensureInitialized();
  const channel = MethodChannel('sedi/tray_bg');
  channel.setMethodCallHandler((call) async {
    if (call.method != 'onAction') return false;
    try {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final answer = args['answer']?.toString() ?? '';
      if (answer.isEmpty) return false;
      if (answer == kTrayDislikeAnswer) {
        await BackgroundNotificationActionHandler.acknowledgeNativeDislike(args['payload']?.toString());
        return true;
      }
      final payload = jsonDecode(args['payload']?.toString() ?? '{}');
      final id = int.tryParse(((payload is Map ? payload['notification_id'] : null) ?? '').toString());
      if (id == null || id <= 0) return true; // nothing to deliver: do not keep an unusable answer
      // false = not accepted by the backend: the native side keeps the answer for the next start.
      return await BackgroundNotificationActionHandler.deliverReasonAnswer(id, answer);
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
          if (item.answer == kTrayDislikeAnswer) {
            await BackgroundNotificationActionHandler.acknowledgeNativeDislike(item.payload);
            continue;
          }
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
