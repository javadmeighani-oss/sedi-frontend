import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../domain/schedule_today.dart';
import '../lifestyle_l10n.dart';
import 'schedule_add_sheets.dart';

/// Reminder presets (minutes before the event); null = reminder off. 1440 = one day, 60 = one hour.
const List<int?> kSchedulePresets = <int?>[null, 0, 15, 30, 60, 1440];

String schedulePresetLabel(LifestyleL10n l10n, int? minutes) {
  switch (minutes) {
    case 0:
      return l10n.reminderAtTime;
    case 15:
      return l10n.reminder15;
    case 30:
      return l10n.reminder30;
    case 60:
      return l10n.reminder1h;
    case 1440:
      return l10n.reminder1d;
    default:
      return l10n.reminderOff;
  }
}

/// What the "add" sheet returns. A medication carries its dose [times]; everything else a start, a lead and an
/// optional repeat ([recurrenceRule]: `FREQ=DAILY` or `FREQ=WEEKLY;BYDAY=SA,MO` - the same time on those days).
class NewReminderInput {
  final ScheduleAddType type;
  final String title;
  final DateTime startsAt;
  final int offsetMinutes;
  final String? recurrenceRule;
  final List<String> times;
  const NewReminderInput({
    this.type = ScheduleAddType.free,
    required this.title,
    required this.startsAt,
    required this.offsetMinutes,
    this.recurrenceRule,
    this.times = const <String>[],
  });
}

/// ONE glass sheet for everything the user adds (pilot V1, R-034): the type as four icons, a title, the day and the
/// time, the repeat (once / every day / chosen weekdays at the SAME time) and when to notify. A medication keeps
/// its list of dose times instead of a single time and a repeat.
class ScheduleAddReminderSheet extends StatefulWidget {
  final LifestyleL10n l10n;
  const ScheduleAddReminderSheet({super.key, required this.l10n});

  @override
  State<ScheduleAddReminderSheet> createState() =>
      _ScheduleAddReminderSheetState();
}

enum _Repeat { once, daily, days }

class _ScheduleAddReminderSheetState extends State<ScheduleAddReminderSheet> {
  final _title = TextEditingController();
  ScheduleAddType _type = ScheduleAddType.free;
  late DateTime _date;
  late TimeOfDay _time;
  int _offset = 0;
  _Repeat _repeat = _Repeat.once;
  late Set<int> _days;
  final List<String> _medTimes = <String>['08:00'];
  String? _error;

  LifestyleL10n get _l10n => widget.l10n;
  bool get _isMed => _type == ScheduleAddType.medication;

