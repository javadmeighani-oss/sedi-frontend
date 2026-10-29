import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_page.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screen 3 (R-034 / R-035, Javad 2026-10-29): the Lifestyle hub is a glass bento of five icon-first cards,
/// the Sedi sphere sits beside the title, and the Today card never says "today" twice.
void main() {
  final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_page.dart');

  testWidgets('five glass cards, the sphere beside the title, nothing overflows', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LifestylePage()));
    await tester.pump();
    final l10n = LifestyleL10n('en');
    expect(find.byType(SediHologramOrb), findsOneWidget);
    for (final title in l10n.sectionTitles) {
      expect(find.text(title), findsOneWidget);
    }
    expect(
      find.descendant(of: find.byType(ListView), matching: find.byType(InkWell)),
      findsNWidgets(5),
    );
    // R-035: the sphere is on the start side of the title (left in LTR)
    final orb = tester.getCenter(find.byType(SediHologramOrb));
    final title = tester.getCenter(find.text(l10n.title));
    expect(orb.dx, lessThan(title.dx));
    expect(tester.takeException(), isNull);
  });

  test('the sphere comes first in the title row and the Today card shows the date, not the word twice', () {
    expect(page.indexOf('const SediHologramOrb('), lessThan(page.indexOf('l10n.title')));
    expect(page.contains('l10n.weekdayShort('), isTrue);
    expect(page.contains('CalendarDateMath.formatIsoForLanguage'), isTrue);
    // the old small "today" label above the sentence is gone
    expect(page.contains('l10n.today,'), isFalse);
  });

  test('Today ring is real data only: a fraction of done/total, never invented', () {
    expect(page.contains('s.total == 0 ? 0.0 : s.done / s.total'), isTrue);
    expect(page.contains('_TodayRingPainter'), isTrue);
    expect(page.contains('if (summary != null) ...['), isTrue); // no summary, no card
  });

  test('cards are glass and keep their destinations', () {
    for (final name in const [
      'LifestyleHealthPage()',
      'LifestyleHistoryPage()',
      'LifestyleSchedulePage()',
      'LifestyleNutritionPage()',
      'LifestyleExercisePage()',
    ]) {
      expect(page.contains('const $name'), isTrue, reason: name);
    }
    expect(page.contains('SediGlass.blur'), isTrue);
    expect(page.contains('_SoftWave'), isTrue); // decoration only
    expect(page.contains('SediSceneBackdrop'), isTrue);
  });

  test('digits helper follows the language numerals', () {
    expect(LifestyleL10n('fa').digits(12), '۱۲');
    expect(LifestyleL10n('en').digits(12), '12');
  });
}
