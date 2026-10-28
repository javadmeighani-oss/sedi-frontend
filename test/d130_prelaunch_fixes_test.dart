import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/background_notification_action_handler.dart';

String _read(String path) => File(path).readAsStringSync();

/// D-130 (Javad's phone test 2026-10-28, before the deploy):
/// - "governed actions" (an English placeholder row) is gone from My Schedule;
/// - the resonance radiates from the CENTRE outwards in every state (a voice leaving a mouth);
/// - the status-bar notification icon is the real Sedi logo;
/// - a tray Dislike asks WHY inside the notification (three buttons), not in an app screen.
void main() {
  test('My Schedule no longer shows the unclear "governed actions" block', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart');
    expect(page.contains('governedActions'), isFalse);
    expect(page.contains('listI8Actions'), isFalse);
    expect(page.contains('_actionRow'), isFalse);
  });

  test('the resonance travels from the centre outwards in every state', () {
    final v = _read('lib/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart');
    // outward = the phase term of time goes with a MINUS distance term
    expect(v.contains('2 * p - 1.1 * d'), isTrue); // idle
    expect(v.contains('3 * p - 1.6 * d'), isTrue); // listening
    expect(v.contains('2 * p - 1.0 * d'), isTrue); // thinking
    expect(v.contains('5 * p - 1.2 * d'), isTrue); // speaking
    expect(v.contains('1.6 * d + 3 * p'), isFalse); // the old inward swell
    expect(v.contains('scans left and right'), isFalse);
  });

  test('the notification status-bar icon is the real Sedi logo in every density', () {
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(File('android/app/src/main/res/drawable-$d/ic_stat_sedi.png').existsSync(), isTrue, reason: d);
    }
    expect(File('android/app/src/main/res/drawable/ic_stat_sedi.xml').existsSync(), isFalse); // old hologram silhouette
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest.contains('@drawable/ic_stat_sedi'), isTrue);
    final service = _read('lib/core/notifications/local_notifications_service.dart');
    expect(service.contains("androidBrandSmallIcon = 'ic_stat_sedi'"), isTrue);
    expect(service.contains('sedi_notification_large.png'), isTrue); // the logo sphere as the large icon
  });

  test('a tray Dislike asks the reason inside a notification with three buttons', () {
    expect(BackgroundNotificationActionHandler.reasonActionPrefix, 'reason:');
    expect(BackgroundNotificationActionHandler.promptReasons, ['too_frequent', 'wrong_timing', 'irrelevant']);
    final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
    expect(bg.contains('_showReasonPrompt('), isTrue);
    expect(bg.contains('showsUserInterface: false'), isTrue); // the answer never opens the app
    expect(bg.contains('timeoutAfter: 90000'), isTrue);
    expect(bg.contains('action.startsWith(reasonActionPrefix)'), isTrue);
    // the in-app chat sheet is only the fallback when the prompt cannot be shown
    expect(bg.contains('if (!shown)'), isTrue);
    final service = _read('lib/core/notifications/local_notifications_service.dart');
    expect(service.contains('BackgroundNotificationActionHandler.reasonActionPrefix'), isTrue);
    final repo = _read('lib/data/repositories/notification_repository.dart');
    expect(repo.contains("'reason': reason"), isTrue);
  });
}
