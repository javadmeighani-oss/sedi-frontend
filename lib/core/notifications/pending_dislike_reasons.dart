// Notifications disliked from the tray whose REASON Sedi still wants to ask (P7).
//
// The tray's Dislike button has no UI, so the reason is asked the next time the app is in the foreground. Stores only
// notification ids - no title, body or health context.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingDislikeReasons {
  static const prefsKey = 'p7_pending_dislike_reason_ids_v1';
  static const maxItems = 5;

  /// Test/double injection; production uses SharedPreferences.
  static Future<SharedPreferences> Function()? prefsLoader;

  static Future<SharedPreferences> _prefs() async {
    final loader = prefsLoader;
    if (loader != null) return loader();
    return SharedPreferences.getInstance();
  }

  static Future<List<int>> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final v in decoded)
          if (int.tryParse('$v') != null && int.parse('$v') > 0) int.parse('$v'),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(List<int> ids) async {
    final prefs = await _prefs();
    final trimmed = ids.length <= maxItems ? ids : ids.sublist(ids.length - maxItems);
    await prefs.setString(prefsKey, jsonEncode(trimmed));
  }

  /// Remember that [notificationId] was disliked without a reason.
  static Future<void> add(int notificationId) async {
    if (notificationId <= 0) return;
    final existing = await load();
    if (existing.contains(notificationId)) return;
    await _save([...existing, notificationId]);
  }

  /// The next notification to ask about (oldest first), removed so the user is asked only once.
  static Future<int?> takeNext() async {
    final existing = await load();
    if (existing.isEmpty) return null;
    final id = existing.first;
    await _save(existing.sublist(1));
    return id;
  }
}
