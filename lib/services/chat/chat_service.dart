import 'package:flutter/foundation.dart';

import '../../core/auth/auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error.dart';
import '../../core/network/api_response.dart';
import '../../data/dto/chat/chat_send_request.dart';
import '../../data/dto/chat/chat_send_response.dart';

/// Canonical V1 A3 chat client — JWT via [ApiClient]; no body user_id identity.
class ChatService {
  final ApiClient _apiClient;

  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<ChatSendResponse>> sendMessage({
    required String message,
    String? language,
    int? sourceNotificationId,
    String? conversationId,
    int? healthSubjectId,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      return const ApiResponse<ChatSendResponse>(
        ok: false,
        error: ApiError(
            code: 'VALIDATION_ERROR', message: 'Message cannot be empty'),
      );
    }

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      return const ApiResponse<ChatSendResponse>(
        ok: false,
        error: ApiError(
          code: 'AUTH_ERROR',
          message: 'Authentication required before sending chat messages.',
        ),
      );
    }

    final request = ChatSendRequest(
      message: text,
      sourceNotificationId: sourceNotificationId,
      conversationId: conversationId,
      healthSubjectId: healthSubjectId,
    );

    final headers = <String, String>{};
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }

    if (kDebugMode) {
      debugPrint('[ChatService] POST /interact/chat');
      debugPrint(
          '[ChatService] source_notification_id=$sourceNotificationId msg_len=${text.length}');
    }

    return _apiClient.post<ChatSendResponse>(
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
  }

  Future<ApiResponse<ChatSendResponse>> openSession({
    String? language,
    int? sourceNotificationId,
  }) async {
    final headers = <String, String>{};
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }
    final body = <String, dynamic>{};
    if (sourceNotificationId != null) {
      body['source_notification_id'] = sourceNotificationId;
    }
    return _apiClient.post<ChatSendResponse>(
      '/interact/session/open',
      body: body,
      extraHeaders: headers.isEmpty ? null : headers,
      parser: (json) {
        if (json is Map) {
          return ChatSendResponse.fromJson(Map<String, dynamic>.from(json));
        }
        return null;
      },
    );
  }
}
