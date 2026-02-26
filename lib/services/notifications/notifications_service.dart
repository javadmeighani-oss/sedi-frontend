import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../../core/auth/user_identity_service.dart';
import '../../data/dto/notifications/notification_feedback_dto.dart';
import '../../data/dto/notifications/notification_list_response_dto.dart';
import '../../data/models/notification_item.dart';

class NotificationsService {
  final ApiClient _apiClient;

  NotificationsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<NotificationItem>>> listInbox({
    bool unreadOnly = false,
    int limit = 50,
    String? cursor,
  }) async {
    final userId = await UserIdentityService.resolveUserId();
    if (userId == null) {
      return const ApiResponse<List<NotificationItem>>(
        ok: false,
        data: [],
        error: ApiError(
          code: 'USER_ID_REQUIRED',
          message: 'User identity is required to load notifications.',
        ),
      );
    }

    final queryParams = <String, String>{
      'user_id': userId.toString(),
      'limit': limit.toString(),
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

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
    final sorted = deduped.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ApiResponse<List<NotificationItem>>(
      ok: response.ok,
      data: sorted,
      error: response.error,
      statusCode: response.statusCode,
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

    final response = await _apiClient.post<Object?>(
      '/notifications/$id/mark-read',
      queryParams: {'user_id': userId.toString()},
      parser: (_) => null,
    );
    return ApiResponse<void>(
      ok: response.ok,
      error: response.error,
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> sendFeedback(
    int id, {
    required bool liked,
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

    final dto = NotificationFeedbackDto(
      liked: liked,
      timestamp: DateTime.now().toIso8601String(),
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
