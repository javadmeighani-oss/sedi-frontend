import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../data/dto/chat/chat_send_request.dart';
import '../../data/dto/chat/chat_send_response.dart';

/// Parses SSE from POST /interact/chat/stream (governed final-answer chunk stream).
class ChatStreamClient {
  http.Client? _client;
  StreamSubscription<String>? _sub;
  bool _cancelled = false;

  Future<ChatSendResponse?> sendStreaming({
    required String message,
    String? language,
    int? sourceNotificationId,
    String? conversationId,
    int? healthSubjectId,
    required void Function(String delta) onDelta,
    void Function(Map<String, dynamic> meta)? onMetadata,
  }) async {
    _cancelled = false;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return null;

    final uri = Uri.parse('${AppConfig.baseUrl}/interact/chat/stream');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };
    if (language != null && language.trim().isNotEmpty) {
      headers['Accept-Language'] = language.trim();
    }

    String? deviceTimezone;
    try {
      deviceTimezone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      deviceTimezone = null; // the backend falls back to its own resolution
    }

    final body = jsonEncode(ChatSendRequest(
      message: message,
      timezone: deviceTimezone,
      sourceNotificationId: sourceNotificationId,
      conversationId: conversationId,
      healthSubjectId: healthSubjectId,
    ).toJson());

    _client = http.Client();
    final request = http.Request('POST', uri)
      ..headers.addAll(headers)
      ..body = body;

    final streamed = await _client!.send(request).timeout(
          const Duration(seconds: 90),
        );

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      if (kDebugMode) {
        debugPrint('[ChatStream] HTTP ${streamed.statusCode}');
      }
      return null;
    }

    ChatSendResponse? finalResponse;
    String event = 'message';
    final buffer = StringBuffer();

    await for (final chunk in streamed.stream.transform(utf8.decoder)) {
      if (_cancelled) break;
      buffer.write(chunk);
      var raw = buffer.toString();
      while (true) {
        final idx = raw.indexOf('\n\n');
        if (idx < 0) {
          buffer
            ..clear()
            ..write(raw);
          break;
        }
        final block = raw.substring(0, idx);
        raw = raw.substring(idx + 2);
        buffer
          ..clear()
          ..write(raw);

        String? dataLine;
        for (final line in block.split('\n')) {
          if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            dataLine = line.substring(5).trim();
          }
        }
        if (dataLine == null) continue;
        Map<String, dynamic>? map;
        try {
          final decoded = jsonDecode(dataLine);
          if (decoded is Map) map = Map<String, dynamic>.from(decoded);
        } catch (_) {
          continue;
        }
        if (map == null) continue;

        switch (event) {
          case 'delta':
            final text = map['text']?.toString() ?? '';
            if (text.isNotEmpty) {
              onDelta(text);
              // Yield so Flutter can paint progressive SPEAKING updates when
              // multiple SSE events arrive in one network read / microtask batch.
              await Future<void>.delayed(Duration.zero);
            }
            break;
          case 'metadata':
            onMetadata?.call(map);
            break;
          case 'final':
            finalResponse = ChatSendResponse.fromJson(map);
            break;
          case 'error':
            return null;
        }
      }
    }

    return finalResponse;
  }

  void cancel() {
    _cancelled = true;
    _sub?.cancel();
    _client?.close();
    _client = null;
  }

  void dispose() => cancel();
}
