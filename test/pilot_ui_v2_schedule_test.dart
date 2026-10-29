import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/domain/schedule_today.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/schedule_add_sheets.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/schedule_reminder_sheets.dart';

String _read(String path) => File(path).readAsStringSync();

Future<NewReminderInput?> _open(WidgetTester tester, {String lang = 'fa'}) async {
  NewReminderInput? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<NewReminderInput>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ScheduleAddReminderSheet(l10n: LifestyleL10n(lang)),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

/// Pilot V1 screen 5 (R-034 / R-035, Javad 2026-10-29): My Schedule is short words and icons, one add sheet with day,
/// time and a repeat at the same time on chosen weekdays; the only notification setting is the bell (how many).
void main() {
  test('the repeat rule the sheet stores is the one the backend scheduler understands', () {
    expect(recurrenceRuleFor(daily: true), 'FREQ=DAILY');
    expect(recurrenceRuleFor(daily: false), isNull);
    expect(recurrenceRuleFor(daily: false, isoWeekdays: {1}), 'FREQ=WEEKLY;BYDAY=MO');
    // sorted Monday..Sunday no matter the tap order (Saturday, Monday, Wednesday)
    expect(recurrenceRuleFor(daily: false, isoWeekdays: {6, 1, 3}), 'FREQ=WEEKLY;BYDAY=MO,WE,SA');
    expect(recurrenceRuleFor(daily: false, isoWeekdays: {0, 9}), isNull);
  });

  test('a series on several weekdays occurs on exactly those days', () {
    final first = DateTime(2026, 10, 26, 21, 30); // Monday
    const rule = 'FREQ=WEEKLY;BYDAY=MO,WE,SA';
    expect(ruleOccursOn(rule, DateTime(2026, 10, 26), first), isTrue); // Mon
    expect(ruleOccursOn(rule, DateTime(2026, 10, 27), first), isFalse); // Tue
    expect(ruleOccursOn(rule, DateTime(2026, 10, 28), first), isTrue); // Wed
    expect(ruleOccursOn(rule, DateTime(2026, 10, 31), first), isTrue); // Sat
    expect(ruleOccursOn(rule, DateTime(2026, 11, 1), first), isFalse); // Sun
    expect(ruleOccursOn(rule, DateTime(2026, 10, 24), first), isFalse); // before the first date
    // the old single-day form still works
    expect(ruleOccursOn('FREQ=WEEKLY;BYDAY=TU', DateTime(2026, 10, 27), first), isTrue);
  });

  test('the repeat label lists several weekdays and never loses the time', () {
    final fa = LifestyleL10n('fa');
    expect(fa.repeatLabel('FREQ=DAILY', '2026-10-26T21:30:00'), 'هر روز · 21:30');
    final multi = fa.repeatLabel('FREQ=WEEKLY;BYDAY=MO,WE', '2026-10-26T21:30:00')!;
    expect(multi.contains('دوشنبه'), isTrue);
    expect(multi.contains('چهارشنبه'), isTrue);
    expect(multi.contains('21:30'), isTrue);
    expect(fa.repeatLabel('FREQ=WEEKLY;BYDAY=TU', '2026-10-26T08:00:00')!.startsWith('هر'), isTrue);
  });

  test('short words exist in fa / ar / en', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final l = LifestyleL10n(lang);
      for (final s in [l.addAction, l.titleField, l.repeatOnce, l.repeatDaily, l.repeatDays, l.pickDays, l.typeFree]) {
        expect(s.trim(), isNotEmpty, reason: lang);
      }
      for (var w = 1; w <= 7; w++) {
        expect(l.weekdayInitial(w), isNotEmpty, reason: '$lang $w');
      }
      for (final m in [0, 15, 30, 60, 1440]) {
        expect(l.presetShort(m).trim(), isNotEmpty, reason: '$lang $m');
      }
      expect(l.weekOrder.toSet().length, 7);
    }
    expect(LifestyleL10n('fa').addAction, 'افزودن'); // «افزودن به برنامه‌ام» became just «افزودن»
    expect(LifestyleL10n('fa').weekOrder.first, 6); // the week starts on Saturday in Persian
    expect(LifestyleL10n('en').weekOrder.first, 1);
    expect(LifestyleL10n('fa').weekdayInitial(6), 'ش');
  });

  testWidgets('a repeat on chosen weekdays needs at least one day, then returns the rule', (tester) async {
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'ورزش');
    // «روزها» = the third segment
    await tester.tap(find.text(LifestyleL10n('fa').repeatDays));
    await tester.pump();
    // the date's own weekday is preselected: deselect it, then saving asks for a day
    final initial = LifestyleL10n('fa').weekdayInitial(DateTime.now().add(const Duration(hours: 1)).weekday);
    await tester.tap(find.text(initial).first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule-add-save')));
    await tester.pump();
    expect(find.text(LifestyleL10n('fa').pickDays), findsOneWidget);
    await tester.tap(find.text(initial).first);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule-add-save')));
    await tester.pumpAndSettle();
    // the sheet closed with a weekly rule on that day
    expect(find.byType(ScheduleAddReminderSheet), findsNothing);
  });

  testWidgets('every day = FREQ=DAILY and the lead defaults to on time', (tester) async {
    NewReminderInput? out;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                out = await showModalBottomSheet<NewReminderInput>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ScheduleAddReminderSheet(l10n: LifestyleL10n('fa')),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'آب بخورم');
    await tester.tap(find.text(LifestyleL10n('fa').repeatDaily));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule-add-save')));
    await tester.pumpAndSettle();
    expect(out, isNotNull);
    expect(out!.recurrenceRule, 'FREQ=DAILY');
    expect(out!.offsetMinutes, 0);
    expect(out!.type, ScheduleAddType.free);
  });

  test('the page: one add sheet, an icon-only bell, no notification card, the sphere beside the title', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart');
    expect(page.indexOf('const SediHologramOrb('), lessThan(page.indexOf('l10n.mySchedule')));
    expect(page.contains('Widget _addPill('), isTrue);
    expect(page.contains('l10n.addAction'), isTrue);
    expect(page.contains('l10n.addToSchedule'), isFalse); // the long label is gone
    expect(page.contains('recurrenceRule: input.recurrenceRule'), isTrue);
    expect(page.contains('showScheduleAmountSheet'), isTrue);
    expect(page.contains('Icons.notifications_none_rounded'), isTrue);
    final sheet = _read('lib/features/lifestyle/presentation/widgets/schedule_amount_sheet.dart');
    expect(sheet.contains("_chip('low'"), isTrue);
    expect(sheet.contains("_chip('normal'"), isTrue);
    expect(sheet.contains("_chip('high'"), isTrue);
    expect(sheet.contains('quiet'), isFalse);
  });
}