  @override
  void initState() {
    super.initState();
    final soon = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(soon.year, soon.month, soon.day);
    _time = TimeOfDay(hour: soon.hour, minute: 0);
    _days = <int>{_date.weekday};
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime get _startsAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _addMedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final v = _fmt(picked);
    if (_medTimes.contains(v)) return;
    setState(() {
      _medTimes
        ..add(v)
        ..sort();
      _error = null;
    });
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = _isMed ? _l10n.medNeedName : _l10n.reminderNeedsTitle);
      return;
    }
    if (_isMed) {
      if (_medTimes.isEmpty) {
        setState(() => _error = _l10n.medNeedTime);
        return;
      }
      Navigator.of(context).pop(
        NewReminderInput(
          type: _type,
          title: title,
          startsAt: _startsAt,
          offsetMinutes: 0,
          times: List.of(_medTimes),
        ),
      );
      return;
    }
    String? rule;
    switch (_repeat) {
      case _Repeat.once:
        rule = null;
        break;
      case _Repeat.daily:
        rule = recurrenceRuleFor(daily: true);
        break;
      case _Repeat.days:
        rule = recurrenceRuleFor(daily: false, isoWeekdays: _days);
        if (rule == null) {
          setState(() => _error = _l10n.pickDays);
          return;
        }
        break;
    }
    // A one-off must lie ahead; a series may start today even if this hour has passed (it fires on its days).
    if (rule == null && !_startsAt.isAfter(DateTime.now())) {
      setState(() => _error = _l10n.pickFutureTime);
      return;
    }
    Navigator.of(context).pop(
      NewReminderInput(
        type: _type,
        title: title,
        startsAt: _startsAt,
        offsetMinutes: _offset,
        recurrenceRule: rule,
      ),
    );
  }

  // ------------------------------------------------------------------ pieces
  BoxDecoration _selected(double radius) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          radius: 1.1,
          colors: [
            Color(0xFFF6FBD6),
            Color(0xFFCFE27C),
            Color(0xFFA9C648),
            Color(0xFF8FAE3E),
          ],
          stops: [0.0, 0.36, 0.78, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x57608022),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      );

  Widget _typeButton(ScheduleAddType t, IconData icon, String label) {
    final on = _type == t;
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _type = t;
            _error = null;
          }),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: on ? _selected(20) : SediGlass.tile(),
                child: Icon(
                  icon,
                  size: 28,
                  color: on ? SediGlass.inkDeep : SediGlass.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: SediGlass.inkDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, VoidCallback onTap, {TextDirection? dir}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: SediGlass.tile().copyWith(
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: SediGlass.ink),
                const SizedBox(width: 8),
                Directionality(
                  textDirection: dir ?? Directionality.of(context),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SediGlass.inkDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment(List<String> labels, int selected, ValueChanged<int> onPick) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        color: Colors.white.withOpacity(0.4),
        border: Border.all(color: Colors.white.withOpacity(0.85)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: i == selected ? _selected(20) : null,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: i == selected ? FontWeight.w800 : FontWeight.w700,
                      color: i == selected ? SediGlass.inkDeep : SediGlass.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayCircles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final w in _l10n.weekOrder)
          Semantics(
            button: true,
            selected: _days.contains(w),
            label: _l10n.weekdayShort(w),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                if (!_days.add(w)) _days.remove(w);
                _error = null;
              }),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: _days.contains(w)
                    ? _selected(21)
                    : SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(21)),
                child: Text(
                  _l10n.weekdayInitial(w),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _days.contains(w) ? FontWeight.w800 : FontWeight.w700,
                    color: _days.contains(w) ? SediGlass.inkDeep : SediGlass.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _leadChips() {
    const leads = <int>[0, 15, 30, 60, 1440];
    return Row(
      children: [
        const Icon(Icons.notifications_none_rounded, size: 22, color: SediGlass.ink),
        const SizedBox(width: 8),
        for (final m in leads)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _offset = m),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: _offset == m
                      ? _selected(18)
                      : SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(18)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _l10n.presetShort(m),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _offset == m ? FontWeight.w800 : FontWeight.w700,
                        color: _offset == m ? SediGlass.inkDeep : SediGlass.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _medTimesRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _medTimes)
          Container(
            height: 42,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 6, 0),
            decoration: SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(21)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _l10n.digits(t),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: SediGlass.inkDeep,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _l10n.deleteItem,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18, color: SediGlass.ink),
                  onPressed: () => setState(() => _medTimes.remove(t)),
                ),
              ],
            ),
          ),
        Tooltip(
          message: _l10n.addTime,
          child: GestureDetector(
            onTap: _addMedTime,
            child: Container(
              width: 42,
              height: 42,
              decoration: _selected(21),
              child: const Icon(Icons.add_rounded, size: 24, color: SediGlass.inkDeep),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = _l10n;
    final iso =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final isToday =
        _date.year == now.year && _date.month == now.month && _date.day == now.day;
    final dayText = isToday
        ? l10n.today
        : CalendarDateMath.formatIsoForLanguage(iso, l10n.lang);
    final timeText = l10n.timeText(_startsAt);
    const radius = BorderRadius.all(Radius.circular(36));
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 12 + bottom),
        child: SafeArea(
          top: false,
          child: SediGlass.blur(
            radius: radius,
            sigma: 26,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.74),
                    Colors.white.withOpacity(0.46),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.88)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0x5948551F),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _typeButton(ScheduleAddType.medication,
                            Icons.medication_outlined, l10n.typeMedication),
                        _typeButton(ScheduleAddType.appointment,
                            Icons.local_hospital_outlined, l10n.typeAppointment),
                        _typeButton(ScheduleAddType.meeting,
                            Icons.groups_outlined, l10n.typeMeeting),
                        _typeButton(ScheduleAddType.free,
                            Icons.notifications_active_outlined, l10n.typeFree),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        color: Colors.white.withOpacity(0.7),
                        border: Border.all(color: const Color(0xFF8FAE3E), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 22, color: SediGlass.ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _title,
                              cursorColor: SediGlass.ink,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: _isMed ? l10n.medName : l10n.titleField,
                                hintStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: SediPalette.sageMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isMed)
                      _medTimesRow()
                    else ...[
                      Row(
                        children: [
                          _pill(Icons.calendar_today_outlined, dayText, _pickDate),
                          const SizedBox(width: 10),
                          _pill(Icons.schedule_rounded, timeText, _pickTime,
                              dir: TextDirection.ltr),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.repeat_rounded, size: 22, color: SediGlass.ink),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _segment(
                              [l10n.repeatOnce, l10n.repeatDaily, l10n.repeatDays],
                              _repeat.index,
                              (i) => setState(() {
                                _repeat = _Repeat.values[i];
                                _error = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (_repeat == _Repeat.days) ...[
                        const SizedBox(height: 10),
                        _dayCircles(),
                      ],
                      const SizedBox(height: 12),
                      _leadChips(),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppTheme.dangerRed),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppTheme.dangerRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: l10n.cancel,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 52,
                              height: 52,
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
                              child: const Icon(Icons.close_rounded, size: 24, color: SediGlass.ink),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Tooltip(
                          message: l10n.save,
                          child: GestureDetector(
                            key: const ValueKey('schedule-add-save'),
                            onTap: _submit,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: SediGlass.pistachioSphere(),
                              child: const Icon(Icons.check_rounded,
                                  size: 30, color: SediGlass.inkDeep),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: pick when to be notified for an existing item (null = off).
Future<ReminderPresetChoice?> showReminderPresetSheet(
  BuildContext context, {
  required LifestyleL10n l10n,
  required int? current,
}) {
  return showModalBottomSheet<ReminderPresetChoice>(
    context: context,
    backgroundColor: AppTheme.gate2CardWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.reminderWhen,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              for (final m in kSchedulePresets)
                ListTile(
                  dense: true,
                  leading: Icon(
                    m == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: SediPalette.pistachio900,
                  ),
                  title: Text(
                    schedulePresetLabel(l10n, m),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () => Navigator.of(ctx).pop(ReminderPresetChoice(m)),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Wraps the chosen preset so "off" (null minutes) can be told apart from "sheet dismissed" (null result).
class ReminderPresetChoice {
  final int? minutes;
  const ReminderPresetChoice(this.minutes);
}
