import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

/// Javad's real-device test 2026-10-28 (items 1, 2, 3, 5, 6, 7, 8).
void main() {
  test('1 Health shows just the average heart rate for the last week, month and year', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart');
    expect(page.contains("_averageRanges = ['7d', '30d', '1y']"), isTrue);
    expect(page.contains('_averagesCard('), isTrue);
    expect(page.contains('_historyCard'), isFalse); // the history list is gone
    expect(page.contains('_rangeChip'), isFalse);
    expect(page.contains('isDeviceReportedStatus'), isTrue); // the gadget's own status stays
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      expect(l.avgHeartRateTitle, isNotEmpty);
      expect(l.avgLastWeek, isNotEmpty);
      expect(l.avgLastMonth, isNotEmpty);
      expect(l.avgLastYear, isNotEmpty);
    }
    expect(LifestyleL10n('fa').avgLastWeek, 'هفته‌ی اخیر');
  });

  test('2 My Schedule: one clear Add when empty, plain notification wording', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart');
    expect(page.contains('final hasAny = all.isNotEmpty || upcoming.isNotEmpty;'), isTrue);
    expect(page.contains('bottomNavigationBar: hasAny'), isTrue);
    expect(page.contains('_emptyAddCard(l10n)'), isTrue);
    expect(page.contains('if (categories >= 2)'), isTrue); // no filter chips for a single category
    final fa = LifestyleL10n('fa');
    expect(fa.notifSettingsTitle, 'اعلان‌های صدی');
    expect(fa.notifSettingsTitle.contains('کِی'), isFalse);
    expect(fa.scheduleEmptyTitle, 'هنوز برنامه‌ای نداری');
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      expect(l.scheduleEmptyTitle, isNotEmpty);
      expect(l.scheduleEmptyHint, isNotEmpty);
      expect(l.notifSettingsSubtitle, isNotEmpty);
    }
  });

  test('3 the resonance is tallest at the centre and shortens to the sides, still outward', () {
    final v = _read('lib/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart');
    expect(v.contains('final spread = (d * 2.0).clamp(0.0, 1.0).toDouble();'), isTrue);
    expect(v.contains('1.0 - 0.30 * spread * _hash(i, 1)'), isTrue); // per-line character fades out at the centre
    expect(v.contains('d / 0.46'), isTrue);
    expect(v.contains('2 * p - 1.1 * d'), isTrue); // motion is still centre -> outwards (D-130)
    expect(v.contains('5 * p - 1.2 * d'), isTrue);
  });

  test('5 opening today earlier chats hides the recap; 7 the sphere makes room for the opened tray', () {
    final page = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
    expect(page.contains('i == _controller.restoredTodayCount'), isTrue);
    expect(page.contains('Gate3TopNavigationTray.expandedExtraHeight'), isTrue); // was 84 before the pilot-V1 tray
  });

  test('6 the delete-selected button turns solid once something is selected', () {
    final inbox = _read('lib/features/notifications/presentation/pages/notification_inbox_page.dart');
    expect(inbox.contains('backgroundColor: SediPalette.skin700'), isTrue);
    expect(inbox.contains('onPressed: _deleteSelected,'), isTrue);
  });

  test('8 a long message takes the whole width; the buttons move below it', () {
    final c = _read('lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart');
    expect(c.contains('_needsWideField('), isTrue);
    expect(c.contains('computeLineMetrics().length > 1'), isTrue);
    expect(c.contains('const Spacer(),'), isTrue);
  });
}
