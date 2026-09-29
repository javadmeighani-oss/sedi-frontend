"""Bounded persistent pending notification actions (A4).

Survives background/terminated action taps. Stores only notification_id,
action_id, and client timestamp — no title/body/health/raw context.
"""

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingNotificationAction {
  final int notificationId;
  final String actionId;
  final String clientTs;

  const PendingNotificationAction({
    required this.notificationId,
    required this.actionId,
    required this.clientTs,
  });

  Map<String, dynamic> toJson() => {
        'notification_id': notificationId,
        'action_id': actionId,
        'client_ts': clientTs,
      };

  static PendingNotificationAction? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = int.tryParse('${map['notification_id'] ?? ''}');
    final action = (map['action_id'] ?? '').toString().trim();
    final ts = (map['client_ts'] ?? '').toString().trim();
    if (id == null || id <= 0 || action.isEmpty) return null;
    return PendingNotificationAction(
      notificationId: id,
      actionId: action,
      clientTs: ts.isEmpty ? DateTime.now().toUtc().toIso8601String() : ts,
    );
  }

  String get dedupeKey => '$notificationId|$actionId';
}

class PendingNotificationActions {
  static const prefsKey = 'a4_pending_notification_actions_v1';
  static const maxItems = 20;

  /// Test/double injection; production uses SharedPreferences.
  static Future<SharedPreferences> Function()? prefsLoader;

  static Future<SharedPreferences> _prefs() async {
    final loader = prefsLoader;
    if (loader != null) return loader();
    return SharedPreferences.getInstance();
  }

  static Future<List<PendingNotificationAction>> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <PendingNotificationAction>[];
      for (final item in decoded) {
        final parsed = PendingNotificationAction.tryParse(item);
        if (parsed != null) out.add(parsed);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(List<PendingNotificationAction> items) async {
    final prefs = await _prefs();
    final trimmed = items.length <= maxItems
        ? items
        : items.sublist(items.length - maxItems);
    await prefs.setString(
      prefsKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList(growable: false)),
    );
  }

  static Future<void> enqueue({
    required int notificationId,
    required String actionId,
    String? clientTs,
  }) async {
    if (notificationId <= 0) return;
    final action = actionId.trim();
    if (action.isEmpty) return;
    final item = PendingNotificationAction(
      notificationId: notificationId,
      actionId: action,
      clientTs: clientTs ?? DateTime.now().toUtc().toIso8601String(),
    );
    final existing = await load();
    final next = <PendingNotificationAction>[
      for (final e in existing)
        if (e.dedupeKey != item.dedupeKey) e,
      item,
    ];
    await _save(next);
  }

  static Future<void> remove({
    required int notificationId,
    required String actionId,
  }) async {
    final existing = await load();
    final key = '$notificationId|$actionId';
    await _save([
      for (final e in existing)
        if (e.dedupeKey != key) e,
    ]);
  }

  /// Drain queue: [send] returns true on success (item removed); false keeps item.
  static Future<void> drain(
    Future<bool> Function(PendingNotificationAction item) send,
  ) async {
    final items = await load();
    for (final item in items) {
      try {
        final ok = await send(item);
        if (ok) {
          await remove(
            notificationId: item.notificationId,
            actionId: item.actionId,
          );
        }
      } catch (_) {
        // Transient — keep for next drain.
      }
    }
  }
}
