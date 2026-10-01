import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../../core/auth/user_identity_service.dart';
import '../../data/dto/notifications/notification_feedback_dto.dart';
import '../../data/dto/notifications/notification_list_response_dto.dart';
import '../../data/models/notification_item.dart';

class NotificationsInboxPageResult {
  final List<NotificationItem> items;
  final String? nextCursor;
  final bool hasMore;
  final int? unreadCount;
  final int? total;

  const NotificationsInboxPageResult({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
    this.unreadCount,
    this.total,
  });
}

class NotificationsService {
  final ApiClient _apiClient;

  NotificationsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Parses POST ACK payloads (`data` object) without treating success as PARSE_ERROR.
  static Map<String, dynamic>? parseAckData(Object? dataJson) {
    if (dataJson is Map) {
      return Map<String, dynamic>.from(dataJson);
    }
    return null;
  }

  /// Parse unread count from a legacy Map-shaped response.
  /// Authority is backend unread_count only; page count/list length are not badges.
  static int parseUnreadCount(Map<String, dynamic> resp) {
    if (resp['ok'] != true) return 0;
    final data = resp['data'] as Map<String, dynamic>?;
    if (data == null) return 0;
    final unread = data['unread_count'];
    if (unread is int) return unread < 0 ? 0 : unread;
    return 0;
  }

  Future<ApiResponse<NotificationsInboxPageResult>> listInboxPage({
    bool unreadOnly = false,
    int limit = 20,
    String? cursor,
  }) async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      return const ApiResponse<NotificationsInboxPageResult>(
        ok: false,
        data: null,
        error: ApiError(
          code: 'USER_ID_REQUIRED',
          message: 'User identity is required to load notifications.',
        ),
      );
    }

    final safeLimit = limit < 1 ? 20 : (limit > 50 ? 50 : limit);
    final queryParams = <String, String>{
      'user_id': userId.toString(),
      'limit': safeLimit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    // All -> GET /notifications/ ; Unread -> GET /notifications/unread
    final path = unreadOnly ? '/notifications/unread' : '/notifications/';
    final response = await _apiClient.get<NotificationListResponseDto>(
      path,
      queryParams: queryParams,
      parser: (json) {
        if (json is Map) {
          return NotificationListResponseDto.fromJson(
              Map<String, dynamic>.from(json));
        }
        return null;
      },
    );

    final payload = response.data;
    final dtos = payload?.notifications ?? const [];
    final items = dtos
        .map((dto) => NotificationItem.fromDto(dto))
        .toList(growable: false);

    final deduped = <int, NotificationItem>{};
    for (final item in items) {
      deduped[item.id] = item;
    }
    // Prefer sentAt when present; else createdAt (backend orders by sent_at).
    final sorted = deduped.values.toList()
      ..sort((a, b) {
        final aTs = a.sentAt ?? a.createdAt;
        final bTs = b.sentAt ?? b.createdAt;
        final cmp = bTs.compareTo(aTs);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });

    return ApiResponse<NotificationsInboxPageResult>(
      ok: response.ok,
      data: NotificationsInboxPageResult(
        items: sorted,
        nextCursor: payload?.nextCursor,
        hasMore: payload?.hasMore ?? false,
        unreadCount: payload?.unreadCount,
        total: payload?.total,
      ),
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  /// Backward-compatible helper used by health services.
  Future<ApiResponse<List<NotificationItem>>> listInbox({
    bool unreadOnly = false,
    int limit = 50,
    String? cursor,
  }) async {
    final page = await listInboxPage(
      unreadOnly: unreadOnly,
      limit: limit,
      cursor: cursor,
    );
    return ApiResponse<List<NotificationItem>>(
      ok: page.ok,
      data: page.data?.items ?? const <NotificationItem>[],
      error: page.error,
      statusCode: page.statusCode,
    );
  }

  Future<ApiResponse<void>> markRead(int id) async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      return const ApiResponse<void>(
        ok: false,
        error: ApiError(
          code: 'USER_ID_REQUIRED',
          message: 'User identity is required to mark notifications as read.',
        ),
      );
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/notifications/$id/mark-read',
      queryParams: {'user_id': userId.toString()},
      parser: NotificationsService.parseAckData,
    );
    return ApiResponse<void>(
      ok: response.ok,
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  /// Soft-hide from Inbox projection only. Never hard-deletes. Never marks read.
  Future<ApiResponse<void>> hideInbox(List<int> notificationIds) async {
    final unique = <int>{
      for (final id in notificationIds)
        if (id > 0) id,
    }.toList(growable: false);
    if (unique.isEmpty) {
      return const ApiResponse<void>(
        ok: false,
        error: ApiError(
          code: 'NOTIFICATION_IDS_REQUIRED',
          message: 'At least one notification id is required to hide.',
        ),
      );
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/notifications/inbox/hide',
      body: {'notification_ids': unique},
      parser: NotificationsService.parseAckData,
    );
    return ApiResponse<void>(
      ok: response.ok,
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  /// Canonical unread SENT-history count for badge (never invents local authority).
  /// Uses GET /notifications/ and trusts backend unread_count only.
  Future<ApiResponse<int>> fetchUnreadCount({int limit = 1}) async {
    final page = await listInboxPage(unreadOnly: false, limit: limit);
    if (!page.ok) {
      return ApiResponse<int>(
        ok: false,
        data: 0,
        error: page.error,
        statusCode: page.statusCode,
      );
    }
    final unread = page.data?.unreadCount ?? 0;
    return ApiResponse<int>(
      ok: true,
      data: unread < 0 ? 0 : unread,
      statusCode: page.statusCode,
    );
  }

  Future<ApiResponse<void>> sendFeedback(
    int id, {
    required bool liked,
    String? reason,
    String? action,
  }) async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      return const ApiResponse<void>(
        ok: false,
        error: ApiError(
          code: 'USER_ID_REQUIRED',
          message: 'User identity is required to send notification feedback.',
        ),
      );
    }

    if (action != null && action.isNotEmpty) {
      final response = await _apiClient.post<Object?>(
        '/notifications/$id/feedback',
        queryParams: {'user_id': userId.toString()},
        body: {
          'action': action,
          'client_ts': DateTime.now().toIso8601String(),
        },
        parser: (_) => null,
      );
      return ApiResponse<void>(
        ok: response.ok,
        error: response.error,
        statusCode: response.statusCode,
      );
    }

    final dto = NotificationFeedbackDto(
      liked: liked,
      timestamp: DateTime.now().toIso8601String(),
      reason: reason,
    );
    final response = await _apiClient.post<Object?>(
      '/notifications/$id/feedback',
      queryParams: {'user_id': userId.toString()},
      body: dto.toJson(),
      parser: (_) => null,
    );
    return ApiResponse<void>(
      ok: response.ok,
      error: response.error,
      statusCode: response.statusCode,
    );
  }
}
