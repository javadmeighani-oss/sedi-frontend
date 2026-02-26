import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../../data/models/heart_rate_event.dart';
import '../notifications/notifications_service.dart';

class HeartRateService {
  final NotificationsService _notificationsService;

  HeartRateService({NotificationsService? notificationsService})
      : _notificationsService = notificationsService ?? NotificationsService();

  Future<ApiResponse<List<HeartRateEvent>>> listHeartRate({
    required int userId,
    int limit = 50,
  }) async {
    // TODO(backend): switch to dedicated endpoint when available:
    // GET /device/events?user_id={userId}&event_type=heart_rate&limit={limit}
    final response = await _notificationsService.listInbox(
      unreadOnly: false,
      limit: limit * 2,
    );
    if (!response.ok) {
      return ApiResponse<List<HeartRateEvent>>(
        ok: false,
        data: const [],
        error: response.error,
        statusCode: response.statusCode,
      );
    }

    final result = <HeartRateEvent>[];
    final dedupe = <String>{};
    for (final item in response.data ?? const []) {
      final text = '${item.title} ${item.body}'.trim();
      final bpm = _extractBpm(text);
      if (bpm == null) continue;

      final key = item.dedupeKey?.trim().isNotEmpty == true
          ? item.dedupeKey!
          : 'notif:${item.id}:${item.createdAt.toUtc().toIso8601String()}:$bpm';
      if (!dedupe.add(key)) continue;

      result.add(
        HeartRateEvent(
          bpm: bpm,
          recordedAt: item.createdAt,
          quality: item.metadata?['quality']?.toString(),
          source: 'notification',
          stableKey: key,
        ),
      );
    }

    result.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final limited = result.take(limit).toList(growable: false);
    return ApiResponse<List<HeartRateEvent>>(
      ok: true,
      data: limited,
      statusCode: response.statusCode,
      error: limited.isEmpty
          ? const ApiError(
              code: 'NO_HEART_RATE_ENDPOINT',
              message:
                  'No dedicated heart-rate event listing endpoint available yet.',
            )
          : null,
    );
  }

  int? _extractBpm(String text) {
    if (text.isEmpty) return null;
    final bpmPattern = RegExp(r'(\d{2,3})\s*bpm', caseSensitive: false);
    final bpmMatch = bpmPattern.firstMatch(text);
    if (bpmMatch != null) {
      return int.tryParse(bpmMatch.group(1) ?? '');
    }
    final numberPattern = RegExp(r'(\d{2,3})');
    final numberMatch = numberPattern.firstMatch(text);
    if (numberMatch != null) {
      final value = int.tryParse(numberMatch.group(1) ?? '');
      if (value != null && value >= 30 && value <= 220) return value;
    }
    return null;
  }
}
