import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/preferences/notification_prefs.dart';

/// A read-only snapshot of the backend notification preferences (UI channel keys).
class NotificationPrefsView {
  final Map<String, bool> channels;
  final bool quietEnabled;
  final String quietStart;
  final String quietEnd;
  final String engagement;

  const NotificationPrefsView({
    required this.channels,
    required this.quietEnabled,
    required this.quietStart,
    required this.quietEnd,
    required this.engagement,
  });
}

/// Syncs notification preferences with backend GET/PUT /notifications/prefs.
class NotificationPrefsRepository {
  final ApiClient _client;

  NotificationPrefsRepository({ApiClient? client})
      : _client = client ?? ApiClient();

  static const Map<String, String> _uiToBackendChannel = {
    'companion': 'companion',
    'health_alert': 'health_alert',
    'medication': 'reminder_medication',
    'appointment': 'reminder_appointment',
    'system': 'reminder_system',
  };

  static const Map<String, String> _backendToUiChannel = {
    'companion': 'companion',
    'health_alert': 'health_alert',
    'reminder_medication': 'medication',
    'reminder_appointment': 'appointment',
    'reminder_system': 'system',
  };

  static String engagementToUi(int level) {
    if (level <= 0) return 'low';
    if (level >= 2) return 'high';
    return 'normal';
  }

  static int engagementToBackend(String level) {
    switch (level) {
      case 'low':
        return 0;
      case 'high':
        return 2;
      default:
        return 1;
    }
  }

  /// Reads the backend preferences (no local caching). Null when unavailable.
  Future<NotificationPrefsView?> fetch({required int userId}) async {
    final response = await _client.getRaw(
      '/notifications/prefs',
      queryParams: {'user_id': userId.toString()},
    );
    if (!response.ok || response.data == null) return null;
    final prefs = response.data!;
    final channels = <String, bool>{};
    final rawChannels = prefs['channels'];
    for (final entry in _backendToUiChannel.entries) {
      final v = rawChannels is Map ? rawChannels[entry.key] : null;
      channels[entry.value] = v is bool ? v : true;
    }
    final quiet = prefs['quiet_hours'];
    final enabled = quiet is Map && quiet['enabled'] == true;
    final start = quiet is Map ? quiet['start']?.toString() : null;
    final end = quiet is Map ? quiet['end']?.toString() : null;
    final level = prefs['engagement_level'];
    return NotificationPrefsView(
      channels: channels,
      quietEnabled: enabled,
      quietStart: (start == null || start.isEmpty) ? '22:30' : start,
      quietEnd: (end == null || end.isEmpty) ? '07:30' : end,
      engagement: engagementToUi(level is int ? level : 1),
    );
  }

  /// Load from backend; cache locally on success. Falls back to local cache.
  Future<void> loadAndCache({required int userId}) async {
    final response = await _client.getRaw(
      '/notifications/prefs',
      queryParams: {'user_id': userId.toString()},
    );
    if (!response.ok || response.data == null) {
      return;
    }

    final prefs = response.data!;

    final channels = prefs['channels'];
    if (channels is Map) {
      for (final entry in _backendToUiChannel.entries) {
        final value = channels[entry.key];
        if (value is bool) {
          await NotificationPrefs.setChannelEnabled(entry.value, value);
        }
      }
    }

    final quiet = prefs['quiet_hours'];
    if (quiet is Map) {
      final enabled = quiet['enabled'] == true;
      final start = quiet['start']?.toString();
      final end = quiet['end']?.toString();
      if (enabled && start != null && start.isNotEmpty) {
        await NotificationPrefs.setQuietHoursStart(start);
      }
      if (enabled && end != null && end.isNotEmpty) {
        await NotificationPrefs.setQuietHoursEnd(end);
      }
    }

    final engagement = prefs['engagement_level'];
    if (engagement is int) {
      await NotificationPrefs.setEngagementLevel(engagementToUi(engagement));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePartial({
    required int userId,
    Map<String, bool>? channelUpdates,
    String? quietStart,
    String? quietEnd,
    bool? quietEnabled,
    String? engagementLevel,
  }) async {
    final body = <String, dynamic>{};

    if (channelUpdates != null && channelUpdates.isNotEmpty) {
      final channels = <String, bool>{};
      channelUpdates.forEach((uiKey, enabled) {
        final backendKey = _uiToBackendChannel[uiKey];
        if (backendKey != null) {
          channels[backendKey] = enabled;
        }
      });
      if (channels.isNotEmpty) {
        body['channels'] = channels;
      }
    }

    if (quietStart != null || quietEnd != null || quietEnabled != null) {
      body['quiet_hours'] = {
        'enabled': quietEnabled ?? true,
        if (quietStart != null) 'start': quietStart,
        if (quietEnd != null) 'end': quietEnd,
      };
    }

    if (engagementLevel != null) {
      body['engagement_level'] = engagementToBackend(engagementLevel);
    }

    if (body.isEmpty) {
      return ApiResponse<Map<String, dynamic>>(ok: true, data: const {});
    }

    return _client.putRaw(
      '/notifications/prefs?user_id=$userId',
      body: body,
    );
  }
}
