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

  /// Register user with backend (onboarding)
  Future<String?> registerUser(String userName, String password, String language) async {
    // ---------------- LOCAL MODE ----------------
    if (AppConfig.useLocalMode) {
      return null; // No registration needed in local mode
    }

    // ---------------- BACKEND MODE ----------------
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/interact/introduce').replace(
        queryParameters: {
          'name': userName,
          'secret_key': password,
          'lang': language,
        },
      );

      final headers = await _buildHeaders();

      final response = await http.post(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['message']?.toString();
      }

      // If user already exists (400), that's okay - they can still chat
      if (response.statusCode == 400) {
        return null; // User already exists, continue
      }

      return 'REGISTRATION_ERROR_${response.statusCode}';
    } catch (e) {
      return 'REGISTRATION_ERROR: ${e.toString()}';
    }
  }

  /// Send message to backend or mock
  /// Returns response or 'SECURITY_CHECK_REQUIRED' if suspicious behavior detected
  Future<String> sendMessage(
    String userMessage, {
    String? userName,
    String? userPassword,
  }) async {
    // ---------------- LOCAL MODE ----------------
    if (AppConfig.useLocalMode) {
      await Future.delayed(
        Duration(milliseconds: 400 + Random().nextInt(600)),
      );
      return _mockReply(userMessage);
    }

    // ---------------- BACKEND MODE ----------------
    try {
      // Validate message is not empty
      if (userMessage.trim().isEmpty) {
        return 'NETWORK_ERROR: Message cannot be empty';
      }

      // Get current language
      final currentLang = await UserPreferences.getUserLanguage();

      // Build query parameters (name and password are optional for new users)
      final queryParams = <String, String>{
        'message': userMessage.trim(), // Ensure trimmed
        'lang': currentLang.isNotEmpty ? currentLang : 'en', // Default to 'en' if empty
      };

      // Add credentials if available (not required for initial conversations)
      if (userName != null && userName.isNotEmpty) {
        queryParams['name'] = userName.trim();
      }
      if (userPassword != null && userPassword.isNotEmpty) {
        queryParams['secret_key'] = userPassword.trim();
      }

      // Backend uses /interact/chat with query parameters
      // Use Uri.https or Uri.http to ensure proper encoding
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '/interact/chat',
        queryParameters: queryParams,
      );

      final headers = await _buildHeaders();

      // Debug: Print URL for troubleshooting (remove in production)
      print('[ChatService] Sending request to: ${uri.toString()}');

      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - Server may be down');
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // Check for security flag in response (backend AI detected suspicious behavior)
        if (body['requires_security_check'] == true) {
          return 'SECURITY_CHECK_REQUIRED';
        }
        
        // Backend returns 'message' field
        return body['message']?.toString() ?? '';
      }

      // Handle 422 (Validation Error) - usually means missing required parameter
      // This can happen if backend hasn't been restarted after code changes
      if (response.statusCode == 422) {
        final body = jsonDecode(response.body);
        final errorDetail = body['detail']?.toString() ?? 'Validation error';
        print('[ChatService] 422 Error: $errorDetail');
        
        // Check if error is about missing name/secret_key (backend not updated)
        if (errorDetail.contains('name') && errorDetail.contains('secret_key')) {
          return 'BACKEND_UPDATE_REQUIRED: Backend needs to be restarted. Please contact administrator.';
        }
        
        return 'SERVER_ERROR_422: $errorDetail';
      }

      if (response.statusCode == 401 || response.statusCode == 404) {
        // User not found - this is okay for new users, they can chat without registration
        // Backend will create user automatically or return error
        return 'AUTH_REQUIRED';
      }

      // Log error response body for debugging
      if (response.statusCode != 200) {
        try {
          final errorBody = jsonDecode(response.body);
          print('[ChatService] Error ${response.statusCode}: $errorBody');
        } catch (_) {
          print('[ChatService] Error ${response.statusCode}: ${response.body}');
        }
      }

      return 'SERVER_ERROR_${response.statusCode}';
    } catch (e) {
      // Better error handling for debugging
      print('[ChatService] Exception: $e');
      
      final errorString = e.toString().toLowerCase();
      
      // Check for specific connection errors
      if (errorString.contains('timeout') || 
          errorString.contains('connection refused') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('socketexception')) {
        return 'SERVER_CONNECTION_ERROR: سرور در دسترس نیست. لطفاً اتصال اینترنت را بررسی کنید یا با مدیر سیستم تماس بگیرید.';
      }
      
      return 'NETWORK_ERROR: ${e.toString()}';
    }
  }
}
