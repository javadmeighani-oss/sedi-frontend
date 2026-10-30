import 'package:flutter/foundation.dart';

import '../../../core/network/api_response.dart';
import '../../../data/dto/chat/chat_send_response.dart';
import '../../../services/chat/chat_service.dart';

/// A1 -> A3 speed (Javad 2026-10-30): Sedi's opener is made by the server (context, recap) and the chat is empty until
/// it arrives. A1 plays for three seconds anyway, so the moment the session is known to be valid the open request
/// starts; A3 picks the result up instead of asking again. One request, started earlier - never two.
class A3SessionPrefetch {
  A3SessionPrefetch._();

  /// An answer older than this is not "the opener of this visit" any more.
  static const Duration maxAge = Duration(seconds: 90);

  static Future<ApiResponse<ChatSendResponse>?>? _pending;
  static DateTime? _startedAt;

  static void start({
    required String language,
    ChatService? service,
    @visibleForTesting Future<ApiResponse<ChatSendResponse>?> Function(String language)? opener,
    DateTime? now,
  }) {
    if (_pending != null) return;
    _startedAt = now ?? DateTime.now();
    _pending = opener != null ? opener(language) : _open(language, service ?? ChatService());
  }

  /// Hands the started request over exactly once; null when nothing (fresh enough) was started.
  static Future<ApiResponse<ChatSendResponse>?>? take({DateTime? now}) {
    final pending = _pending;
    final at = _startedAt;
    _pending = null;
    _startedAt = null;
    if (pending == null || at == null) return null;
    if ((now ?? DateTime.now()).difference(at) > maxAge) return null;
    return pending;
  }

  static Future<ApiResponse<ChatSendResponse>?> _open(String language, ChatService service) async {
    try {
      return await service.openSession(language: language);
    } catch (e) {
      if (kDebugMode) debugPrint('[A3SessionPrefetch] session/open failed: $e');
      return null;
    }
  }

  @visibleForTesting
  static void reset() {
    _pending = null;
    _startedAt = null;
  }
}
