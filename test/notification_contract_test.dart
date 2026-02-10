import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/data/models/notification.dart';
import 'package:sedi_app/data/models/notification_feedback.dart';

void main() {
  group('Notification.fromJson (backend shape)', () {
    test('parses backend response item: id int, body, type, priority, is_read, created_at', () {
      final json = {
        'id': 42,
        'user_id': 1,
        'type': 'health_alert',
        'title': 'High heart rate',
        'body': 'Your heart rate was elevated.',
        'priority': 'high',
        'is_read': false,
        'created_at': '2025-02-09T12:00:00.000Z',
      };
      final n = Notification.fromJson(json);
      expect(n.id, '42');
      expect(n.message, 'Your heart rate was elevated.');
      expect(n.title, 'High heart rate');
      expect(n.type, NotificationType.healthAlert);
      expect(n.priority, NotificationPriority.high);
      expect(n.isRead, false);
      expect(n.createdAt, '2025-02-09T12:00:00.000Z');
    });

    test('parses backend type morning_brief and priority critical', () {
      final json = {
        'id': 1,
        'type': 'morning_brief',
        'body': 'Good morning',
        'priority': 'critical',
        'is_read': true,
        'created_at': '2025-02-09T08:00:00Z',
      };
      final n = Notification.fromJson(json);
      expect(n.type, NotificationType.morningBrief);
      expect(n.priority, NotificationPriority.urgent);
      expect(n.isRead, true);
    });

    test('parses legacy shape: id string, message', () {
      final json = {
        'id': 'legacy-1',
        'type': 'reminder',
        'message': 'Take your medicine',
        'priority': 'normal',
        'is_read': false,
        'created_at': '2025-02-09T10:00:00Z',
      };
      final n = Notification.fromJson(json);
      expect(n.id, 'legacy-1');
      expect(n.message, 'Take your medicine');
      expect(n.type, NotificationType.reminder);
    });
  });

  group('NotificationFeedback.toBackendJson', () {
    test('like -> positive', () {
      final f = NotificationFeedback.create(
        notificationId: '99',
        reaction: FeedbackReaction.like,
      );
      final j = f.toBackendJson();
      expect(j['feedback'], 'positive');
      expect(j.containsKey('reason'), isFalse);
    });

    test('dislike with feedbackText -> negative and reason', () {
      final f = NotificationFeedback.create(
        notificationId: '99',
        reaction: FeedbackReaction.dislike,
        feedbackText: 'Too early',
      );
      final j = f.toBackendJson();
      expect(j['feedback'], 'negative');
      expect(j['reason'], 'Too early');
    });

    test('seen -> neutral', () {
      final f = NotificationFeedback.create(
        notificationId: '99',
        reaction: FeedbackReaction.seen,
      );
      final j = f.toBackendJson();
      expect(j['feedback'], 'neutral');
    });

    test('interact with actionId -> neutral and action', () {
      final f = NotificationFeedback(
        notificationId: '99',
        actionId: 'too_late',
        reaction: FeedbackReaction.interact,
        feedbackText: null,
        timestamp: DateTime.now().toIso8601String(),
      );
      final j = f.toBackendJson();
      expect(j['feedback'], 'neutral');
      expect(j['action'], 'too_late');
    });
  });
}
