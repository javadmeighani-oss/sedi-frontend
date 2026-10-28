import '../../../core/locale/calendar_date_math.dart';

/// H1: month grids for the My History calendar. Pure presentation math over backend ISO days
/// (en = Gregorian, fa = Jalali, ar = Hijri). Never reads the device clock: "today" is supplied by the backend.
enum HistoryCalendar { jalali, gregorian, hijri }

HistoryCalendar historyCalendarFor(String languageCode) {
  switch (languageCode) {
    case 'fa':
      return HistoryCalendar.jalali;
    case 'ar':
      return HistoryCalendar.hijri;
    default:
      return HistoryCalendar.gregorian;
  }
}

/// ISO weekday (1=Mon..7=Sun) the calendar week starts on: Saturday for fa/ar, Sunday for en.
int historyWeekStart(String languageCode) =>
    (languageCode == 'fa' || languageCode == 'ar') ? 6 : 7;

String _pad(int n) => n.toString().padLeft(2, '0');

String isoOfDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_pad(d.month)}-${_pad(d.day)}';

class HistoryMonth {
  final HistoryCalendar calendar;
  final int year;
  final int month;

  const HistoryMonth(this.calendar, this.year, this.month);

  /// The month (in [calendar]) that contains the backend ISO date [iso]; null when [iso] is not a date.
  static HistoryMonth? containing(HistoryCalendar calendar, String? iso) {
    final d = CalendarDateMath.parseIsoLocalDate(iso);
    if (d == null) return null;
    switch (calendar) {
      case HistoryCalendar.jalali:
        final j = CalendarDateMath.gregorianToJalali(d.year, d.month, d.day);
        return HistoryMonth(calendar, j[0], j[1]);
      case HistoryCalendar.hijri:
        final h = CalendarDateMath.gregorianToHijri(d.year, d.month, d.day);
        return HistoryMonth(calendar, h[0], h[1]);
      case HistoryCalendar.gregorian:
        return HistoryMonth(calendar, d.year, d.month);
    }
  }

  HistoryMonth shifted(int delta) {
    final index = year * 12 + (month - 1) + delta;
    return HistoryMonth(calendar, index ~/ 12, index % 12 + 1);
  }

  int get length {
    switch (calendar) {
      case HistoryCalendar.jalali:
        return CalendarDateMath.jalaliMonthLength(year, month);
      case HistoryCalendar.hijri:
        return CalendarDateMath.hijriMonthLength(year, month);
      case HistoryCalendar.gregorian:
        return DateTime.utc(year, month + 1, 0).day;
    }
  }

  /// Gregorian date (UTC components) of day [day] of this month.
  DateTime gregorianOf(int day) {
    switch (calendar) {
      case HistoryCalendar.jalali:
        final g = CalendarDateMath.jalaliToGregorian(year, month, day);
        return DateTime.utc(g[0], g[1], g[2]);
      case HistoryCalendar.hijri:
        final g = CalendarDateMath.hijriToGregorian(year, month, day);
        return DateTime.utc(g[0], g[1], g[2]);
      case HistoryCalendar.gregorian:
        return DateTime.utc(year, month, day);
    }
  }

  String isoOf(int day) => isoOfDate(gregorianOf(day));

  String get fromIso => isoOf(1);
  String get toIso => isoOf(length);

  /// Empty cells before day 1 for a week that starts on ISO weekday [weekStart].
  int leadingBlanks(int weekStart) => (gregorianOf(1).weekday - weekStart + 7) % 7;

  bool sameMonth(HistoryMonth other) =>
      calendar == other.calendar && year == other.year && month == other.month;
}

/// Day numbers (1..length) of [m] -> ISO, in display order, for tests and the grid.
List<String> historyMonthIsoDays(HistoryMonth m) =>
    [for (var d = 1; d <= m.length; d++) m.isoOf(d)];

/// ISO date `days` before [iso] (calendar arithmetic on backend-supplied dates only).
String? isoMinusDays(String? iso, int days) {
  final d = CalendarDateMath.parseIsoLocalDate(iso);
  if (d == null) return null;
  return isoOfDate(d.subtract(Duration(days: days)));
}
