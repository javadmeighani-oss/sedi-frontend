/// Local notifications: init (permissions + Android channels), show.
/// A4: single Flutter-rendered Android tray with localized Gate4 actions.
/// Channels: legacy silent morning/morning_v2 + morning_v3/v4 + engagement_v2/v3
/// kept installed for compatibility; Gate4 routes to morning_v5 / engagement_v4
/// (audible sedi_alarm) / health_alert_v2.
/// Runtime sound download is PROHIBITED — binary must be bundled.
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/brand_name.dart';
import 'background_notification_action_handler.dart';
import 'tray_notification_snapshot_store.dart';

/// Expected Android raw resource name (file without extension): sedi_alarm.
const String androidSoundResource = 'sedi_alarm';

/// iOS sound file name (as in Runner bundle): sedi_alarm.wav (or .caf).
const String iosSoundFile = 'sedi_alarm.wav';

const String channelMorningLegacy = 'morning';
const String channelEngagementLegacy = 'engagement';
const String channelHealthAlertLegacy = 'health_alert';
const String channelMorningV2 = 'morning_v2';
const String channelMorningV3 = 'morning_v3';
const String channelMorningV4 = 'morning_v4';
const String channelMorningV5 = 'morning_v5';
const String channelEngagementV2 = 'engagement_v2';
const String channelEngagementV3 = 'engagement_v3';
const String channelEngagementV4 = 'engagement_v4';
const String channelHealthAlertV2 = 'health_alert_v2';

/// Top-level background action handler (terminated/background isolate).
/// Like/Dislike: persist → background-safe ACK → dismiss on success.
/// open_chat/body: enqueue only (no navigation from isolate).
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  // Required for SharedPreferences / secure storage in background isolate.
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundNotificationActionHandler.handle(response);
}

Map<String, dynamic>? parseLocalNotificationPayload(String? payloadJson) {
  if (payloadJson == null || payloadJson.isEmpty) return null;
  try {
    final decoded = jsonDecode(payloadJson);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}

/// Resolve Android channel_id from FCM data for Gate4 tray render.
/// Gate4 never resolves to silent morning / morning_v2.
String resolveAndroidChannelId(String channel) {
  switch (channel) {
    case 'morning':
    case channelMorningLegacy:
    case channelMorningV2:
    case channelMorningV3:
    case channelMorningV4:
    case channelMorningV5:
    case 'morning_v2':
    case 'morning_v3':
    case 'morning_v4':
    case 'morning_v5':
      return channelMorningV5;
    case 'health_alert':
    case channelHealthAlertLegacy:
    case channelHealthAlertV2:
    case 'sedi_health':
    case 'sedi_critical':
      return channelHealthAlertV2;
    case 'engagement':
    case channelEngagementLegacy:
    case channelEngagementV2:
    case channelEngagementV3:
    case channelEngagementV4:
    case 'sedi_reminder':
    case 'sedi_default':
    default:
      return channelEngagementV4;
  }
}

/// Parse Gate4 action buttons; never hard-code LIKE/DISLIKE/OPEN_CHAT labels.
List<AndroidNotificationAction> resolveNotificationActions({
  required Map<String, dynamic> data,
  String language = 'en',
}) {
  final labels = <String, String>{};
  final order = <String>[];

  void addAction(String id, String label) {
    final key = id.trim().toLowerCase();
    if (key != 'like' && key != 'dislike' && key != 'open_chat') return;
    if (!labels.containsKey(key)) order.add(key);
    labels[key] = label.trim().isEmpty ? fallbackActionLabel(key, language) : label.trim();
  }

  final gate4Raw = data['gate4_actions'];
  if (gate4Raw != null) {
    try {
      final decoded =
          gate4Raw is String ? jsonDecode(gate4Raw) : gate4Raw;
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final id = '${item['action_id'] ?? ''}';
          final label = '${item['label'] ?? ''}';
          addAction(id, label);
        }
      }
    } catch (_) {}
  }

  if (labels.isEmpty) {
    final labelsRaw = data['action_labels'];
    if (labelsRaw != null) {
      try {
        final decoded =
            labelsRaw is String ? jsonDecode(labelsRaw) : labelsRaw;
        if (decoded is Map) {
          decoded.forEach((k, v) => addAction('$k', '$v'));
        }
      } catch (_) {}
    }
  }

  if (labels.isEmpty) {
    for (final id in const ['like', 'dislike', 'open_chat']) {
      addAction(id, fallbackActionLabel(id, language));
    }
  }

  return [
    for (final id in order)
      AndroidNotificationAction(
        id,
        labels[id]!,
        showsUserInterface: id == 'open_chat',
        // Keep tray until backend ACK dismisses it explicitly.
        cancelNotification: false,
      ),
  ];
}

