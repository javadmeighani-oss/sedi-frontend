import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/notification/data/notification_service.dart';
import 'package:sedi_app/features/notification/logic/notification_sync.dart';

void main() {
  group('mergeSeenIdsRollingWindow', () {
    test('keeps newest first and caps at max', () {
      final existing = ['a', 'b', 'c'];
      final newIds = ['d', 'e'];
      final result = mergeSeenIdsRollingWindow(existing, newIds, 5);
      expect(result, ['d', 'e', 'a', 'b', 'c']);
    });

    test('rolling window: over 200 ids stored as 200 newest', () {
      final existing = List.generate(200, (i) => 'id_$i');
      final newIds = ['new1', 'new2', 'new3'];
      final result = mergeSeenIdsRollingWindow(existing, newIds, 200);
      expect(result.length, 200);
      expect(result.take(3).toList(), ['new1', 'new2', 'new3']);
      expect(result.contains('id_0'), false);
      expect(result.contains('id_199'), true);
    });

    test('no duplicate new ids in merged list', () {
      final existing = ['a', 'b'];
      final newIds = ['c', 'a'];
      final result = mergeSeenIdsRollingWindow(existing, newIds, 10);
      expect(result, ['c', 'a', 'b']);
    });
  });

  group('NotificationService.parseUnreadCount', () {
    test('returns count when ok and data.count present', () {
      final resp = {'ok': true, 'data': {'count': 5, 'notifications': []}};
      expect(NotificationService.parseUnreadCount(resp), 5);
    });

    test('falls back to notifications length when count missing', () {
      final resp = {
        'ok': true,
        'data': {
          'notifications': [
            {'id': '1'},
            {'id': '2'},
          ],
        },
      };
      expect(NotificationService.parseUnreadCount(resp), 2);
    });

    test('returns 0 when not ok', () {
      expect(NotificationService.parseUnreadCount({'ok': false}), 0);
    });

    test('returns 0 when data null', () {
      expect(NotificationService.parseUnreadCount({'ok': true, 'data': null}), 0);
    });
  });
}
