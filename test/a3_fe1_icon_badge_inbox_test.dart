import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/data/dto/notifications/notification_feedback_dto.dart';
import 'package:sedi_app/features/notifications/presentation/notification_inbox_l10n.dart';
import 'package:sedi_app/services/notifications/notifications_service.dart';

String _read(String relativePath) => File(relativePath).readAsStringSync();

void main() {
  test('A3 Gate3 Smart Notifications is single intended icon→Inbox entry', () {
    final gate3 = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    final row = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
    );

    expect(gate3.contains('NotificationInboxPage'), isTrue);
    expect(gate3.contains('_openNotificationsInbox'), isTrue);
    expect(gate3.contains('unreadNotificationCount'), isTrue);
    expect(gate3.contains('fetchUnreadCount'), isTrue);
    expect(gate3.contains('InboxRefreshBus'), isTrue);

    expect(row.contains('Icons.notifications_none_outlined'), isTrue);
    expect(row.contains('unreadNotificationCount'), isTrue);
    expect(row.contains('_notificationsBadge'), isTrue);
    // Zero must not render a misleading badge.
    expect(row.contains('count <= 0'), isTrue);
  });

  test('parseUnreadCount prefers unread_count over page count', () {
    expect(
      NotificationsService.parseUnreadCount({
        'ok': true,
        'data': {
          'count': 20,
          'unread_count': 37,
          'total': 37,
          'notifications': List.filled(20, {'id': 1}),
        },
      }),
      37,
    );
    expect(
      NotificationsService.parseUnreadCount({
        'ok': true,
        'data': {'unread_count': 0, 'count': 0, 'notifications': []},
      }),
      0,
    );
  });

  test('dislike feedback DTO includes optional reason only for dislike', () {
    final withReason = NotificationFeedbackDto(
      liked: false,
      timestamp: '2026-09-14T00:00:00Z',
      reason: 'irrelevant',
    ).toJson();
    expect(withReason['reaction'], 'dislike');
    expect(withReason['reason'], 'irrelevant');

    final like = NotificationFeedbackDto(
      liked: true,
      timestamp: '2026-09-14T00:00:00Z',
      reason: 'irrelevant',
    ).toJson();
    expect(like.containsKey('reason'), isFalse);
  });

  test('Inbox detail recovery reuses action coordinator; no hard delete', () {
    final inbox = _read(
      'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
    );
    expect(inbox.contains('NotificationActionCoordinator'), isTrue);
    expect(inbox.contains('hideInbox'), isTrue);
    expect(inbox.contains('continueInChat'), isFalse);
    expect(inbox.contains('_pickDislikeReason'), isFalse);
    expect(inbox.contains('AppGateRouter.goToHeart'), isFalse);
    expect(inbox.contains('InboxRefreshBus.instance.triggerDebounced'), isTrue);
    expect(inbox.contains('HealthSubject'), isFalse);
    expect(inbox.contains('gadget_provenance'), isFalse);
    expect(inbox.contains('SELF'), isFalse);
    expect(inbox.contains('OTHER'), isFalse);
    expect(inbox.contains('categoryLabel'), isTrue);
    expect(inbox.contains('hard delete'), isFalse);
    expect(inbox.contains('hardDelete'), isFalse);

    final en = NotificationInboxL10n('en');
    final fa = NotificationInboxL10n('fa');
    final ar = NotificationInboxL10n('ar');
    expect(en.title, 'Smart Notifications');
    expect(en.fallbackTitle, 'Notification');
    expect(fa.fallbackTitle, 'اعلان');
    expect(ar.fallbackTitle, 'إشعار');
    expect(fa.isRtl, isTrue);
    expect(ar.isRtl, isTrue);
  });
}