String fallbackActionLabel(String actionId, String language) {
  final lang = language.toLowerCase().split('-').first;
  switch (actionId) {
    case 'like':
      return lang == 'fa'
          ? 'پسندیدن'
          : lang == 'ar'
              ? 'إعجاب'
              : 'Like';
    case 'dislike':
      return lang == 'fa'
          ? 'نپسندیدن'
          : lang == 'ar'
              ? 'عدم إعجاب'
              : 'Dislike';
    case 'open_chat':
      return lang == 'fa'
          ? 'صحبت با صدی'
          : lang == 'ar'
              ? 'التحدث مع صدی'
              : 'Talk to Sedi';
    default:
      return actionId;
  }
}

/// Transient tray processing label — never implies backend success.
String trayProcessingLabel(String actionId, String language) {
  final lang = language.toLowerCase().split('-').first;
  switch (actionId) {
    case 'like':
      return lang == 'fa'
          ? 'در حال ارسال پسند…'
          : lang == 'ar'
              ? 'جارٍ إرسال الإعجاب…'
              : 'Sending Like…';
    case 'dislike':
      return lang == 'fa'
          ? 'در حال ارسال نپسند…'
          : lang == 'ar'
              ? 'جارٍ إرسال عدم الإعجاب…'
              : 'Sending Dislike…';
    case 'open_chat':
      return lang == 'fa'
          ? 'در حال آماده‌سازی…'
          : lang == 'ar'
              ? 'جارٍ التحضير…'
              : 'Preparing…';
    default:
      return lang == 'fa'
          ? 'در حال پردازش…'
          : lang == 'ar'
              ? 'جارٍ المعالجة…'
              : 'Processing…';
  }
}

(Importance, Priority, bool playSound, bool enableVibration)
    channelImportanceFor(String channelId) {
  switch (channelId) {
    case channelHealthAlertV2:
    case channelHealthAlertLegacy:
      return (Importance.high, Priority.high, true, true);
    case channelEngagementV4:
    case channelEngagementV3:
    case channelEngagementV2:
    case channelEngagementLegacy:
      return (
        Importance.defaultImportance,
        Priority.defaultPriority,
        true,
        false
      );
    case channelMorningV5:
    case channelMorningV4:
    case channelMorningV3:
      return (
        Importance.defaultImportance,
        Priority.defaultPriority,
        true,
        false
      );
    case channelMorningV2:
    case channelMorningLegacy:
      return (Importance.low, Priority.low, false, false);
    default:
      return (
        Importance.defaultImportance,
        Priority.defaultPriority,
        true,
        false
      );
  }
}

class LocalNotificationsService {
  /// Callback when user taps notification or action (main isolate).
  /// [actionId]: 'like' | 'dislike' | 'open_chat' | null (body tap → open_chat)
  static void Function(String? actionId, String? payloadJson)? onNotificationResponse;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sedi_alerts';
  static String get _channelName => '${sediBrandName('en')} Alerts';

  static bool _initialized = false;

