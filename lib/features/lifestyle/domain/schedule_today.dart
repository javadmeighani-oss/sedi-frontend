import '../../../services/lifestyle/lifestyle_schedule_service.dart';

/// Categories of My Schedule (R-031 redesign). The category is a coarse label for the user's eyes and the only thing
/// Sedi's memory keeps about a done item - never its title.
enum ScheduleCategory { medication, appointment, meeting, other }

const Set<String> _appointmentTypes = {
  'doctor_visit',
  'lab_test',
  'imaging',
  'surgery',
  'physiotherapy',
  'nursing_visit',
  'care_followup',
  'medication_review',
};
const Set<String> _meetingTypes = {'work_meeting', 'exam', 'deadline'};

ScheduleCategory categoryForEvent(String? eventType) {
  if (eventType != null && _appointmentTypes.contains(eventType)) {
    return ScheduleCategory.appointment;
  }
  if (eventType != null && _meetingTypes.contains(eventType)) {
    return ScheduleCategory.meeting;
  }
  return ScheduleCategory.other;
}

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// One line of the user's day: a medication dose or an event occurrence.
class ScheduleItem {
  /// 'event' | 'medication'
  final String kind;
  final int refId;
  final String title;

  /// Local date-time of this occurrence.
  final DateTime when;
  final ScheduleCategory category;
  final String? recurrenceRule;
  final bool fromChat;

  /// Minutes before; null = reminder off.
  final int? reminderMinutes;

  /// 'HH:MM' for a medication dose.
  final String? medTime;
  final LifestyleUserEventDto? event;
  final bool done;

  const ScheduleItem({
    required this.kind,
    required this.refId,
    required this.title,
    required this.when,
    required this.category,
    this.recurrenceRule,
    this.fromChat = false,
    this.reminderMinutes,
    this.medTime,
    this.event,
    this.done = false,
  });

  /// Same id the backend ledger uses: `event:12:20261028` / `medication:5:20261028:0800`.
  String get occurrenceId {
    final base = '$kind:$refId:${ymd(when)}';
    return medTime == null ? base : '$base:${medTime!.replaceAll(':', '')}';
  }

  ScheduleItem withDone(bool value) => ScheduleItem(
        kind: kind,
        refId: refId,
        title: title,
        when: when,
        category: category,
        recurrenceRule: recurrenceRule,
        fromChat: fromChat,
        reminderMinutes: reminderMinutes,
        medTime: medTime,
        event: event,
        done: value,
      );
}

const _byDay = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Does a stored rule (`FREQ=DAILY`, `FREQ=WEEKLY;BYDAY=MO`) occur on [day], given the series' first date?
bool ruleOccursOn(String? rule, DateTime day, DateTime first) {
  if (rule == null || !rule.startsWith('FREQ=')) return false;
  final d = DateTime(day.year, day.month, day.day);
  final f = DateTime(first.year, first.month, first.day);
  if (d.isBefore(f)) return false;
  if (rule.contains('FREQ=DAILY')) return true;
  if (rule.contains('FREQ=WEEKLY')) {
    final m = RegExp(r'BYDAY=([A-Z]{2})').firstMatch(rule);
    final code = m?.group(1) ?? _byDay[f.weekday - 1];
    return _byDay[d.weekday - 1] == code;
  }
  return false;
}

int? _reminderOf(LifestyleUserEventDto e) => !e.reminderEnabled
    ? null
    : (e.reminderOffsets.isEmpty ? 0 : e.reminderOffsets.first);

DateTime? _parseLocal(String? s) => s == null ? null : DateTime.tryParse(s.trim());

/// Everything the user has for [today], earliest first. [doneIds] are ledger occurrence ids already marked done.
List<ScheduleItem> buildToday({
  required List<LifestyleUserEventDto> events,
  required List<LifestyleMedicationDto> medications,
  required Set<String> doneIds,
  required DateTime today,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final out = <ScheduleItem>[];
  for (final e in events) {
    final start = _parseLocal(e.startsAt);
    if (start == null) continue;
    final repeats = e.recurrenceRule != null;
    final occursToday = repeats
        ? ruleOccursOn(e.recurrenceRule, day, start)
        : DateTime(start.year, start.month, start.day) == day;
    if (!occursToday) continue;
    final when = DateTime(day.year, day.month, day.day, start.hour, start.minute);
    final item = ScheduleItem(
      kind: 'event',
      refId: e.id,
      title: e.title,
      when: when,
      category: categoryForEvent(e.eventType),
      recurrenceRule: e.recurrenceRule,
      fromChat: e.source == 'conversation',
      reminderMinutes: _reminderOf(e),
      event: e,
    );
    out.add(item.withDone(
        doneIds.contains(item.occurrenceId) || (!repeats && e.status == 'completed')));
  }
  for (final m in medications) {
    if (!m.reminderEnabled) continue;
    for (final t in m.reminderTimes) {
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]);
      final mi = int.tryParse(parts[1]);
      if (h == null || mi == null) continue;
      final hhmm =
          '${h.toString().padLeft(2, '0')}:${mi.toString().padLeft(2, '0')}';
      final item = ScheduleItem(
        kind: 'medication',
        refId: m.id,
        title: m.name,
        when: DateTime(day.year, day.month, day.day, h, mi),
        category: ScheduleCategory.medication,
        recurrenceRule: 'FREQ=DAILY',
        reminderMinutes: 0,
        medTime: hhmm,
      );
      out.add(item.withDone(doneIds.contains(item.occurrenceId)));
    }
  }
  out.sort((a, b) {
    final c = a.when.compareTo(b.when);
    if (c != 0) return c;
    final k = a.kind.compareTo(b.kind); // events before medication doses at the same minute
    if (k != 0) return k;
    return a.title.compareTo(b.title);
  });
  return out;
}

/// One-off events after today (the next [days] days), earliest first.
List<ScheduleItem> buildUpcoming({
  required List<LifestyleUserEventDto> events,
  required DateTime today,
  int days = 30,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final end = day.add(Duration(days: days));
  final out = <ScheduleItem>[];
  for (final e in events) {
    if (e.recurrenceRule != null) continue;
    final start = _parseLocal(e.startsAt);
    if (start == null) continue;
    final d = DateTime(start.year, start.month, start.day);
    if (!d.isAfter(day) || d.isAfter(end)) continue;
    out.add(ScheduleItem(
      kind: 'event',
      refId: e.id,
      title: e.title,
      when: start,
      category: categoryForEvent(e.eventType),
      fromChat: e.source == 'conversation',
      reminderMinutes: _reminderOf(e),
      event: e,
      done: e.status == 'completed',
    ));
  }
  out.sort((a, b) => a.when.compareTo(b.when));
  return out;
}

/// The next item that is not done and not already past (falls back to the first undone one of the day).
ScheduleItem? nextUp(List<ScheduleItem> today, DateTime now) {
  final open = today.where((i) => !i.done).toList();
  if (open.isEmpty) return null;
  for (final i in open) {
    if (!i.when.isBefore(now)) return i;
  }
  return open.first;
}

class ScheduleDaySummary {
  final int total;
  final int done;
  final ScheduleItem? next;
  const ScheduleDaySummary(this.total, this.done, this.next);
}

ScheduleDaySummary summarize(List<ScheduleItem> today, DateTime now) =>
    ScheduleDaySummary(
        today.length, today.where((i) => i.done).length, nextUp(today, now));
