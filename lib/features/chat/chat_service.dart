import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../../../core/auth/auth_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/user_preferences.dart';

/// ------------------------------------------------------------
/// ChatService
///
/// RESPONSIBILITY:
/// - Send user message to backend (or mock)
/// - Return raw assistant reply
/// - NO UI logic
/// - NO personality / intent logic
/// ------------------------------------------------------------
class ChatService {
  /// Build request headers with optional Authorization
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Minimal mock response for frontend development
  /// Personality & intelligence handled elsewhere
  String _mockReply(String userMessage) {
    final replies = <String>[
      'I understand.',
      'Got it.',
      'Please continue.',
      'Thanks for sharing.',
      'I am processing your message.',
    ];

    return replies[Random().nextInt(replies.length)];
  }

  /// Send message to backend or mock
  Future<String> sendMessage(String userMessage) async {
    // ---------------- LOCAL MODE ----------------
    if (AppConfig.useLocalMode) {
      await Future.delayed(
        Duration(milliseconds: 400 + Random().nextInt(600)),
      );
      return _mockReply(userMessage);
    }

    // ---------------- BACKEND MODE ----------------
    try {
      // Get user credentials from UserPreferences
      final userName = await UserPreferences.getUserName();
      final userPassword = await UserPreferences.getUserPassword();
      
      if (userName == null || userName.isEmpty || userPassword == null || userPassword.isEmpty) {
        return 'AUTH_REQUIRED';
      }

      // Get current language
      final currentLang = await UserPreferences.getUserLanguage();

      // Backend uses /interact/chat with query parameters
      final uri = Uri.parse('${AppConfig.baseUrl}/interact/chat').replace(
        queryParameters: {
          'name': userName,
          'secret_key': userPassword, // Backend uses secret_key, we use password
          'message': userMessage,
          'lang': currentLang,
        },
      );

      final headers = await _buildHeaders();

      final response = await http.post(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Backend returns 'message' field, not 'reply'
        return body['message']?.toString() ?? '';
      }

      if (response.statusCode == 401 || response.statusCode == 404) {
        return 'AUTH_REQUIRED';
      }

      return 'SERVER_ERROR_${response.statusCode}';
    } catch (e) {
      // Better error handling for debugging
      return 'NETWORK_ERROR: ${e.toString()}';
    }
  }
}
