import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/cache/page_snapshot_cache.dart';
import 'package:sedi_app/features/intro/presentation/pages/intro_page.dart';
import 'package:sedi_app/features/lifestyle/logic/lifestyle_summary_cache.dart';

String _read(String path) => File(path).readAsStringSync();

/// R-050 (Javad 2026-11-01): the pages behind the top icons paint what was seen last at once, independent reads run
/// together, A1 is 2.2 s, and the notification question does not wait for an asset read.
void main() {
  group('PageSnapshotCache', () {
    setUp(PageSnapshotCache.clear);

    test('returns what was put, by type; a wrong type is a miss', () {
      PageSnapshotCache.put('k', <int>[1, 2]);
      expect(PageSnapshotCache.get<List<int>>('k'), [1, 2]);
      expect(PageSnapshotCache.get<String>('k'), isNull);
      expect(PageSnapshotCache.get<List<int>>('other'), isNull);
    });

    test('expires after 30 minutes and is emptied by clear (logout)', () {
      final t0 = DateTime(2026, 11, 1, 10);
      PageSnapshotCache.put('k', 'v', now: t0);
      expect(PageSnapshotCache.get<String>('k', now: t0.add(const Duration(minutes: 29))), 'v');
      expect(PageSnapshotCache.get<String>('k', now: t0.add(const Duration(minutes: 31))), isNull);
      PageSnapshotCache.put('k2', 'v');
      PageSnapshotCache.clear();
      expect(PageSnapshotCache.get<String>('k2'), isNull);
    });

    test('a schedule snapshot of another day is never shown', () {
      ScheduleSnapshot.remember(const [], const [], <String>{}, now: DateTime(2026, 11, 1, 9));
      expect(ScheduleSnapshot.today(now: DateTime(2026, 11, 1, 20)), isNotNull);
      expect(ScheduleSnapshot.today(now: DateTime(2026, 11, 2, 8)), isNull);
    });

    test('logout clears it', () {
      final src = _read('lib/core/utils/user_profile_manager.dart');
      expect(src.contains('PageSnapshotCache.clear()'), isTrue);
    });
  });

  group('icon pages paint at once and read together', () {
    test('schedule: snapshot first, the three reads start together, a failed refresh keeps the list', () {
      final src = _read('lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart');
      expect(src.contains('ScheduleSnapshot.today()'), isTrue);
      expect(src.contains('final evF = _svc.listEvents();'), isTrue);
      expect(src.contains('final ev = await _svc.listEvents();'), isFalse);
      expect(src.contains('a failed refresh never wipes what the user already sees'), isTrue);
    });

    test('inbox: the request starts beside the signed-in check; the last first page paints at once', () {
      final src = _read('lib/features/notifications/presentation/pages/notification_inbox_page.dart');
      expect(src.indexOf('final reloadF = _reload(soft: hasSeen);'), lessThan(src.indexOf('final userId = await idF;')));
      expect(src.contains('PageSnapshotCache.get<_InboxFirstPage>'), isTrue);
    });

    test('health and history paint the last seen content and refresh behind it', () {
      final health = _read('lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart');
      expect(health.contains('PageSnapshotCache.get<_HealthSnapshot>'), isTrue);
      final hist = _read('lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart');
      expect(hist.contains('PageSnapshotCache.get<HistoryResponse>'), isTrue);
      expect(hist.contains('_load(silent: seen != null)'), isTrue);
    });

    test('A3 background read fills the schedule snapshot', () {
      final src = _read('lib/features/lifestyle/logic/lifestyle_summary_cache.dart');
      expect(src.contains('ScheduleSnapshot.remember('), isTrue);
    });

    test('gadgets page shows its sentence at once (no spinner while the list is read)', () {
      final src = _read('lib/features/devices/presentation/pages/devices_page.dart');
      expect(src.contains('if (_loading && _controller.devices.isNotEmpty)'), isTrue);
    });
  });

  group('A1 and the notification question', () {
    test('A1 is 2.2 s with the same keyframes', () {
      expect(IntroPage.kIntroDuration, const Duration(milliseconds: 2200));
      expect(IntroPage.kMotionKeyframes.length, 3);
    });

    test('the tray question builds its avatar from a drawable, not an asset read', () {
      final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(bg.contains('rootBundle'), isFalse);
      // R-073: the sphere is the large icon of the standard grown notification (still a drawable, no asset read)
      expect(bg.contains("DrawableResourceAndroidBitmap('sedi_notification_sphere')"), isTrue);
    });
  });
}
