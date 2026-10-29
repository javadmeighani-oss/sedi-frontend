import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A7545),
            ),
          ),
        ),
      for (var i = 0; i < blanks; i++) const SizedBox.shrink(),
      for (var d = 1; d <= m.length; d++) _dayCell(m.isoOf(d), d),
    ];
    final radius = BorderRadius.circular(26);
    return SediGlass.blur(
      radius: radius,
      sigma: 16,
      child: DecoratedBox(
        decoration: SediGlass.card(radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  _arrow(
                    tooltip: l10n.nextMonth,
                    icon: rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    onTap: () => _shift(1),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 17, color: SediGlass.ink),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n.monthName(_calendar.name, m.month)} ${_digits(m.year)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: SediGlass.inkDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _arrow(
                    tooltip: l10n.prevMonth,
                    icon: rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    onTap: () => _shift(-1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: cells,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A small round glass arrow (44dp tap target around a 32dp disc).
  Widget _arrow({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.82),
                    Colors.white.withOpacity(0.32),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.92)),
              ),
              child: Icon(icon, size: 19, color: SediGlass.ink),
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onPick(iso),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected || today
                ? const RadialGradient(
                    center: Alignment(-0.3, -0.6),
                    radius: 1.6,
                    colors: [
                      Color(0xFFF6FBD6),
                      Color(0xFFCFE27C),
                      Color(0xFFA9C648),
                    ],
                  )
                : null,
            boxShadow: selected || today
                ? const [
                    BoxShadow(
                      color: Color(0x4D608022),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _digits(day),
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: (selected || today) ? FontWeight.w800 : FontWeight.w600,
                  color: (selected || today) ? SediGlass.inkDeep : const Color(0xFF2B3416),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: has ? const Color(0xFF5F7B22) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
