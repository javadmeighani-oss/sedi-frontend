/// Local notifications: init (permissions + Android channels), show.
/// Stage 16.6: FCM remote message display with action buttons (LIKE, DISLIKE, OPEN_CHAT).
/// Channels: sedi_alerts (legacy), morning, engagement, health_alert.
/// Android: custom sound via RawResourceAndroidNotificationSound('sedi_alarm').
/// iOS: custom sound via DarwinNotificationDetails.sound ('sedi_alarm.wav').
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/brand_name.dart';

/// TODO(Stage 16.6.6): Dismiss callback - flutter_local_notifications does not reliably
/// provide a callback when user swipes/dismisses a notification on Android. Skip for now.

/// Expected Android raw resource name (file without extension): sedi_alarm.wav in res/raw/.
const String _androidSoundResource = 'sedi_alarm';

/// iOS sound file name (as in Runner bundle): sedi_alarm.wav (or .caf).
const String _iosSoundFile = 'sedi_alarm.wav';

/// Channel IDs for Stage 16.6 push
const String _channelMorning = 'morning';
const String _channelEngagement = 'engagement';
const String _channelHealthAlert = 'health_alert';

class LocalNotificationsService {
  /// Callback when user taps notification or action. Set via init(onResponse:).
  /// [actionId]: 'like' | 'dislike' | 'open_chat' | null (tap on body)
  /// [payloadJson]: JSON string with notification_id, channel, deeplink_url
  static void Function(String? actionId, String? payloadJson)? onNotificationResponse;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sedi_alerts';
  static String get _channelName => '${sediBrandName('en')} Alerts';

  static bool _initialized = false;

  /// Call once at app start. Requests permissions on iOS.
  /// [onResponse]: optional callback when user taps notification or action.
  static Future<bool> init({
    void Function(String? actionId, String? payloadJson)? onResponse,
  }) async {
    if (_initialized) return true;
    onNotificationResponse = onResponse;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);

    final ok = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    if (ok != true) return false;

    if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Legacy channel
      await impl?.createNotificationChannel(AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: '${sediBrandName('en')} health and reminder alerts',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidSoundResource),
        enableVibration: true,
      ));
      // Stage 16.6 channels
      for (final ch in _pushChannels) {
        await impl?.createNotificationChannel(ch);
      }
    }
    _initialized = true;
    return true;
  }

  /// Channel behavior (market-ready):
  /// - health_alert: HIGH importance, heads-up, vibration+sound for urgent health care alerts.
  /// - engagement: DEFAULT importance, non-intrusive nudges.
  /// - morning: LOW importance, no heads-up; user can override per-channel settings in Android system settings.
  static List<AndroidNotificationChannel> get _pushChannels => [
        AndroidNotificationChannel(
          _channelMorning,
          'Morning Brief',
          description: 'Daily morning notifications',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          _channelEngagement,
          'Engagement',
          description: 'Engagement nudges',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          _channelHealthAlert,
          'Health Alerts',
          description: 'Health care alerts',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(_androidSoundResource),
          enableVibration: true,
        ),
      ];

  static void _handleNotificationResponse(NotificationResponse? response) {
    if (response == null) return;
    onNotificationResponse?.call(response.actionId, response.payload);
  }

  /// Show notification from FCM remote message. Use title/body as received.
  /// Parses notification_id, channel, deeplink_url, actions_json from data.
  static Future<void> showRemoteNotification(RemoteMessage message) async {
    if (!_initialized) await init();
    final notif = message.notification;
    final data = message.data;
    String title =
        notif?.title ?? data['title'] ?? 'Notification';
    String body = notif?.body ?? data['body'] ?? '';
    final notificationId = data['notification_id']?.toString() ?? '';
    final channel = data['channel'] ?? data['type'] ?? 'engagement';
    final deeplinkUrl = data['deeplink_url']?.toString() ?? '';

    final payload = <String, String>{
      'notification_id': notificationId,
      'channel': channel,
      'deeplink_url': deeplinkUrl,
    };
    final payloadStr = jsonEncode(payload);

    final channelId = _channelForPush(channel);
    final notifId = _notificationIdToInt(notificationId);

    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'like',
        'LIKE',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'dislike',
        'DISLIKE',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'open_chat',
        'OPEN_CHAT',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    if (Platform.isAndroid) {
      final (importance, priority, playSound, enableVibration) =
          _channelImportance(channelId);
      final android = AndroidNotificationDetails(
        channelId,
        _channelDisplayName(channelId),
        channelDescription: '${sediBrandName('en')} notifications',
        importance: importance,
        priority: priority,
        playSound: playSound,
        enableVibration: enableVibration,
        actions: actions,
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: _iosSoundFile,
      );
      final details = NotificationDetails(android: android, iOS: darwin);
      await _plugin.show(
        notifId,
        title,
        body,
        details,
        payload: payloadStr,
      );
    } else {
      await showNotification(
        id: notifId,
        title: title,
        body: body,
        payload: payloadStr,
      );
    }
  }

  static String _channelForPush(String channel) {
    switch (channel) {
      case 'morning':
        return _channelMorning;
      case 'health_alert':
        return _channelHealthAlert;
      case 'engagement':
      default:
        return _channelEngagement;
    }
  }

  static String _channelDisplayName(String channelId) {
    switch (channelId) {
      case _channelMorning:
        return 'Morning Brief';
      case _channelHealthAlert:
        return 'Health Alerts';
      case _channelEngagement:
      default:
        return 'Engagement';
    }
  }

  static (Importance, Priority, bool, bool) _channelImportance(String channelId) {
    switch (channelId) {
      case _channelHealthAlert:
        return (Importance.high, Priority.high, true, true);
      case _channelEngagement:
        return (Importance.defaultImportance, Priority.defaultPriority, true, false);
      case _channelMorning:
      default:
        return (Importance.low, Priority.low, false, false);
    }
  }

  static int _notificationIdToInt(String id) {
    final n = int.tryParse(id);
    if (n != null && n > 0 && n < 2147483647) return n;
    return id.hashCode.abs() % 2147483647;
  }

  /// Show a local notification with title, body, optional payload.
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
