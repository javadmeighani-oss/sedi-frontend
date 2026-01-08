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
  /// CRITICAL: userId is required to prevent anonymous user creation
  Future<String?> getGreeting({
    String? userName,
    String? userPassword,
    String? language,
    int? userId, // CRITICAL: user_id to prevent anonymous user creation
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

      // CRITICAL: Add user_id if available (prevents anonymous user creation)
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
        print('[ChatService] Adding user_id to greeting request: $userId');
      }

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

      // Retry mechanism for greeting
      http.Response? response;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount < maxRetries) {
        try {
          response = await http
              .post(
            uri,
            headers: headers,
          )
              .timeout(
            const Duration(seconds: 15), // Increased timeout for greeting
            onTimeout: () {
              print(
                  '[ChatService] Greeting request timeout after 15 seconds (attempt ${retryCount + 1})');
              throw Exception('Greeting timeout');
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            print('[ChatService] All greeting retry attempts failed');
            rethrow; // Re-throw the last error
          }
          print(
              '[ChatService] Greeting retry attempt $retryCount/$maxRetries after error: $e');
          await Future.delayed(
              Duration(seconds: retryCount * 2)); // Exponential backoff
        }
      }

      if (response == null) {
        print(
            '[ChatService] Failed to get greeting response after $maxRetries attempts');
        return 'BACKEND_UNAVAILABLE';
      }

      print('[ChatService] Greeting response - Status: ${response.statusCode}');
      print('[ChatService] Greeting response - Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Safe parsing - handle optional fields
        final message = body['message'];
        final userId = body['user_id'] as int?;

        print('[ChatService] Greeting success - message received from backend');
        print(
            '[ChatService] Message length: ${message?.toString().length ?? 0}');
        print('[ChatService] User ID: $userId');

        if (message != null && message.toString().isNotEmpty) {
          // Return message with user_id if available (for anonymous users)
          if (userId != null) {
            return 'USER_ID:$userId|MESSAGE:${message.toString()}';
          }
          return message.toString();
        } else {
          print(
              '[ChatService] Warning: Backend returned empty message in greeting');
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
      // Any error - return BACKEND_UNAVAILABLE to show error message
      print('[ChatService] Greeting error: $e');
      print('[ChatService] Error type: ${e.runtimeType}');

      // Check for connection errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') ||
          errorString.contains('connection refused') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('socketexception') ||
          errorString.contains('connection reset') ||
          errorString.contains('no route to host')) {
        return 'BACKEND_UNAVAILABLE';
      }
      print('[ChatService] Full error: ${e.toString()}');
      // Return special marker to indicate backend unavailable
      return 'BACKEND_UNAVAILABLE';
    }
  }

  /// Setup onboarding - create user with password and name
  /// Returns: (message, user_id, language) or (error, null, null)
  ///
  /// CRITICAL:
  /// - name is REQUIRED (from JSON body)
  /// - password is REQUIRED (from JSON body)
  /// - Backend contract: {"name": string, "password": string}
  /// - This method MUST return user_id if backend returns 200.
  /// - Only network errors or non-200 status codes should return null user_id.
  Future<Map<String, dynamic>> setupOnboarding(
    String password, {
    required String name, // REQUIRED - name must be provided
  }) async {
    print('[ChatService] ========== SETUP ONBOARDING START ==========');
    print('[ChatService] Name: "$name" (length: ${name.length})');
    print('[ChatService] Password length: ${password.length}');
    print('[ChatService] Local mode: ${AppConfig.useLocalMode}');

    // ---------------- LOCAL MODE ----------------
    if (AppConfig.useLocalMode) {
      print('[ChatService] Using local mode - returning mock response');
      return {
        'message': 'Welcome! This is local mode.',
        'user_id': null,
        'language': 'en',
      };
    }

    // ---------------- BACKEND MODE ----------------
    // STEP 2: Validate name (REQUIRED, non-empty)
    if (name.trim().isEmpty) {
      print('[ChatService] ❌ ERROR: Name is required and cannot be empty');
      return {
        'message': 'Name is required and cannot be empty',
        'user_id': null,
        'language': null,
      };
    }

    try {
      // STEP 2: Use JSON body (not query params)
      final uri = Uri.parse('${AppConfig.baseUrl}/interact/onboarding');
      final headers = await _buildHeaders();

      // STEP 2: Create JSON payload according to backend contract
      // Backend contract: {"name": string, "password": string}
      final payload = {
        'name': name.trim(), // REQUIRED
        'password': password.trim(), // REQUIRED
      };

      print('[ChatService] Request URL: ${uri.toString()}');
      print('[ChatService] Request payload: $payload');
      print('[ChatService] Request headers: $headers');

      final response = await http
          .post(
        uri,
        headers: {
          ...headers,
          'Content-Type': 'application/json', // STEP 2: JSON body
        },
        body: jsonEncode(payload), // STEP 2: JSON body
      )
          .timeout(
        const Duration(seconds: 30), // Increased timeout
        onTimeout: () {
          print('[ChatService] ❌ Request timeout after 30 seconds');
          throw Exception('Onboarding timeout');
        },
      );

      print('[ChatService] ========== RESPONSE RECEIVED ==========');
      print('[ChatService] Status code: ${response.statusCode}');
      print('[ChatService] Response body: ${response.body}');
      print('[ChatService] Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          // ============================================
          // STEP 5: LOGGING (IMPORTANT)
          // ============================================
          // Add debug logging for onboarding response:
          // - full response body
          // - extracted user_id
          // ============================================
          print('[ChatService] ===== RAW RESPONSE (200) =====');
          print('[ChatService] Response body (raw): ${response.body}');
          print('[ChatService] Response body length: ${response.body.length}');

          final body = jsonDecode(response.body);
          print('[ChatService] ===== PARSED RESPONSE =====');
          print('[ChatService] Parsed response body: $body');
          print('[ChatService] Response type: ${body.runtimeType}');
          print('[ChatService] Response keys: ${body.keys.toList()}');

          // Check if user_id exists in response
          if (!body.containsKey('user_id')) {
            print(
                '[ChatService] ⚠️ WARNING: user_id not found in response body');
            print('[ChatService] Response body keys: ${body.keys.toList()}');
            print('[ChatService] This indicates backend response format issue');
          }

          final userId = body['user_id'];
          print('[ChatService] ===== USER_ID EXTRACTION =====');
          print('[ChatService] user_id from body: $userId');
          print('[ChatService] user_id type: ${userId?.runtimeType}');
          print('[ChatService] user_id is null: ${userId == null}');
          print('[ChatService] message: ${body['message']}');
          print('[ChatService] language: ${body['language']}');

          // Handle both int and string user_id
          int? userIdInt;
          if (userId == null) {
            print('[ChatService] ⚠️ WARNING: user_id is null in response');
            print('[ChatService] This means registration FAILED on backend');
            userIdInt = null;
          } else if (userId is int) {
            userIdInt = userId;
            print('[ChatService] ✅ user_id is int: $userIdInt');
          } else if (userId is String) {
            userIdInt = int.tryParse(userId);
            if (userIdInt == null) {
              print(
                  '[ChatService] ⚠️ WARNING: Failed to parse user_id string: "$userId"');
            } else {
              print('[ChatService] ✅ user_id is string, parsed: $userIdInt');
            }
          } else {
            userIdInt = int.tryParse(userId.toString());
            if (userIdInt == null) {
              print(
                  '[ChatService] ⚠️ WARNING: Failed to parse user_id from type ${userId.runtimeType}: $userId');
            } else {
              print(
                  '[ChatService] ✅ user_id is other type, converted: $userIdInt');
            }
          }

          print('[ChatService] ===== FINAL USER_ID =====');
          print('[ChatService] Final user_id: $userIdInt');
          print('[ChatService] Final user_id is null: ${userIdInt == null}');
          print('[ChatService] ===== END SUCCESS RESPONSE =====');

          // ============================================
          // STEP 1: FIX ONBOARDING SUCCESS CONDITION
          // ============================================
          // SUCCESS if and only if: user_id exists and is not null
          // FAILURE only if: HTTP error OR user_id is missing
          // DO NOT check: success flag, message content, chat response, GPT availability
          // ============================================

          if (userIdInt == null) {
            print('[ChatService] ❌ ERROR: user_id is null after parsing');
            print(
                '[ChatService] This indicates registration FAILED on backend');
            print('[ChatService] Response body: $body');
            return {
              'message': body['message']?.toString() ??
                  'Server response missing user_id. Please try again.',
              'user_id': null,
              'language': body['language']?.toString() ?? language,
            };
          }

          // ============================================
          // STEP 2: DECOUPLE ONBOARDING FROM CHAT
          // ============================================
          // Registration is SUCCESSFUL - return user_id immediately
          // Message content (even if it contains chat/GPT errors) does NOT affect registration success
          // ============================================

          print(
              '[ChatService] ✅ Registration SUCCESSFUL - user_id: $userIdInt');
          print(
              '[ChatService] Returning success response (message may contain chat errors, but registration succeeded)');

          return {
            'message': body['message']?.toString() ?? '',
            'user_id': userIdInt,
            'language': body['language']?.toString() ?? 'en', // Default to English if not provided
          };
        } catch (e, stackTrace) {
          print('[ChatService] ===== PARSE ERROR =====');
          print('[ChatService] ERROR parsing response body: $e');
          print('[ChatService] Stack trace: $stackTrace');
          print('[ChatService] Response body (raw): ${response.body}');
          print('[ChatService] Response status: ${response.statusCode}');
          print('[ChatService] ===== END PARSE ERROR =====');
          return {
            'message': 'Error parsing server response. Please try again.',
            'user_id': null,
            'language': null,
          };
        }
      }

      // Parse error message - provide user-friendly messages
      print('[ChatService] ===== ERROR RESPONSE =====');
      print('[ChatService] Status code: ${response.statusCode}');
      print('[ChatService] Response body: ${response.body}');
      print('[ChatService] Response headers: ${response.headers}');

      String errorMessage = 'Error creating account. Please try again.';

      try {
        final errorBody = jsonDecode(response.body);
        print('[ChatService] Error body parsed: $errorBody');

        // Try to get detail from error body
        final detail = errorBody['detail']?.toString() ??
            errorBody['message']?.toString() ??
            errorBody['error']?.toString() ??
            '';

        print('[ChatService] Error detail extracted: $detail');

        // Use backend error detail if available
        if (detail.isNotEmpty) {
          errorMessage = detail;
          print('[ChatService] Using backend error detail: $errorMessage');
        } else {
          // Map status codes to user-friendly messages
          switch (response.statusCode) {
            case 400:
              errorMessage =
                  'Invalid request. Please check your password (minimum 6 characters).';
              break;
            case 401:
              errorMessage = 'Authentication failed. Please try again.';
              break;
            case 404:
              errorMessage = 'Service not found. Please contact support.';
              break;
            case 422:
              errorMessage = 'Validation error. Please check your input.';
              break;
            case 500:
              errorMessage = 'Server error. Please try again later.';
              break;
            case 503:
              errorMessage =
                  'Service temporarily unavailable. Please try again later.';
              break;
            default:
              errorMessage = 'Registration failed. Please try again.';
          }
          print(
              '[ChatService] Using status code based error message: $errorMessage');
        }
      } catch (parseError) {
        print('[ChatService] ⚠️ Could not parse error body: $parseError');
        print('[ChatService] Raw response body: ${response.body}');

        // If can't parse error body, use status code
        switch (response.statusCode) {
          case 400:
            errorMessage =
                'Invalid request. Please check your password (minimum 6 characters).';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          case 503:
            errorMessage =
                'Service temporarily unavailable. Please try again later.';
            break;
          default:
            errorMessage = 'Registration failed. Please try again.';
        }
        print('[ChatService] Using fallback error message: $errorMessage');
      }

      print('[ChatService] Final error message: $errorMessage');
      print('[ChatService] ===== END ERROR RESPONSE =====');
      return {
        'message': errorMessage,
        'user_id': null,
        'language': null,
      };
    } catch (e) {
      print('[ChatService] Onboarding exception: $e');
      print('[ChatService] Exception type: ${e.runtimeType}');

      // Provide user-friendly error messages based on exception type
      String errorMessage;
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('timeout')) {
        errorMessage =
            'Connection timeout. Please check your internet connection and try again.';
      } else if (errorString.contains('connection refused') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('socketexception')) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection and try again.';
      } else if (errorString.contains('network')) {
        errorMessage =
            'Network error. Please check your internet connection and try again.';
      } else {
        errorMessage = 'Registration failed. Please try again.';
      }

      return {
        'message': errorMessage,
        'user_id': null,
        'language': null,
      };
    }
  }

  /// Register user with backend (onboarding) - DEPRECATED, use setupOnboarding
  /// Returns tuple: (message, user_id) or (error, null)
  Future<Map<String, dynamic>> registerUser(
    String userName,
    String password,
    String language, {
    int? existingUserId, // For upgrading anonymous users
  }) async {
    // Use new onboarding endpoint - name is required
    final result = await setupOnboarding(
      password,
      name: userName, // name is now a required named parameter
    );
    return {
      'message': result['message'],
      'user_id': result['user_id'],
    };
  }

  /// Send message to backend or mock
  /// Returns response or 'SECURITY_CHECK_REQUIRED' if suspicious behavior detected
  Future<String> sendMessage(
    String userMessage, {
    String? userName,
    String? userPassword,
    String? language, // Language from ChatController (currentLanguage)
    int?
        userId, // CRITICAL: user_id from previous response to maintain conversation continuity
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

      // STEP 2: Use JSON body (not query params) - Backend API contract
      if (userId == null) {
        print('[ChatService] ❌ ERROR: user_id is required for chat');
        return 'VALIDATION_ERROR: User ID is required. Please complete onboarding first.';
      }

      // Build JSON payload according to backend contract
      final payload = {
        'user_id': userId,
        'message': userMessage.trim(),
      };

      final uri = Uri.parse('${AppConfig.baseUrl}/interact/chat');
      final headers = await _buildHeaders();

      // Debug: Print request details
      print('[ChatService] ===== SENDING TO BACKEND =====');
      print('[ChatService] URL: ${uri.toString()}');
      print('[ChatService] Method: POST');
      print('[ChatService] Headers: $headers');
      print('[ChatService] JSON payload: $payload');
      print('[ChatService] Message: "$userMessage"');

      // Retry mechanism for network issues
      http.Response? response;
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          response = await http
              .post(
            uri,
            headers: {
              ...headers,
              'Content-Type': 'application/json', // STEP 2: JSON body
            },
            body: jsonEncode(payload), // STEP 2: JSON body
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print(
                  '[ChatService] Request timeout after 15 seconds (attempt ${retryCount + 1})');
              throw Exception('Connection timeout');
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            print('[ChatService] All retry attempts failed');
            rethrow; // Re-throw the last error
          }
          print(
              '[ChatService] Retry attempt $retryCount/$maxRetries after error: $e');
          await Future.delayed(
              Duration(seconds: retryCount * 2)); // Exponential backoff
        }
      }

      if (response == null) {
        throw Exception('Failed to get response after $maxRetries attempts');
      }

      print('[ChatService] ===== BACKEND RESPONSE =====');
      print('[ChatService] Status: ${response.statusCode}');
      print('[ChatService] Response body: ${response.body}');

      // Handle 502 Bad Gateway (GPT failure) FIRST
      if (response.statusCode == 502) {
        print('[ChatService] ❌ 502 Bad Gateway - GPT service error');
        try {
          final errorBody = jsonDecode(response.body);
          final errorDetail =
              errorBody['detail'] ?? errorBody['error'] ?? 'GPT service error';
          print('[ChatService] GPT error detail: $errorDetail');
          return 'GPT_ERROR: $errorDetail';
        } catch (parseError) {
          print('[ChatService] Could not parse 502 error body: $parseError');
          return 'GPT_ERROR: GPT service is unavailable. Please try again.';
        }
      }

      if (response.statusCode == 200) {
        print('[ChatService] ✅ SUCCESS - Backend responded');
      } else {
        print('[ChatService] ❌ ERROR - Status ${response.statusCode}');
        print('[ChatService] Response body: ${response.body}');

        // Parse error response to get real backend error message
        try {
          final errorBody = jsonDecode(response.body);
          final errorDetail = errorBody.get('detail') ??
              errorBody.get('message') ??
              'Unknown error';
          print('[ChatService] Backend error detail: $errorDetail');

          // Return structured error message from backend
          if (response.statusCode == 400) {
            return 'VALIDATION_ERROR: $errorDetail';
          } else if (response.statusCode == 404) {
            return 'USER_NOT_FOUND: $errorDetail';
          } else if (response.statusCode >= 500) {
            return 'SERVER_ERROR: $errorDetail';
          } else {
            return 'ERROR_${response.statusCode}: $errorDetail';
          }
        } catch (parseError) {
          print('[ChatService] Could not parse error body: $parseError');
          // Fallback to status code based error
          if (response.statusCode == 400) {
            return 'VALIDATION_ERROR: Invalid request. Please check your input.';
          } else if (response.statusCode == 404) {
            return 'USER_NOT_FOUND: User not found. Please check your user_id.';
          } else {
            return 'ERROR_${response.statusCode}: Server returned error status ${response.statusCode}';
          }
        }
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        print('[ChatService] Response body keys: ${body.keys.toList()}');
        print('[ChatService] Response body: $body');

        // Backend contract: {"message": string, "language": string, "timestamp": string, "requires_security_check": boolean, "detected_name": string | null}
        final message = body['message']?.toString() ?? '';
        final language = body['language']?.toString();
        final timestamp = body['timestamp']?.toString();
        final requiresSecurityCheck = body['requires_security_check'] == true;
        final detectedName = body['detected_name']?.toString();

        print('[ChatService] Parsed message: "$message"');
        print('[ChatService] Parsed language: $language');
        print('[ChatService] Parsed timestamp: $timestamp');
        print(
            '[ChatService] Parsed requires_security_check: $requiresSecurityCheck');
        print('[ChatService] Parsed detected_name: $detectedName');

        if (message.isEmpty) {
          print('[ChatService] ⚠️ WARNING: Backend returned empty message!');
          print('[ChatService] Full response body: $body');
        }

        // Build JSON response string to pass to controller
        // Controller will parse this JSON to extract message and detected_name
        final responseData = {
          'message': message,
          'language': language,
          'timestamp': timestamp,
          'requires_security_check': requiresSecurityCheck,
          'detected_name': detectedName,
        };

        return jsonEncode(responseData);
      }

      // Handle 422 (Validation Error) - usually means missing required parameter
      // This can happen if backend hasn't been restarted after code changes
      if (response.statusCode == 422) {
        final body = jsonDecode(response.body);
        final errorDetail = body['detail']?.toString() ?? 'Validation error';
        print('[ChatService] 422 Validation Error: $errorDetail');

        // Check if error is about missing name/secret_key (backend not updated)
        if (errorDetail.contains('name') &&
            errorDetail.contains('secret_key')) {
          print(
              '[ChatService] Backend needs restart - name/secret_key still required');
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
      print('[ChatService] ===== EXCEPTION CAUGHT =====');
      print('[ChatService] Exception type: ${e.runtimeType}');
      print('[ChatService] Exception message: $e');
      print('[ChatService] Stack trace: ${StackTrace.current}');

      final errorString = e.toString().toLowerCase();

      // STEP 4: Only return real HTTP/timeout errors (no fake errors)
      if (errorString.contains('timeout')) {
        print('[ChatService] ❌ Connection timeout');
        return 'SERVER_ERROR: Connection timeout. Please try again.';
      } else if (errorString.contains('connection refused') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('name resolution') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('socketexception') ||
          errorString.contains('socket') ||
          errorString.contains('connection reset') ||
          errorString.contains('no route to host')) {
        print('[ChatService] ❌ Network error: $e');
        return 'SERVER_ERROR: Network error. Please check your internet connection and try again.';
      }

      print('[ChatService] ❌ Unknown error: $e');
      return 'SERVER_ERROR: ${e.toString()}';
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

      final response = await http
          .post(
        uri,
        headers: headers,
      )
          .timeout(
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
