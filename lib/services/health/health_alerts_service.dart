import '../../core/network/api_response.dart';
import '../../data/models/notification_item.dart';
import '../notifications/notifications_service.dart';

class HealthAlertsService {
  final NotificationsService _notificationsService;

  HealthAlertsService({NotificationsService? notificationsService})
      : _notificationsService = notificationsService ?? NotificationsService();

  Future<ApiResponse<List<NotificationItem>>> listHealthAlerts({
    required int userId,
    int limit = 50,
  }) async {
    final response = await _notificationsService.listInbox(
      unreadOnly: false,
      limit: limit * 2,
    );
    if (!response.ok) {
      return ApiResponse<List<NotificationItem>>(
        ok: false,
        data: const [],
        error: response.error,
        statusCode: response.statusCode,
      );
    }
    final alerts = <NotificationItem>[];
    final dedupe = <String>{};
    for (final item in response.data ?? const []) {
      if (!_isHealthAlert(item)) continue;
      final key = item.dedupeKey?.trim().isNotEmpty == true
          ? item.dedupeKey!
          : 'id:${item.id}:${item.createdAt.toUtc().toIso8601String()}';
      if (!dedupe.add(key)) continue;
      alerts.add(item);
    }
    alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ApiResponse<List<NotificationItem>>(
      ok: true,
      data: alerts.take(limit).toList(growable: false),
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> markRead(int id) =>
      _notificationsService.markRead(id);

  Future<ApiResponse<void>> sendFeedback(
    int id, {
    required bool liked,
  }) =>
      _notificationsService.sendFeedback(id, liked: liked);

  bool _isHealthAlert(NotificationItem item) {
    final channel = item.channel.toLowerCase();
    final priority = item.priority?.toLowerCase() ?? '';
    final title = item.title.toLowerCase();
    return channel == 'health_alert' ||
        priority == 'high' ||
        priority == 'critical' ||
        title.contains('ضربان');
  }
}
