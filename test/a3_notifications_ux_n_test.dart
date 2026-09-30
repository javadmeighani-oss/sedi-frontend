import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/notifications/presentation/notification_inbox_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('Notifications inbox is history-only white card destination', () {
    final src = _read(
      'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
    );
    expect(src.contains('A3DestinationSurface.canvas'), isTrue);
    expect(src.contains('gate3PaleOliveBackground'), isFalse);
    expect(src.contains('A3DestinationCard'), isTrue);
    expect(src.contains('listInboxPage'), isTrue);
    expect(src.contains('_loadMore'), isTrue);
    expect(src.contains('_reload'), isTrue);
    expect(src.contains('_markReadOptimistic'), isTrue);
    expect(src.contains('NotificationActionCoordinator'), isTrue);
    expect(src.contains('hideInbox'), isTrue);
    expect(src.contains('AppGateRouter.goToHeart'), isFalse);
    expect(src.contains('wasThisUseful'), isFalse);
    expect(src.contains('continueInChat'), isFalse);
    expect(src.contains('InboxFilter.all'), isTrue);
    expect(src.contains('InboxFilter.unread'), isTrue);
    expect(src.contains('HealthSubject'), isFalse);
    expect(src.contains('categoryLabel'), isTrue);
    expect(src.contains('isScrollControlled: true'), isTrue);

    expect(NotificationInboxL10n('en').title, 'Smart Notifications');
    expect(NotificationInboxL10n('en').fallbackTitle, 'Notification');
    expect(NotificationInboxL10n('fa').isRtl, isTrue);
    expect(NotificationInboxL10n('ar').isRtl, isTrue);
    expect(NotificationInboxL10n('fa').fallbackTitle, 'اعلان');
    expect(NotificationInboxL10n('ar').fallbackTitle, 'إشعار');
  });
}
