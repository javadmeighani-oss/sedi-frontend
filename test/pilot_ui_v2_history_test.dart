import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screen 4 (R-034 / R-035, Javad 2026-10-29): My History is a search that works, ONE last day above a
/// compact calendar, no summaries card and no "note for a day" button; the note / correction box exists only inside an
/// opened day.
void main() {
  final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart');
  final day = _read('lib/features/lifestyle/presentation/pages/memory_day_page.dart');
  final cal = _read('lib/features/lifestyle/presentation/widgets/history_calendar_card.dart');

  test('the sphere sits on the start side of the title on both history pages (R-035)', () {
    expect(page.indexOf('const SediHologramOrb('), lessThan(page.indexOf('l10n.myHistory')));
    expect(day.indexOf('const SediHologramOrb('), lessThan(day.indexOf('dateLabel,')));
  });

  test('search is a real input with a submit button; a too-short query tells the user instead of doing nothing', () {
    expect(page.contains('TextField('), isTrue);
    expect(page.contains('onSubmitted: _openSearch'), isTrue);
    expect(page.contains('onTap: () => _openSearch(_searchController.text)'), isTrue);
    expect(page.contains('MemorySearchPage('), isTrue);
    expect(page.contains('if (q.length < 2)'), isTrue);
  });

  test('ONE last day comes before the calendar, and the old extras are gone', () {
    expect(page.indexOf('..._lastDayCard(l10n)'), lessThan(page.indexOf('HistoryCalendarCard(')));
    expect(page.contains('past.first'), isTrue);
    expect(page.contains('.take(7)'), isFalse);
    expect(page.contains('recentDays'), isFalse);
    expect(page.contains('l10n.noteForDay'), isFalse); // no "note for a day" button on the home page
    expect(page.contains('bottomNavigationBar'), isFalse);
    expect(page.contains('showMemoryTextSheet'), isFalse);
    expect(page.contains('_addNote'), isFalse);
    expect(page.contains('_loadSummary'), isFalse);
    expect(page.contains('/memory/period-summary'), isFalse);
  });

  test('the calendar is compact glass with dots', () {
    expect(cal.contains('childAspectRatio: 1.35'), isTrue);
    expect(cal.contains('SediGlass.card'), isTrue);
    expect(cal.contains('A3DestinationCard'), isFalse);
    expect(cal.contains('widget.memoryDays.contains(iso)'), isTrue);
  });

  test('the edit box exists only inside a day: a note, or a correction beside the summary of an older day', () {
    expect(day.contains('Widget _noteBox('), isTrue);
    expect(day.contains('if (showBox)'), isTrue);
    expect(day.contains('correction: !day!.rawVisible'), isTrue);
    expect(day.contains("kind: correction ? 'correction' : 'note'"), isTrue);
    expect(day.contains('correctionExplain'), isTrue); // the original summary is never rewritten
    expect(page.contains('_noteBox'), isFalse);
  });

  test('conversation lines are justified and the cards are glass', () {
    expect(day.contains('textAlign: TextAlign.justify'), isTrue);
    expect(day.contains('class _GlassCard'), isTrue);
    expect(day.contains('A3DestinationCard('), isFalse);
  });

  test('short strings exist in fa / ar / en', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final l = LifestyleL10n(lang);
      for (final s in [l.historyExplain, l.dayNoteBox, l.dayCorrectionBox]) {
        expect(s.trim(), isNotEmpty, reason: lang);
      }
      expect(l.historyExplain.length, lessThan(110), reason: '$lang the rule is one short line');
    }
  });
}
