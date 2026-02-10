/// Rolling 7-day vitals history (SharedPreferences). Key: vitals_history_<userId>.
/// Single responsibility: storage, merge/dedup/cap/purge, derived stats.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'vitals_cache.dart';

const String _historyKeyPrefix = 'vitals_history_';

/// Max items to keep in history.
const int maxHistoryItems = 50;

/// Max age of entries (days).
const int maxHistoryDays = 7;

/// Derived stats for the 7-day window.
class VitalsHistoryStats {
  /// Rounded average heart rate in window; null if no HR data.
  final int? avgHeartRate7d;
  /// Min heart rate in window; null if no HR data.
  final int? minHeartRate7d;
  /// Max heart rate in window; null if no HR data.
  final int? maxHeartRate7d;
  /// Number of records in the 7-day window.
  final int countRecords7d;

  const VitalsHistoryStats({
    this.avgHeartRate7d,
    this.minHeartRate7d,
    this.maxHeartRate7d,
    this.countRecords7d = 0,
  });
}

/// Dedupe key: created_at truncated to minute when available (avoids duplicate on every open);
/// else fallback "nodate" so entries without timestamp still dedupe by heart_rate.
String _dedupeKey(CachedVitals v) {
  String t;
  if (v.createdAt != null) {
    final d = v.createdAt!;
    t = DateTime.utc(d.year, d.month, d.day, d.hour, d.minute).toIso8601String();
  } else {
    t = 'nodate';
  }
  final hr = v.heartRate;
  if (hr != null) return '${t}_$hr';
  return t;
}

/// Remove entries older than [maxHistoryDays] from [list] (assumed newest first).
List<CachedVitals> purgeOlderThan7Days(List<CachedVitals> list) {
  final cutoff = DateTime.now().subtract(Duration(days: maxHistoryDays));
  return list.where((e) => (e.createdAt ?? DateTime(0)).isAfter(cutoff)).toList();
}

/// Merge [newEntry] into [current] (newest first), dedupe, cap at [maxHistoryItems], purge older than 7 days.
/// Returns the new list (caller may persist).
List<CachedVitals> mergeAndTrim(List<CachedVitals> current, CachedVitals newEntry) {
  final seen = <String>{};
  final combined = <CachedVitals>[newEntry];
  for (final e in current) {
    final k = _dedupeKey(e);
    if (seen.contains(k)) continue;
    seen.add(k);
    combined.add(e);
  }
  combined.sort((a, b) {
    final at = a.createdAt ?? DateTime(0);
    final bt = b.createdAt ?? DateTime(0);
    return bt.compareTo(at);
  });
  final capped = combined.take(maxHistoryItems).toList();
  return purgeOlderThan7Days(capped);
}

/// Compute stats from a list (already in 7-day window).
VitalsHistoryStats computeStats(List<CachedVitals> list) {
  final withHr = list.where((e) => e.heartRate != null).toList();
  if (withHr.isEmpty) {
    return VitalsHistoryStats(countRecords7d: list.length);
  }
  double sum = 0;
  int minHr = withHr.first.heartRate!.round();
  int maxHr = minHr;
  for (final e in withHr) {
    final hr = e.heartRate!;
    sum += hr;
    final h = hr.round();
    if (h < minHr) minHr = h;
    if (h > maxHr) maxHr = h;
  }
  final avg = (sum / withHr.length).round();
  return VitalsHistoryStats(
    avgHeartRate7d: avg,
    minHeartRate7d: minHr,
    maxHeartRate7d: maxHr,
    countRecords7d: list.length,
  );
}

Future<List<CachedVitals>> _loadHistoryRaw(int userId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_historyKeyPrefix$userId');
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>?;
    if (decoded == null) return [];
    final list = <CachedVitals>[];
    for (final e in decoded) {
      if (e is Map<String, dynamic>) {
        final v = CachedVitals.fromJson(e);
        if (v != null) list.add(v);
      } else if (e is Map) {
        final v = CachedVitals.fromJson(Map<String, dynamic>.from(e));
        if (v != null) list.add(v);
      }
    }
    return list;
  } catch (_) {
    return [];
  }
}

Future<bool> _saveHistoryRaw(int userId, List<CachedVitals> list) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
  return prefs.setString('$_historyKeyPrefix$userId', encoded);
}

/// Append/merge one entry into user's history; then trim (cap 50, purge >7d).
Future<void> appendVitalsHistoryEntry(int userId, CachedVitals entry) async {
  final current = await _loadHistoryRaw(userId);
  final merged = mergeAndTrim(current, entry);
  await _saveHistoryRaw(userId, merged);
}

/// Load recent history for user (newest first). Purges entries older than 7 days on read.
Future<List<CachedVitals>> loadVitalsHistory(int userId) async {
  final list = await _loadHistoryRaw(userId);
  final purged = purgeOlderThan7Days(list);
  if (purged.length != list.length) {
    await _saveHistoryRaw(userId, purged);
  }
  return purged;
}

/// Namespace for history so callers can use VitalsHistory.appendEntry / getRecentHistory / computeStats.
class VitalsHistory {
  VitalsHistory._();
  static Future<void> appendEntry(int userId, CachedVitals entry) => appendVitalsHistoryEntry(userId, entry);
  static Future<List<CachedVitals>> getRecentHistory(int userId) => loadVitalsHistory(userId);
}
