import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../dto/interact_request.dart';

/// Result of a chat POST: status code and raw body (for ChatService to parse).
/// Backend /interact/chat returns raw JSON (not ApiResponse envelope).
class ChatRepositoryResult {
  final int statusCode;
  final String body;

  const ChatRepositoryResult({required this.statusCode, required this.body});
}

/// Sends chat request to POST /interact/chat with JSON body from [request].
/// Does not log secrets. Caller handles 422/502 and parses body.
Future<ChatRepositoryResult> sendChat(InteractRequest request) async {
  final baseUri = Uri.parse(AppConfig.baseUrl);
  final uri = Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.port,
    path: '/interact/chat',
  );
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };
  final token = await AuthService.getToken();
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  final body = jsonEncode(request.toJson());
  final response = await http
      .post(uri, headers: headers, body: body)
      .timeout(const Duration(seconds: 15), onTimeout: () {
    throw Exception('Connection timeout');
  });
  return ChatRepositoryResult(statusCode: response.statusCode, body: response.body);
}
