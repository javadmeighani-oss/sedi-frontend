import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// One answer button of the grown tray notification.
class SediTrayAnswer {
  final String id;
  final String label;

  const SediTrayAnswer({required this.id, required this.label});

  Map<String, String> toMap() => <String, String>{'id': id, 'label': label};
}

/// An answer the user tapped in the tray that could not be delivered to Dart at once (picked up on the next start).
class SediTrayPendingAnswer {
  final int id;
  final String answer;
  final String payload;

  const SediTrayPendingAnswer({required this.id, required this.answer, required this.payload});
}

/// What the user tapped on the notification's «talk with Sedi» button (picked up when the app is in front).
class SediTrayLaunch {
  final int id;
  final String payload;

  const SediTrayLaunch({required this.id, required this.payload});
}

/// R-073: the native side of the tray. Every call is fail-open: a problem returns false / empty so the caller keeps the
/// standard notification path.
class SediTray {
  SediTray._();

  static const MethodChannel _channel = MethodChannel('sedi/tray');

  static bool get supported => Platform.isAndroid;

  /// Shows (or replaces, same [id]) the grown notification: its own title and text on top with «talk» and the selected
  /// «not now» buttons, Sedi's question below, and the answers below that. Returns true when it was posted.
  static Future<bool> showGrown({
    required int id,
    required bool rtl,
    required String title,
    required String body,
    required String question,
    required String talkLabel,
    required String notNowLabel,
    required List<SediTrayAnswer> answers,
    required String channelId,
    required String payload,
    required String answerPayload,
  }) async {
    if (!supported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('showGrown', <String, Object?>{
        'id': id,
        'rtl': rtl,
        'title': title,
        'body': body,
        'question': question,
        'talkLabel': talkLabel,
        'notNowLabel': notNowLabel,
        'answers': answers.map((a) => a.toMap()).toList(),
        'channelId': channelId,
        'payload': payload,
        'answerPayload': answerPayload,
      });
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// Registers the Dart entry the native answer receiver starts in the background (raw callback handle).
  static Future<bool> registerBackground(int handle) async {
    if (!supported) return false;
    try {
      return (await _channel.invokeMethod<bool>('registerBackground', <String, Object?>{'handle': handle})) == true;
    } catch (_) {
      return false;
    }
  }

  /// Answers tapped in the tray that Dart has not processed yet (the native receiver keeps them until delivered).
  static Future<List<SediTrayPendingAnswer>> drainPending() async {
    if (!supported) return const <SediTrayPendingAnswer>[];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('drainPending');
      final out = <SediTrayPendingAnswer>[];
      for (final item in raw ?? const <dynamic>[]) {
        if (item is! Map) continue;
        final id = item['id'];
        final answer = item['answer']?.toString() ?? '';
        final payload = item['payload']?.toString() ?? '';
        if (id is int && answer.isNotEmpty) {
          out.add(SediTrayPendingAnswer(id: id, answer: answer, payload: payload));
        }
      }
      return out;
    } catch (_) {
      return const <SediTrayPendingAnswer>[];
    }
  }

  /// The «talk with Sedi» tap on the grown notification (once), or null.
  static Future<SediTrayLaunch?> takeLaunch() async {
    if (!supported) return null;
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('takeLaunch');
      if (raw == null) return null;
      final id = raw['id'];
      final payload = raw['payload']?.toString() ?? '';
      if (id is! int || payload.isEmpty) return null;
      return SediTrayLaunch(id: id, payload: payload);
    } catch (_) {
      return null;
    }
  }
}
