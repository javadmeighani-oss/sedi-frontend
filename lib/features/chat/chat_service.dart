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

  /// Get greeting from backend (for new or returning users)
  /// Returns greeting message or null if backend unavailable
  Future<String?> getGreeting({
    String? userName,
    String? userPassword,
    String? language,
  }) async {
    // ---------------- LOCAL MODE ---------------- 
    if (AppConfig.useLocalMode) {
      return null; // No greeting in local mode, use fallback
    }

    // ---------------- BACKEND MODE ---------------- 
    try {
      final currentLang = language ?? await UserPreferences.getUserLanguage();
      final lang = currentLang.isNotEmpty ? currentLang : 'en';

      // For new users without credentials, we can't use /greeting endpoint
      // Instead, we'll use /chat with a special greeting message
      // This allows backend to generate appropriate greeting
      final queryParams = <String, String>{
        'message': '__GREETING__', // Special marker for greeting
        'lang': lang,
      };

      // Add credentials if available
      if (userName != null && userName.isNotEmpty) {
        queryParams['name'] = userName.trim();
      }
      if (userPassword != null && userPassword.isNotEmpty) {
        queryParams['secret_key'] = userPassword.trim();
      }

      final baseUri = Uri.parse(AppConfig.baseUrl);
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '/interact/chat',
        queryParameters: queryParams,
      );

      final headers = await _buildHeaders();
      
      print('[ChatService] Greeting request - URL: ${uri.toString()}');
      print('[ChatService] Greeting request - Headers: $headers');
      print('[ChatService] Greeting request - Query params: $queryParams');
      
      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10), // Increased timeout for greeting
        onTimeout: () {
          print('[ChatService] Greeting request timeout after 10 seconds');
          throw Exception('Greeting timeout');
        },
      );
      
      print('[ChatService] Greeting response - Status: ${response.statusCode}');
      print('[ChatService] Greeting response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // Safe parsing - handle optional fields
        final message = body['message'];
        final userId = body['user_id'] as int?;
        
        print('[ChatService] Greeting success - message received from backend');
        print('[ChatService] Message length: ${message?.toString().length ?? 0}');
        print('[ChatService] User ID: $userId');
        
        if (message != null && message.toString().isNotEmpty) {
          // Return message with user_id if available (for anonymous users)
          if (userId != null) {
            return 'USER_ID:$userId|MESSAGE:${message.toString()}';
          }
          return message.toString();
        } else {
          print('[ChatService] Warning: Backend returned empty message in greeting');
        }
      } else {
        // Log error details for debugging
        print('[ChatService] Greeting failed: Status ${response.statusCode}');
        try {
          final errorBody = jsonDecode(response.body);
          print('[ChatService] Error body: $errorBody');
        } catch (_) {
          print('[ChatService] Error body (raw): ${response.body}');
        }
      }

      // If 401/404, user not registered yet - that's okay, use fallback
      // If other error, also use fallback
      return null;
    } catch (e) {
      // Any error - use fallback greeting
      print('[ChatService] Greeting error (using fallback): $e');
      print('[ChatService] Error type: ${e.runtimeType}');
      print('[ChatService] Full error: ${e.toString()}');
      // Return special marker to indicate backend unavailable
      return 'BACKEND_UNAVAILABLE';
    }
  }

  /// Register user with backend (onboarding)
  /// Returns tuple: (message, user_id) or (error, null)
  Future<Map<String, dynamic>> registerUser(
    String userName,
    String password,
    String language, {
    int? existingUserId, // For upgrading anonymous users
  }) async {
    // ---------------- LOCAL MODE ----------------
    if (AppConfig.useLocalMode) {
      return {'message': null, 'user_id': null}; // No registration needed in local mode
    }

    // ---------------- BACKEND MODE ----------------
    try {
      final queryParams = <String, String>{
        'name': userName,
        'secret_key': password,
        'lang': language,
      };
      
      // Add user_id if upgrading anonymous user
      if (existingUserId != null) {
        queryParams['user_id'] = existingUserId.toString();
      }

      final uri = Uri.parse('${AppConfig.baseUrl}/interact/introduce').replace(
        queryParameters: queryParams,
      );

      final headers = await _buildHeaders();

      final response = await http.post(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'message': body['message']?.toString(),
          'user_id': body['user_id'] as int?,
        };
      }

      // If user already exists (400), that's okay - they can still chat
      if (response.statusCode == 400) {
        return {'message': null, 'user_id': null}; // User already exists, continue
      }

      return {
        'message': 'REGISTRATION_ERROR_${response.statusCode}',
        'user_id': null,
      };
    } catch (e) {
      return {
        'message': 'REGISTRATION_ERROR: ${e.toString()}',
        'user_id': null,
      };
    }
  }

  /// Send message to backend or mock
  /// Returns response or 'SECURITY_CHECK_REQUIRED' if suspicious behavior detected
  Future<String> sendMessage(
    String userMessage, {
    String? userName,
    String? userPassword,
    String? language, // Language from ChatController (currentLanguage)
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

      // Get current language - prefer provided language, fallback to UserPreferences
      String currentLang;
      if (language != null && language.isNotEmpty) {
        currentLang = language;
      } else {
        currentLang = await UserPreferences.getUserLanguage();
      }

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

      // Debug: Print URL for troubleshooting (TEMPORARY - for verification)
      print('[ChatService] ===== SENDING TO BACKEND =====');
      print('[ChatService] URL: ${uri.toString()}');
      print('[ChatService] Method: POST');
      print('[ChatService] Headers: $headers');
      print('[ChatService] Query params: $queryParams');
      print('[ChatService] Message: "$userMessage"');

      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('[ChatService] Request timeout after 10 seconds');
          throw Exception('Connection timeout - Server may be down');
        },
      );
      
      print('[ChatService] ===== BACKEND RESPONSE =====');
      print('[ChatService] Status: ${response.statusCode}');
      print('[ChatService] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('[ChatService] ✅ SUCCESS - Backend responded');
      } else {
        print('[ChatService] ❌ ERROR - Status ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        print('[ChatService] Response body keys: ${body.keys.toList()}');
        print('[ChatService] Response body: $body');
        
        // Check for security flag in response (backend AI detected suspicious behavior)
        if (body['requires_security_check'] == true) {
          print('[ChatService] ⚠️ Security check required');
          return 'SECURITY_CHECK_REQUIRED';
        }
        
        // Backend returns 'message' field and 'user_id' (for anonymous users)
        final message = body['message']?.toString() ?? '';
        final userId = body['user_id'] as int?;
        
        print('[ChatService] Parsed message: "$message"');
        print('[ChatService] Parsed user_id: $userId');
        
        if (message.isEmpty) {
          print('[ChatService] ⚠️ WARNING: Backend returned empty message!');
          print('[ChatService] Full response body: $body');
        }
        
        // Return message with user_id if available (for anonymous users)
        if (userId != null && message.isNotEmpty) {
          print('[ChatService] Returning message with user_id: $userId');
          return 'USER_ID:$userId|MESSAGE:$message';
        }
        
        print('[ChatService] Returning message only (no user_id)');
        return message;
      }

      // Handle 422 (Validation Error) - usually means missing required parameter
      // This can happen if backend hasn't been restarted after code changes
      if (response.statusCode == 422) {
        final body = jsonDecode(response.body);
        final errorDetail = body['detail']?.toString() ?? 'Validation error';
        print('[ChatService] 422 Validation Error: $errorDetail');
        
        // Check if error is about missing name/secret_key (backend not updated)
        if (errorDetail.contains('name') && errorDetail.contains('secret_key')) {
          print('[ChatService] Backend needs restart - name/secret_key still required');
          return 'BACKEND_UPDATE_REQUIRED: Backend needs to be restarted. Please contact administrator.';
        }
        
        return 'SERVER_ERROR_422: $errorDetail';
      }

      if (response.statusCode == 401 || response.statusCode == 404) {
        print('[ChatService] Auth error: Status ${response.statusCode}');
        // User not found - this is okay for new users, they can chat without registration
        // Backend will create user automatically or return error
        // But with anonymous users support, this shouldn't happen
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

  /// Test backend connection
  Future<bool> testConnection() async {
    if (AppConfig.useLocalMode) {
      return false; // No connection test in local mode
    }

    try {
      final baseUri = Uri.parse(AppConfig.baseUrl);
      final uri = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
        path: '/interact/chat',
        queryParameters: {
          'message': '__CONNECTION_TEST__',
          'lang': 'en',
        },
      );
      
      final headers = await _buildHeaders();
      
      final response = await http.post(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      // Backend is reachable if we get any response (even errors mean server is up)
      return response.statusCode == 200 || 
             response.statusCode == 401 || 
             response.statusCode == 422 ||
             response.statusCode == 400;
    } catch (e) {
      print('[ChatService] Connection test failed: $e');
      return false;
    }
  }
}
