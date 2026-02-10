/// Pull-sync: fetch recent notifications, detect new, show local notification for new items.
/// Call sync once after user verification success (without breaking flows).
/// Seen IDs stored in a rolling window (max 200, newest first). syncOnce is guarded against concurrent runs.
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/utils/user_profile_manager.dart';
import '../../../data/models/notification.dart' as sedi;
import '../data/notification_service.dart';
import '../utils/notification_ui_mapping.dart';

const String _keySeenIds = 'notification_sync_seen_ids';
const String _keyLastSeenId = 'notification_sync_last_seen_id';
const String _keyLastSeenTimestamp = 'notification_sync_last_seen_ts';
const int _maxSeenIds = 200;

/// Merges new IDs (newest first) with existing ordered list and returns at most [max] ids (newest first).
/// Used for rolling-window storage; exposed for tests.
List<String> mergeSeenIdsRollingWindow(List<String> existingOrdered, List<String> newIds, int max) {
  final merged = [...newIds, ...existingOrdered.where((id) => !newIds.contains(id))];
  return merged.take(max).toList();
}

class NotificationSync {
  static final NotificationService _service = NotificationService();
  static bool _syncing = false;

  /// Fetch recent notifications for current user; show local notification for new items.
  /// Uses SharedPreferences: seen IDs in a rolling window (newest first, max 200).
  /// Guarded against concurrent runs (early return if already syncing).
  static Future<void> syncOnce() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final profile = await UserProfileManager.loadProfile();
      final userId = profile.userId;
      if (userId == null) return;
      final resp = await _service.getNotifications(userId: userId, limit: 30);
      if (resp['ok'] != true) return;
      final data = resp['data'] as Map<String, dynamic>?;
      final list = data?['notifications'] as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final seenRaw = prefs.getString(_keySeenIds) ?? '';
      // Order: newest first (list from API is typically newest first)
      final existingOrdered = seenRaw.isEmpty ? <String>[] : seenRaw.split(',').where((s) => s.isNotEmpty).toList();
      final seenSet = existingOrdered.toSet();
      final newIds = <String>[];
      for (final e in list) {
        try {
          final n = sedi.Notification.fromJson(Map<String, dynamic>.from(e as Map));
          if (!seenSet.contains(n.id)) {
            newIds.add(n.id);
            seenSet.add(n.id);
            await LocalNotificationsService.showNotification(
              id: n.id.hashCode.abs() % 100000,
              title: n.title?.isNotEmpty == true ? n.title! : defaultTitleForNotificationType(n.type),
              body: n.message,
              payload: n.id,
            );
          }
        } catch (_) {}
      }
      if (newIds.isEmpty) {
        return;
      }
      // Rolling window: newest first, cap at _maxSeenIds
      final toStore = mergeSeenIdsRollingWindow(existingOrdered, newIds, _maxSeenIds).join(',');
      await prefs.setString(_keySeenIds, toStore);
      final lastId = list.isNotEmpty ? (list.first as Map<String, dynamic>)['id']?.toString() : null;
      if (lastId != null) {
        await prefs.setString(_keyLastSeenId, lastId);
        await prefs.setInt(_keyLastSeenTimestamp, DateTime.now().millisecondsSinceEpoch);
      }
    } finally {
      _syncing = false;
    }
  }
}
