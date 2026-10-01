/// Bounded durable tray snapshot for same-ID processing restore (A4).
/// Stores only fields needed to re-show the original actionable tray —
/// no health/context PII expansion beyond the already-displayed title/body.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrayNotificationSnapshot {
  final int notificationId;
  final String title;
  final String body;
  final String channel;
  final String language;
  final String payloadJson;
  /// Raw gate4_actions JSON string (optional).
  final String? gate4ActionsRaw;
  /// Raw action_labels JSON string (optional).
  final String? actionLabelsRaw;

  const TrayNotificationSnapshot({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.channel,
    required this.language,
    required this.payloadJson,
    this.gate4ActionsRaw,
    this.actionLabelsRaw,
  });

  Map<String, dynamic> toJson() => {
        'notification_id': notificationId,
        'title': title,
        'body': body,
        'channel': channel,
        'language': language,
        'payload_json': payloadJson,
        if (gate4ActionsRaw != null) 'gate4_actions': gate4ActionsRaw,
        if (actionLabelsRaw != null) 'action_labels': actionLabelsRaw,
      };

  static TrayNotificationSnapshot? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = int.tryParse('${map['notification_id'] ?? ''}');
    if (id == null || id <= 0) return null;
    return TrayNotificationSnapshot(
      notificationId: id,
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      channel: (map['channel'] ?? 'engagement').toString(),
      language: (map['language'] ?? 'en').toString(),
      payloadJson: (map['payload_json'] ?? '').toString(),
      gate4ActionsRaw: map['gate4_actions']?.toString(),
      actionLabelsRaw: map['action_labels']?.toString(),
    );
  }

  Map<String, dynamic> actionData() {
    final data = <String, dynamic>{};
    if (gate4ActionsRaw != null && gate4ActionsRaw!.isNotEmpty) {
      data['gate4_actions'] = gate4ActionsRaw;
    }
    if (actionLabelsRaw != null && actionLabelsRaw!.isNotEmpty) {
      data['action_labels'] = actionLabelsRaw;
    }
    return data;
  }
}

class TrayNotificationSnapshotStore {
  static const prefsKey = 'a4_tray_notification_snapshots_v1';
  static const maxItems = 20;

  static Future<SharedPreferences> Function()? prefsLoader;

  static Future<SharedPreferences> _prefs() async {
    final loader = prefsLoader;
    if (loader != null) return loader();
    return SharedPreferences.getInstance();
  }

  static Future<List<TrayNotificationSnapshot>> loadAll() async {
    final prefs = await _prefs();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <TrayNotificationSnapshot>[];
      for (final item in decoded) {
        final parsed = TrayNotificationSnapshot.tryParse(item);
        if (parsed != null) out.add(parsed);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(List<TrayNotificationSnapshot> items) async {
    final prefs = await _prefs();
    final trimmed = items.length <= maxItems
        ? items
        : items.sublist(items.length - maxItems);
    await prefs.setString(
      prefsKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList(growable: false)),
    );
  }

  static Future<void> put(TrayNotificationSnapshot snap) async {
    if (snap.notificationId <= 0) return;
    final existing = await loadAll();
    final next = <TrayNotificationSnapshot>[
      for (final e in existing)
        if (e.notificationId != snap.notificationId) e,
      snap,
    ];
    await _save(next);
  }

  static Future<TrayNotificationSnapshot?> get(int notificationId) async {
    if (notificationId <= 0) return null;
    final all = await loadAll();
    for (final e in all) {
      if (e.notificationId == notificationId) return e;
    }
    return null;
  }

  static Future<void> remove(int notificationId) async {
    if (notificationId <= 0) return;
    final existing = await loadAll();
    await _save([
      for (final e in existing)
        if (e.notificationId != notificationId) e,
    ]);
  }

  @visibleForTesting
  static Future<void> clearForTest() async {
    final prefs = await _prefs();
    await prefs.remove(prefsKey);
  }
}
