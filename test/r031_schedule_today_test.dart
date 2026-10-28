import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/domain/schedule_today.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/services/lifestyle/lifestyle_schedule_service.dart';

LifestyleUserEventDto _ev(
  int id,
  String title,
  String startsAt, {
  String? type,
  String? rule,
  String status = 'scheduled',
  String source = 'manual',
  List<int> offsets = const [60],
}) =>
    LifestyleUserEventDto(
      id: id,
      title: title,
      eventType: type,
      status: status,
      startsAt: startsAt,
      reminderEnabled: true,
      reminderOffsets: offsets,
      source: source,
      recurrenceRule: rule,
    );

/// R-031: the day's list (medication doses + event occurrences), what is next, and the ids the backend ledger uses.
void main() {
  final today = DateTime(2026, 10, 27, 9, 0); // a Tuesday

  test('categories are coarse and follow the event type', () {
    expect(categoryForEvent('doctor_visit'), ScheduleCategory.appointment);
    expect(categoryForEvent('lab_test'), ScheduleCategory.appointment);
    expect(categoryForEvent('work_meeting'), ScheduleCategory.meeting);
    expect(categoryForEvent('exam'), ScheduleCategory.meeting);
    expect(categoryForEvent('other'), ScheduleCategory.other);
    expect(categoryForEvent(null), ScheduleCategory.other);
  });

  test('repeat rules match the right days', () {
    final first = DateTime(2026, 10, 20, 8, 0); // Tuesday
    expect(ruleOccursOn('FREQ=DAILY', today, first), isTrue);
    expect(ruleOccursOn('FREQ=DAILY', DateTime(2026, 10, 19), first), isFalse); // before the series began
    expect(ruleOccursOn('FREQ=WEEKLY;BYDAY=TU', today, first), isTrue);
    expect(ruleOccursOn('FREQ=WEEKLY;BYDAY=MO', today, first), isFalse);
    expect(ruleOccursOn('FREQ=WEEKLY', today, first), isTrue); // no BYDAY: the first date's weekday
    expect(ruleOccursOn(null, today, first), isFalse);
    expect(ruleOccursOn('garbage', today, first), isFalse);
  });

  test('today lists one-off events, series occurrences and medication doses, earliest first', () {
    final items = buildToday(
      events: [
        _ev(1, 'جلسه', '2026-10-27T10:30:00', type: 'work_meeting', source: 'conversation'),
        _ev(2, 'آب', '2026-10-20T08:00:00', rule: 'FREQ=DAILY', type: 'other'),
        _ev(3, 'فردا', '2026-10-28T09:00:00'),
        _ev(4, 'هفتگی دوشنبه', '2026-10-19T07:00:00', rule: 'FREQ=WEEKLY;BYDAY=MO'),
      ],
      medications: const [
        LifestyleMedicationDto(id: 5, name: 'قرص فشار', reminderTimes: ['20:00', '08:00']),
        LifestyleMedicationDto(id: 6, name: 'خاموش', reminderTimes: ['09:00'], reminderEnabled: false),
      ],
      doneIds: <String>{},
      today: today,
    );
    expect(items.map((i) => i.title).toList(), ['آب', 'قرص فشار', 'جلسه', 'قرص فشار']);
    expect(items.map((i) => ymd(i.when)).toSet(), {'20261027'});
    final meeting = items.firstWhere((i) => i.title == 'جلسه');
    expect(meeting.category, ScheduleCategory.meeting);
    expect(meeting.fromChat, isTrue);
    expect(items.where((i) => i.kind == 'medication').every((i) => i.category == ScheduleCategory.medication), isTrue);
  });

  test('occurrence ids are exactly the ones the backend ledger writes', () {
    final items = buildToday(
      events: [_ev(12, 'x', '2026-10-27T10:30:00')],
      medications: const [LifestyleMedicationDto(id: 5, name: 'm', reminderTimes: ['08:00'])],
      doneIds: <String>{},
      today: today,
    );
    final ids = items.map((i) => i.occurrenceId).toSet();
    expect(ids, {'event:12:20261027', 'medication:5:20261027:0800'});
  });

  test('done ticks come from the ledger ids; a completed one-off is done; a series is not completed by status', () {
    final items = buildToday(
      events: [
        _ev(1, 'یک‌باره', '2026-10-27T10:30:00', status: 'completed'),
        _ev(2, 'سری', '2026-10-20T08:00:00', rule: 'FREQ=DAILY', status: 'completed'),
      ],
      medications: const [LifestyleMedicationDto(id: 5, name: 'قرص', reminderTimes: ['08:00', '20:00'])],
      doneIds: <String>{'medication:5:20261027:0800'},
      today: today,
    );
    bool doneOf(String title, {String? time}) =>
        items.firstWhere((i) => i.title == title && (time == null || i.medTime == time)).done;
    expect(doneOf('یک‌باره'), isTrue);
    expect(doneOf('سری'), isFalse); // the series' own status never marks a day
    expect(doneOf('قرص', time: '08:00'), isTrue);
    expect(doneOf('قرص', time: '20:00'), isFalse);
  });

  test('next up skips what is done and what is past', () {
    final items = buildToday(
      events: [_ev(1, 'جلسه', '2026-10-27T10:30:00'), _ev(2, 'دکتر', '2026-10-27T13:00:00')],
      medications: const [LifestyleMedicationDto(id: 5, name: 'قرص', reminderTimes: ['08:00'])],
      doneIds: <String>{},
      today: today,
    );
    expect(nextUp(items, DateTime(2026, 10, 27, 9, 0))!.title, 'جلسه');
    expect(nextUp(items, DateTime(2026, 10, 27, 11, 0))!.title, 'دکتر');
    final doneAll = [for (final i in items) i.withDone(true)];
    expect(nextUp(doneAll, today), isNull);
    final s = summarize(items, DateTime(2026, 10, 27, 9, 0));
    expect(s.total, 3);
    expect(s.done, 0);
  });

  test('upcoming lists only future one-off events', () {
    final up = buildUpcoming(
      events: [
        _ev(1, 'امروز', '2026-10-27T15:00:00'),
        _ev(2, 'فردا', '2026-10-28T09:00:00'),
        _ev(3, 'سری', '2026-10-20T08:00:00', rule: 'FREQ=DAILY'),
        _ev(4, 'خیلی دور', '2027-03-01T09:00:00'),
      ],
      today: today,
    );
    expect(up.map((i) => i.title).toList(), ['فردا']);
  });

  test('medication dto and l10n strings', () {
    final m = LifestyleMedicationDto.fromJson({
      'id': 9,
      'name': 'قرص',
      'reminder_times': ['08:00', '20:00'],
      'reminder_enabled': true,
    });
    expect(m.reminderTimes, ['08:00', '20:00']);
    expect(LifestyleMedicationDto.fromJson({'id': 1, 'name': 'x'}).reminderTimes, isEmpty);
    final fa = LifestyleL10n('fa');
    expect(fa.hubToday(4, 1), '۴ کار داری · ۱ تا انجام شد');
    expect(fa.hubToday(0, 0), 'امروز برنامه‌ای نداری.');
    expect(fa.relativeIn(const Duration(hours: 2)), '۲ ساعت دیگه');
    expect(fa.relativeIn(const Duration(minutes: 25)), '۲۵ دقیقه دیگه');
    expect(fa.timeText(DateTime(2026, 1, 1, 8, 5)), '۰۸:۰۵');
    expect(LifestyleL10n('en').hubToday(3, 1), '3 for today · 1 done');
    expect(fa.notifSettingsTitle, 'اعلان‌های صدی'); // simplified 2026-10-28 (was «صدی کِی و چی بهت خبر بده؟»)
  });

  test('the page wires done, add-by-type, medication and the compact notification card', () {
    final page = File('lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart').readAsStringSync();
    expect(page.contains('_svc.markDone('), isTrue);
    expect(page.contains('showAddTypeSheet('), isTrue);
    expect(page.contains('_svc.createMedication('), isTrue);
    expect(page.contains('ScheduleNotificationSettingsCard('), isTrue);
    expect(page.contains("eventType = 'doctor_visit'"), isTrue);
    final hub = File('lib/features/lifestyle/presentation/pages/lifestyle_page.dart').readAsStringSync();
    expect(hub.contains('summarize('), isTrue);
    final card = File('lib/features/lifestyle/presentation/widgets/schedule_notification_settings_card.dart').readAsStringSync();
    expect(card.contains("_channel('system'"), isFalse);
    expect(card.contains('notifLearningLine'), isTrue);
  });
}
