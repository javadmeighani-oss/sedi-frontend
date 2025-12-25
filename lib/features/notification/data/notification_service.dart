/// ============================================
/// NotificationService - Contract-Compliant API Client
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Send/receive contract-compliant payloads
/// - No transformation
/// - No business logic
/// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/notification.dart';
import '../../../data/models/notification_feedback.dart';
import '../../../core/config/app_config.dart';

class NotificationService {
  final String baseUrl;

  NotificationService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConfig.baseUrl;

  /// GET /notifications (Contract Section 7)
  Future<Map<String, dynamic>> getNotifications({
    required int userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Support both /notifications and /notifications/ (contract-compliant)
      final uri = Uri.parse('$baseUrl/notifications/')
          .replace(queryParameters: {
        'user_id': userId.toString(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'ok': false,
          'error': {'code': 'HTTP_ERROR', 'message': 'Failed to fetch notifications'}
        };
      }
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'NETWORK_ERROR', 'message': e.toString()}
      };
    }
  }

  /// POST /notifications/feedback (Contract Section 5)
  Future<Map<String, dynamic>> submitFeedback(NotificationFeedback feedback) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/feedback');
      final body = json.encode(feedback.toJson());

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'ok': false,
          'error': {'code': 'HTTP_ERROR', 'message': 'Failed to submit feedback'}
        };
      }
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'NETWORK_ERROR', 'message': e.toString()}
      };
    }
  }
}

