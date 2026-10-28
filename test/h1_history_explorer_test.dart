import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/domain/history_calendar.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/services/lifestyle/memory_explorer_service.dart';

String _read(String path) => File(path).readAsStringSync();

/// H1 (Javad 2026-10-28): My History is a memory explorer - search, calendar, one-day view. Raw chat text is shown and
/// editable only inside the 30-day window; older days show derived summaries and the user's corrections sit beside them.
void main() {
  group('history calendar math (backend ISO days, no device clock)', () {
    test('Aban 1405 starts on Friday 2026-10-23 and has 30 days', () {
      final m = HistoryMonth.containing(HistoryCalendar.jalali, '2026-10-28')!;
      expect([m.year, m.month, m.length], [1405, 8, 30]);
      expect(m.fromIso, '2026-10-23');
      expect(m.toIso, '2026-11-21');
      expect(m.leadingBlanks(historyWeekStart('fa')), 6); // Saturday-first week, month starts Friday
    });

    test('Gregorian and month shifting roll the year', () {
      final g = HistoryMonth.containing(HistoryCalendar.gregorian, '2026-10-28')!;
      expect([g.length, g.fromIso, g.toIso], [31, '2026-10-01', '2026-10-31']);
      expect(g.leadingBlanks(historyWeekStart('en')), 4); // Sunday-first, Thursday start
      final next = g.shifted(3);
      expect([next.year, next.month], [2027, 1]);
      final back = g.shifted(-10);
      expect([back.year, back.month], [2025, 12]);
      final j = HistoryMonth.containing(HistoryCalendar.jalali, '2026-03-21')!; // 1 Farvardin 1405
      expect([j.year, j.month, j.isoOf(1)], [1405, 1, '2026-03-21']);
      expect(j.shifted(-1).month, 12);
    });

    test('invalid backend date fails closed and isoMinusDays works on ISO text', () {
      expect(HistoryMonth.containing(HistoryCalendar.gregorian, 'oops'), isNull);
      expect(HistoryMonth.containing(HistoryCalendar.gregorian, null), isNull);
      expect(isoMinusDays('2026-10-28', 31), '2026-09-27');
      expect(isoMinusDays(null, 3), isNull);
      expect(historyCalendarFor('fa'), HistoryCalendar.jalali);
      expect(historyCalendarFor('ar'), HistoryCalendar.hijri);
      expect(historyCalendarFor('en'), HistoryCalendar.gregorian);
    });
  });

  test('MemoryDayDto parses the backend day payload', () {
    final day = MemoryDayDto.fromJson({
      'date': '2026-10-26',
      'days_ago': 2,
      'raw_visible': true,
      'consent': true,
      'turns': [
        {'id': 7, 'time': '10:12', 'user_message': 'سلام', 'sedi_response': 'سلام جواد'}
      ],
      'summary': {
        'text': 'درباره‌ی خواب حرف زدیم.',
        'chips': {'topics': ['sleep'], 'wellbeing': ['fatigue'], 'plan_done': 1, 'plan_total': 3, 'user_done': 2},
      },
      'events': [
        {'id': 3, 'title': 'نوبت دکتر', 'life_event': true, 'starts_at': '2026-10-26T13:00:00'}
      ],
      'notes': [
        {'id': 4, 'kind': 'correction', 'text': 'درست نبود'}
      ],
      'facts': [
        {'id': 5, 'value': 'دیابت', 'editable': true}
      ],
    });
    expect(day.rawVisible, isTrue);
    expect(day.turns.single.id, 7);
    expect(day.turns.single.sediResponse, 'سلام جواد');
    expect(day.chips.userDone, 2);
    expect(day.chips.isEmpty, isFalse);
    expect(day.events.single.timeLabel, '13:00');
    expect(day.events.single.lifeEvent, isTrue);
    expect(day.notes.single.isCorrection, isTrue);
    expect(day.facts.single.editable, isTrue);
    expect(MemoryDayDto.fromJson({'date': 'x'}).turns, isEmpty);
  });

  test('every H1 string exists in fa/en/ar', () {
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      for (final s in [
        l.searchMemoryHint, l.memoryDotLegend, l.recentDays, l.noteForDay, l.dayConversations, l.sediDaySummary,
        l.eventsAndNotes, l.learnedThatDay, l.addItem, l.editItem, l.oldDayBanner, l.fixSummary, l.correctionsTitle,
        l.correctionExplain, l.correctionLabel, l.noteLabel, l.correctionHint, l.noteHint, l.emptyDay,
        l.memoryConsentOff, l.searchOldDaysNote, l.rangeAll, l.hitType('fact'), l.monthName('jalali', 8),
        l.daysAgoLabel(4),
      ]) {
        expect(s, isNotEmpty, reason: lang);
      }
    }
    expect(LifestyleL10n('fa').monthName('jalali', 8), 'آبان');
    expect(LifestyleL10n('fa').oldDayBanner.contains('سدی'), isFalse);
    expect(LifestyleL10n('fa').searchOldDaysNote.contains('صدی'), isTrue);
  });

  test('the page and day view follow the 30-day / correction-note rules', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart');
    expect(page.contains('MemorySearchPage'), isTrue);
    expect(page.contains('HistoryCalendarCard'), isTrue);
    expect(page.contains('MemoryDayPage'), isTrue);
    expect(page.contains('DateTime.now()'), isFalse); // today comes from the backend
    final day = _read('lib/features/lifestyle/presentation/pages/memory_day_page.dart');
    expect(day.contains('rawVisible'), isTrue);
    expect(day.contains("kind: correction ? 'correction' : 'note'"), isTrue);
    expect(day.contains('correctionExplain'), isTrue); // the original summary is never rewritten
    expect(day.contains('DateTime.now()'), isFalse);
    final svc = _read('lib/services/lifestyle/memory_explorer_service.dart');
    for (final path in ["'/memory/calendar'", "'/memory/day'", "'/memory/search'", "'/memory/turns/\$id'", "'/memory/day-notes'"]) {
      expect(svc.contains(path), isTrue, reason: path);
    }
    expect(svc.contains("'user_id'"), isFalse);
    final search = _read('lib/features/lifestyle/presentation/pages/memory_search_page.dart');
    expect(search.contains('searchOldDaysNote'), isTrue);
  });
}
