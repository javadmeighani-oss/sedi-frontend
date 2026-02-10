import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/features/notification/utils/notification_ui_mapping.dart';
import 'package:sedi_app/data/models/notification.dart' as sedi;

void main() {
  group('defaultTitleForNotificationType', () {
    test('returns default title for each type', () {
      expect(defaultTitleForNotificationType(sedi.NotificationType.info), 'Notification');
      expect(defaultTitleForNotificationType(sedi.NotificationType.alert), 'Alert');
      expect(defaultTitleForNotificationType(sedi.NotificationType.reminder), 'Reminder');
      expect(defaultTitleForNotificationType(sedi.NotificationType.morningBrief), 'Morning Brief');
      expect(defaultTitleForNotificationType(sedi.NotificationType.healthAlert), 'Health Alert');
      expect(defaultTitleForNotificationType(sedi.NotificationType.connectionPing), 'Connection');
      expect(defaultTitleForNotificationType(sedi.NotificationType.deviceDisconnected), 'Device Disconnected');
    });
  });

  group('reaction action constants', () {
    test('tap_like and tap_dislike are defined for backend', () {
      expect(actionTapLike, 'tap_like');
      expect(actionTapDislike, 'tap_dislike');
    });
  });
}