  /// Last rendered tray snapshot for same-ID processing updates (no second tray).
  static final Map<int, _TraySnapshot> _lastTrayById = <int, _TraySnapshot>{};

  static Future<bool> init({
    void Function(String? actionId, String? payloadJson)? onResponse,
  }) async {
    if (_initialized) {
      if (onResponse != null) onNotificationResponse = onResponse;
      return true;
    }
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
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    if (ok != true) return false;

    if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await impl?.createNotificationChannel(AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: '${sediBrandName('en')} health and reminder alerts',
        importance: Importance.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(androidSoundResource),
        enableVibration: true,
      ));
      for (final ch in allAndroidChannels) {
        await impl?.createNotificationChannel(ch);
      }
    }
    _initialized = true;
    return true;
  }

  /// Public for tests. Old channel IDs remain installed; Gate4 routes to v5/v4.
  static List<AndroidNotificationChannel> get allAndroidChannels => [
        AndroidNotificationChannel(
          channelMorningLegacy,
          'Morning Brief',
          description: 'Daily morning notifications',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelEngagementLegacy,
          'Engagement',
          description: 'Engagement nudges',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelHealthAlertLegacy,
          'Health Alerts',
          description: 'Health care alerts',
          importance: Importance.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: true,
        ),
        AndroidNotificationChannel(
          channelMorningV2,
          'Morning Brief',
          description: 'Daily morning notifications (v2 legacy silent)',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelMorningV3,
          'Morning Brief',
          description: 'Daily morning notifications (v3 legacy audible)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelMorningV4,
          'Morning Brief',
          description: 'Daily morning notifications (v4 legacy audible)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelMorningV5,
          'Morning Brief',
          description: 'Daily morning notifications (v5 audible)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelEngagementV2,
          'Engagement',
          description: 'Engagement nudges (v2)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelEngagementV3,
          'Engagement',
          description: 'Engagement nudges (v3 legacy audible)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelEngagementV4,
          'Engagement',
          description: 'Engagement nudges (v4 audible)',
          importance: Importance.defaultImportance,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: false,
        ),
        AndroidNotificationChannel(
          channelHealthAlertV2,
          'Health Alerts',
          description: 'Health care alerts (v2)',
          importance: Importance.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(androidSoundResource),
          enableVibration: true,
        ),
      ];

  static void _handleNotificationResponse(NotificationResponse? response) {
    if (response == null) return;
    onNotificationResponse?.call(response.actionId, response.payload);
  }

  /// Recover terminated launch from a *local* notification/action.
  static Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }

  /// Dismiss local tray entry after backend ACK (never before).
  static Future<void> cancelByBackendNotificationId(int notificationId) async {
    if (notificationId <= 0) return;
    try {
      if (!_initialized) await init();
      final id = notificationIdToInt(notificationId.toString());
      await _plugin.cancel(id);
      _lastTrayById.remove(id);
      await TrayNotificationSnapshotStore.remove(notificationId);
    } catch (e) {
      debugPrint('[LocalNotif] cancel failed: $e');
    }
  }

  /// Restore ORIGINAL same-ID actionable tray after processing failure.
  /// Silent / onlyAlertOnce — no fake success, no second tray ID.
  static Future<void> restoreOriginalTrayNotification({
    required int notificationId,
  }) async {
    if (notificationId <= 0) return;
    if (!Platform.isAndroid) return;
    try {
      if (!_initialized) await init();
      final stored = await TrayNotificationSnapshotStore.get(notificationId);
      final notifId = notificationIdToInt(notificationId.toString());
      final mem = _lastTrayById[notifId];
      final title = (stored?.title.isNotEmpty == true)
          ? stored!.title
          : (mem?.title ?? sediBrandName('en'));
      final body = stored?.body ?? mem?.body ?? '';
      final channelRaw =
          stored?.channel ?? mem?.channel ?? 'engagement';
      final language = stored?.language ?? 'en';
      final payloadStr = (stored?.payloadJson.isNotEmpty == true)
          ? stored!.payloadJson
          : (mem?.payloadJson ??
              jsonEncode({
                'notification_id': '$notificationId',
                'source_notification_id': '$notificationId',
                'channel': channelRaw,
                'deeplink_url': '',
                'language': language,
              }));
      final actionData = stored?.actionData() ?? <String, dynamic>{};
      final channelId = resolveAndroidChannelId(channelRaw);
      final actions =
          resolveNotificationActions(data: actionData, language: language);

      final android = AndroidNotificationDetails(
        channelId,
        channelDisplayName(channelId),
        channelDescription: '${sediBrandName('en')} notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        // Silent restore — do not re-alert / re-sound.
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        actions: actions,
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      );
      await _plugin.show(
        notifId,
        title,
        body,
        NotificationDetails(android: android, iOS: darwin),
        payload: payloadStr,
      );
      _lastTrayById[notifId] = _TraySnapshot(
        title: title,
        body: body,
        channel: channelRaw,
        payloadJson: payloadStr,
      );
    } catch (e) {
      debugPrint('[LocalNotif] restore tray failed: $e');
    }
  }

  /// Transient selected/processing reaction on the SAME local notification ID.
  /// Does not imply backend success; removes action buttons to reject duplicates.
  /// Android-supported path; no-op elsewhere when unsupported.
  /// Durable original snapshot is preserved for failure restore.
  static Future<void> showTrayActionProcessing({
    required int notificationId,
    required String actionId,
    String? payloadJson,
  }) async {
    if (notificationId <= 0) return;
    // Android supports same-ID tray updates; skip elsewhere without implying success.
    if (!Platform.isAndroid) return;
    try {
      if (!_initialized) await init();
      final notifId = notificationIdToInt(notificationId.toString());
      final stored = await TrayNotificationSnapshotStore.get(notificationId);
      final snap = _lastTrayById[notifId];
      Map<String, dynamic>? payload = parseLocalNotificationPayload(payloadJson);
      payload ??= parseLocalNotificationPayload(stored?.payloadJson);
      payload ??= parseLocalNotificationPayload(snap?.payloadJson);
      final language = payload?['language']?.toString() ??
          stored?.language ??
          'en';
      final channelRaw = payload?['channel']?.toString() ??
          stored?.channel ??
          snap?.channel ??
          'engagement';
      final channelId = resolveAndroidChannelId(channelRaw);
      final title = (stored?.title.isNotEmpty == true)
          ? stored!.title
          : ((snap?.title.isNotEmpty == true)
              ? snap!.title
              : sediBrandName(language));
      final originalBody = stored?.body ?? snap?.body ?? '';
      final processing = trayProcessingLabel(actionId, language);
      // Keep original body when present; append transient processing marker only.
      final body = originalBody.trim().isEmpty
          ? processing
          : '$originalBody · $processing';
      final payloadStr = payloadJson ??
          stored?.payloadJson ??
          snap?.payloadJson ??
          jsonEncode({
            'notification_id': '$notificationId',
            'source_notification_id': '$notificationId',
            'channel': channelRaw,
            'deeplink_url': '',
            'language': language,
          });

      final android = AndroidNotificationDetails(
        channelId,
        channelDisplayName(channelId),
        channelDescription: '${sediBrandName('en')} notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        // Empty actions = processing lock on the same tray row.
        actions: const <AndroidNotificationAction>[],
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
      );
      final details = NotificationDetails(android: android, iOS: darwin);
      await _plugin.show(notifId, title, body, details, payload: payloadStr);
      // Memory cache for restore fallback — durable store remains original.
      _lastTrayById[notifId] = _TraySnapshot(
        title: title,
        body: originalBody,
        channel: channelRaw,
        payloadJson: payloadStr,
      );
    } catch (e) {
      debugPrint('[LocalNotif] processing tray update failed: $e');
    }
  }

  /// Show notification from FCM remote message. Use title/body as received.
  static Future<void> showRemoteNotification(RemoteMessage message) async {
    if (!_initialized) await init();
    final notif = message.notification;
    final data = Map<String, dynamic>.from(message.data);
    final title =
        notif?.title ?? data['title']?.toString() ?? 'Notification';
    final body = notif?.body ?? data['body']?.toString() ?? '';
    final notificationId = data['notification_id']?.toString() ?? '';
    final channel =
        data['channel_id']?.toString() ??
        data['channel']?.toString() ??
        data['type']?.toString() ??
        'engagement';
    final deeplinkUrl = data['deeplink_url']?.toString() ?? '';
    final sourceId = data['source_notification_id']?.toString() ?? notificationId;
    final language = data['language']?.toString() ?? 'en';

    final payload = <String, String>{
      'notification_id': notificationId,
      'source_notification_id': sourceId,
      'channel': channel,
      'deeplink_url': deeplinkUrl,
      'language': language,
    };
    final payloadStr = jsonEncode(payload);

    final channelId = resolveAndroidChannelId(channel);
    final notifId = notificationIdToInt(notificationId);
    final actions = resolveNotificationActions(data: data, language: language);

    String? gate4Raw;
    final g4 = data['gate4_actions'];
    if (g4 != null) {
      gate4Raw = g4 is String ? g4 : jsonEncode(g4);
    }
    String? labelsRaw;
    final al = data['action_labels'];
    if (al != null) {
      labelsRaw = al is String ? al : jsonEncode(al);
    }

    final snap = TrayNotificationSnapshot(
      notificationId: int.tryParse(notificationId) ?? notifId,
      title: title,
      body: body,
      channel: channel,
      language: language,
      payloadJson: payloadStr,
      gate4ActionsRaw: gate4Raw,
      actionLabelsRaw: labelsRaw,
    );
    // Durable original for failure restore (same ID). Bounded prefs store.
    // ignore: discarded_futures
    TrayNotificationSnapshotStore.put(snap);
    _lastTrayById[notifId] = _TraySnapshot(
      title: title,
      body: body,
      channel: channel,
      payloadJson: payloadStr,
    );

    if (Platform.isAndroid) {
      final (importance, priority, playSound, enableVibration) =
          channelImportanceFor(channelId);
      final android = AndroidNotificationDetails(
        channelId,
        channelDisplayName(channelId),
        channelDescription: '${sediBrandName('en')} notifications',
        importance: importance,
        priority: priority,
        playSound: playSound,
        sound: playSound
            ? const RawResourceAndroidNotificationSound(androidSoundResource)
            : null,
        enableVibration: enableVibration,
        actions: actions,
      );
      const darwin = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: iosSoundFile,
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

  static String channelDisplayName(String channelId) {
    switch (channelId) {
      case channelMorningV5:
      case channelMorningV4:
      case channelMorningV3:
      case channelMorningV2:
      case channelMorningLegacy:
        return 'Morning Brief';
      case channelHealthAlertV2:
      case channelHealthAlertLegacy:
        return 'Health Alerts';
      case channelEngagementV4:
      case channelEngagementV3:
      case channelEngagementV2:
      case channelEngagementLegacy:
      default:
        return 'Engagement';
    }
  }

  static int notificationIdToInt(String id) {
    final n = int.tryParse(id);
    if (n != null && n > 0 && n < 2147483647) return n;
    return id.hashCode.abs() % 2147483647;
  }

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
      sound: const RawResourceAndroidNotificationSound(androidSoundResource),
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      sound: iosSoundFile,
    );
    final details = NotificationDetails(android: android, iOS: darwin);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  @visibleForTesting
  static void clearTrayCacheForTest() => _lastTrayById.clear();
}

class _TraySnapshot {
  final String title;
  final String body;
  final String channel;
  final String payloadJson;

  const _TraySnapshot({
    required this.title,
    required this.body,
    required this.channel,
    required this.payloadJson,
  });
}
