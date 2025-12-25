/// ============================================
/// NotificationHandler - Contract-Compliant Parser
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Parse contract-compliant payloads from backend
/// - No transformation hacks
/// - No business logic
/// ============================================

import '../../../data/models/notification.dart';

class NotificationHandler {
  /// Parse notification from contract-compliant JSON
  /// Contract Section 1
  Notification parseNotification(Map<String, dynamic> json) {
    return Notification.fromJson(json);
  }

  /// Parse list of notifications from API response
  /// Contract Section 7 - GET /notifications response
  List<Notification> parseNotificationList(Map<String, dynamic> response) {
    if (response['ok'] != true) {
      return [];
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      return [];
    }

    final notifications = data['notifications'] as List<dynamic>?;
    if (notifications == null) {
      return [];
    }

    return notifications
        .map((n) => Notification.fromJson(n as Map<String, dynamic>))
        .toList();
  }
}
