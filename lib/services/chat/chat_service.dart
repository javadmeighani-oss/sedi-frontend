import 'package:flutter/foundation.dart';

import '../../core/auth/user_identity_service.dart';
import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../../data/dto/chat/chat_send_request.dart';
import '../../data/dto/chat/chat_send_response.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<ChatSendResponse>> sendMessage({
    required String message,
    String? language,
    int? userId,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      return const ApiResponse<ChatSendResponse>(
        ok: false,
        error: ApiError(
            code: 'VALIDATION_ERROR', message: 'Message cannot be empty'),
      );
    }

    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == null) {
      return const ApiResponse<ChatSendResponse>(
        ok: false,
        error: ApiError(
          code: 'USER_ID_REQUIRED',
          message: 'User identity is required before sending chat messages.',
        ),
      );
    }

    final request = ChatSendRequest(
      userId: resolvedUserId,
      message: text,
    );

    final headers = <String, String>{};
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }

    if (kDebugMode) {
      debugPrint('[ChatService] POST /interact/chat');
      debugPrint(
          '[ChatService] payload: user_id=$resolvedUserId message_len=${text.length}');
    }

    final response = await _apiClient.post<ChatSendResponse>(
      '/interact/chat',
      body: request.toJson(),
      extraHeaders: headers.isEmpty ? null : headers,
      parser: (json) {
        if (json is Map) {
          return ChatSendResponse.fromJson(Map<String, dynamic>.from(json));
        }
        return null;
      },
    );

    if (kDebugMode) {
      debugPrint(
        '[ChatService] envelope: ok=${response.ok} status=${response.statusCode} error=${response.error?.code}',
      );
    }
    return response;
  }

  Future<int?> _resolveUserId(int? explicitUserId) async {
    if (explicitUserId != null && explicitUserId > 0) return explicitUserId;
    final resolved = await UserIdentityService.resolveUserId();
    if (resolved != null) return resolved;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;
    return UserIdentityService.resolveUserId(forceRefresh: true);
  }
}
