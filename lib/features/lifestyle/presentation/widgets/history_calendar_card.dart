import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../domain/history_calendar.dart';
import '../lifestyle_l10n.dart';

/// The My History calendar: one month, a dot under every day Sedi remembers something about.
/// [todayIso] is the backend's current day; the widget never reads the device clock.
class HistoryCalendarCard extends StatefulWidget {
  final String todayIso;
  final String? selectedIso;
  final Set<String> memoryDays;
  final LifestyleL10n l10n;
  final ValueChanged<String> onPick;
  final void Function(String fromIso, String toIso) onMonthChanged;

  const HistoryCalendarCard({
    super.key,
    required this.todayIso,
    required this.selectedIso,
    required this.memoryDays,
    required this.l10n,
    required this.onPick,
    required this.onMonthChanged,
  });

  @override
  State<HistoryCalendarCard> createState() => _HistoryCalendarCardState();
}

class _HistoryCalendarCardState extends State<HistoryCalendarCard> {
  late HistoryCalendar _calendar;
  HistoryMonth? _month;

  @override
  void initState() {
    super.initState();
    _calendar = historyCalendarFor(widget.l10n.lang);
    _month = HistoryMonth.containing(_calendar, widget.selectedIso ?? widget.todayIso);
    final m = _month;
    if (m != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onMonthChanged(m.fromIso, m.toIso);
      });
    }
  }

  void _shift(int delta) {
    final m = _month;
    if (m == null) return;
    final next = m.shifted(delta);
    setState(() => _month = next);
    widget.onMonthChanged(next.fromIso, next.toIso);
  }

  String _digits(Object n) =>
      CalendarDateMath.localizeDigitsForLanguage('$n', widget.l10n.lang);

  /// One-letter weekday header (two for English); Arabic drops the article so the letters differ.
  String _weekdayLetter(int isoWeekday) {
    var name = widget.l10n.weekdayShort(isoWeekday);
    if (widget.l10n.lang == 'ar' && name.startsWith('ال')) name = name.replaceFirst('ال', '');
    final take = widget.l10n.lang == 'en' ? 2 : 1;
    return String.fromCharCodes(name.runes.take(take));
  }

  @override
  Widget build(BuildContext context) {
    final m = _month;
    final l10n = widget.l10n;
    if (m == null) return const SizedBox.shrink();
    final weekStart = historyWeekStart(l10n.lang);
    final blanks = m.leadingBlanks(weekStart);
    final rtl = l10n.isRtl;
    final cells = <Widget>[
      for (var i = 0; i < 7; i++)
        Center(
          child: Text(
            _weekdayLetter((weekStart - 1 + i) % 7 + 1),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= m.length; d++) _dayCell(m.isoOf(d), d),
    ];
    return A3DestinationCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.nextMonth,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
                onPressed: () => _shift(1),
              ),
              Expanded(
                child: Text(
                  '${l10n.monthName(_calendar.name, m.month)} ${_digits(m.year)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.prevMonth,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: Icon(rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
                onPressed: () => _shift(-1),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _dayCell(String iso, int day) {
    final selected = iso == widget.selectedIso;
    final today = iso == widget.todayIso;
    final has = widget.memoryDays.contains(iso);
    return Semantics(
      button: true,
      label: iso,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onPick(iso),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: selected ? AppTheme.gate2ButtonOlive : null,
            borderRadius: BorderRadius.circular(14),
            border: today && !selected
                ? Border.all(color: AppTheme.gate2ButtonOlive, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _digits(day),
                style: TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: (selected || today) ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: has
                      ? (selected ? AppTheme.pistachioGreen : AppTheme.gate2ButtonOlive)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
