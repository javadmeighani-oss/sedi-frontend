/// Local notifications: init (permissions + Android channel with sound), show.
/// Android: custom sound via RawResourceAndroidNotificationSound('sedi_alarm').
/// iOS: custom sound via DarwinNotificationDetails.sound ('sedi_alarm.wav').
/// Channel id is stable: 'sedi_alerts' (do not recreate with different configs).
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/brand_name.dart';

/// Expected Android raw resource name (file without extension): sedi_alarm.wav in res/raw/.
const String _androidSoundResource = 'sedi_alarm';

/// iOS sound file name (as in Runner bundle): sedi_alarm.wav (or .caf).
const String _iosSoundFile = 'sedi_alarm.wav';

class LocalNotificationsService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sedi_alerts';
  static String get _channelName => '${sediBrandName('en')} Alerts';

  static bool _initialized = false;

  /// Call once at app start (e.g. after user verification). Requests permissions on iOS (alert, sound, badge).
  static Future<bool> init() async {
    if (_initialized) return true;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    final ok = await _plugin.initialize(settings);
    if (ok != true) return false;
    if (Platform.isAndroid) {
      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: '${sediBrandName('en')} health and reminder alerts',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidSoundResource),
        enableVibration: true,
      );
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }
    _initialized = true;
    return true;
  }

  /// Show a local notification with title, body, optional payload. Uses custom sound when asset is present.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '${sediBrandName('en')} health and reminder alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_androidSoundResource),
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: _iosSoundFile,
    );
    final details = NotificationDetails(android: android, iOS: darwin);
    await _plugin.show(id, title, body, details, payload: payload);
  }
}
