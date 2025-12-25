/// ============================================
/// Frontend Contract Test - Phase 2 Validation
/// ============================================
/// 
/// PURPOSE:
/// - Test frontend parsing of backend contract response
/// - Validate field names, types, enum values
/// - Test feedback submission
/// ============================================

import '../../../data/models/notification.dart';
import '../../../data/models/notification_feedback.dart';
import '../data/notification_service.dart';

class FrontendContractTest {
  final NotificationService service;

  FrontendContractTest({NotificationService? service})
      : service = service ?? NotificationService();

  /// Test A2: Frontend Contract Parse Test
  /// Validates that frontend can parse backend response correctly
  Future<Map<String, dynamic>> testParseNotificationResponse() async {
    print('=' * 60);
    print('FRONTEND CONTRACT PARSE TEST');
    print('=' * 60);

    try {
      // Call backend
      final response = await service.getNotifications(userId: 1);

      if (response['ok'] != true) {
        return {
          'ok': false,
          'error': response['error'],
          'message': 'Backend returned error'
        };
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        return {
          'ok': false,
          'error': 'Missing data field in response'
        };
      }

      // Validate response structure (Contract Section 7)
      final notifications = data['notifications'] as List<dynamic>?;
      final total = data['total'] as int?;
      final unreadCount = data['unread_count'] as int?;

      if (notifications == null) {
        return {
          'ok': false,
          'error': 'Missing notifications array'
        };
      }

      if (total == null) {
        return {
          'ok': false,
          'error': 'Missing total field'
        };
      }

      if (unreadCount == null) {
        return {
          'ok': false,
          'error': 'Missing unread_count field'
        };
      }

      print('✅ Response structure matches contract');
      print('   - notifications: ${notifications.length} items');
      print('   - total: $total');
      print('   - unread_count: $unreadCount');

      // Parse each notification (Contract Section 1)
      final parsedNotifications = <Notification>[];
      final issues = <String>[];

      for (var notifJson in notifications) {
        try {
          final notif = Notification.fromJson(notifJson as Map<String, dynamic>);
          parsedNotifications.add(notif);

          // Validate required fields
          if (notif.id.isEmpty) issues.add('Missing id');
          if (notif.message.isEmpty) issues.add('Missing message');
          if (notif.createdAt.isEmpty) issues.add('Missing created_at');

          // Validate enum values
          final typeStr = notif.type.toContractString();
          if (!['info', 'alert', 'reminder', 'check_in', 'achievement']
              .contains(typeStr)) {
            issues.add('Invalid type: $typeStr');
          }

          final priorityStr = notif.priority.toContractString();
          if (!['low', 'normal', 'high', 'urgent'].contains(priorityStr)) {
            issues.add('Invalid priority: $priorityStr');
          }

          // Validate actions if present (Contract Section 4)
          if (notif.actions != null) {
            for (var action in notif.actions!) {
              final actionTypeStr = action.type.toContractString();
              if (!['quick_reply', 'navigate', 'dismiss', 'custom']
                  .contains(actionTypeStr)) {
                issues.add('Invalid action type: $actionTypeStr');
              }
            }
          }

          print('   ✅ Parsed notification: ${notif.id} (${notif.type.toContractString()}, ${notif.priority.toContractString()})');
        } catch (e) {
          issues.add('Failed to parse notification: $e');
        }
      }

      if (issues.isNotEmpty) {
        return {
          'ok': false,
          'error': 'Contract validation issues',
          'issues': issues
        };
      }

      return {
        'ok': true,
        'parsed_count': parsedNotifications.length,
        'total': total,
        'unread_count': unreadCount,
        'notifications': parsedNotifications
      };
    } catch (e) {
      return {
        'ok': false,
        'error': 'Test failed: $e'
      };
    }
  }

  /// Test A3: Frontend Feedback Submission Test
  /// Validates that frontend can submit feedback correctly
  Future<Map<String, dynamic>> testFeedbackSubmission(String notificationId) async {
    print('\n' + '=' * 60);
    print('FRONTEND FEEDBACK SUBMISSION TEST');
    print('=' * 60);

    try {
      // Create feedback payload (Contract Section 5)
      final feedback = NotificationFeedback.create(
        notificationId: notificationId,
        reaction: FeedbackReaction.seen,
      );

      print('📤 Sending feedback:');
      print('   - notification_id: ${feedback.notificationId}');
      print('   - reaction: ${feedback.reaction.toContractString()}');
      print('   - timestamp: ${feedback.timestamp}');

      // Submit feedback
      final response = await service.submitFeedback(feedback);

      if (response['ok'] != true) {
        return {
          'ok': false,
          'error': response['error'],
          'message': 'Backend rejected feedback'
        };
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        return {
          'ok': false,
          'error': 'Missing data in response'
        };
      }

      print('✅ Feedback accepted by backend');
      print('   - feedback_received: ${data['feedback_received']}');
      print('   - message: ${data['message']}');

      return {
        'ok': true,
        'response': data
      };
    } catch (e) {
      return {
        'ok': false,
        'error': 'Test failed: $e'
      };
    }
  }

  /// Run all frontend contract tests
  Future<Map<String, dynamic>> runAllTests() async {
    print('\n' + '=' * 60);
    print('FRONTEND CONTRACT TEST SUITE');
    print('=' * 60);

    // Test 1: Parse notification response
    final parseResult = await testParseNotificationResponse();

    if (parseResult['ok'] != true) {
      return {
        'ok': false,
        'test': 'parse',
        'result': parseResult
      };
    }

    // Test 2: Feedback submission (if we have notifications)
    final notifications = parseResult['notifications'] as List<Notification>?;
    if (notifications != null && notifications.isNotEmpty) {
      final firstNotif = notifications.first;
      final feedbackResult = await testFeedbackSubmission(firstNotif.id);

      if (feedbackResult['ok'] != true) {
        return {
          'ok': false,
          'test': 'feedback',
          'result': feedbackResult
        };
      }
    }

    print('\n' + '=' * 60);
    print('✅ ALL FRONTEND TESTS PASSED');
    print('=' * 60);

    return {
      'ok': true,
      'parse_test': parseResult,
      'feedback_test': notifications != null && notifications.isNotEmpty
          ? 'passed'
          : 'skipped (no notifications)'
    };
  }
}

