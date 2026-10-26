import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../lifestyle_l10n.dart';

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

/// Result of the "add a reminder" sheet.
class NewReminderInput {
  final String title;
  final DateTime startsAt;
  final int offsetMinutes;
  const NewReminderInput({
    required this.title,
    required this.startsAt,
    required this.offsetMinutes,
  });
}

/// Bottom sheet: what / date / time / when to notify.
class ScheduleAddReminderSheet extends StatefulWidget {
  final LifestyleL10n l10n;
  const ScheduleAddReminderSheet({super.key, required this.l10n});

  @override
  State<ScheduleAddReminderSheet> createState() =>
      _ScheduleAddReminderSheetState();
}

class _ScheduleAddReminderSheetState extends State<ScheduleAddReminderSheet> {
  final _title = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  int _offset = 0;
  String? _error;

  LifestyleL10n get _l10n => widget.l10n;

  @override
  void initState() {
    super.initState();
    final soon = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(soon.year, soon.month, soon.day);
    _time = TimeOfDay(hour: soon.hour, minute: 0);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime get _startsAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

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

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = _l10n.reminderNeedsTitle);
      return;
    }
    if (!_startsAt.isAfter(DateTime.now())) {
      setState(() => _error = _l10n.pickFutureTime);
      return;
    }
    Navigator.of(context).pop(
      NewReminderInput(
          title: title, startsAt: _startsAt, offsetMinutes: _offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final iso =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final dayOnly = CalendarDateMath.formatIsoForLanguage(iso, _l10n.lang);
    final timeLabel =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return Directionality(
      textDirection: _l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _l10n.addReminder,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _title,
                maxLength: 120,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: _l10n.reminderWhat,
                  filled: true,
                  fillColor: AppTheme.gate2InputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SediPalette.sageLine),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _pickerButton(_l10n.reminderDate, dayOnly,
                          Icons.event_outlined, _pickDate)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _pickerButton(_l10n.reminderTime, timeLabel,
                          Icons.schedule, _pickTime)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _l10n.reminderWhen,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in kSchedulePresets.where((m) => m != null))
                    ChoiceChip(
                      label: Text(schedulePresetLabel(_l10n, m)),
                      selected: _offset == m,
                      onSelected: (_) => setState(() => _offset = m!),
                      selectedColor: SediPalette.pistachio500,
                      backgroundColor: SediPalette.sageInput,
                      labelStyle: TextStyle(
                        color: _offset == m
                            ? SediPalette.charcoal950
                            : AppTheme.textPrimary,
                        fontWeight:
                            _offset == m ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: const BorderSide(color: SediPalette.sageLine),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: AppTheme.dangerRed, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.ctaFill,
                        foregroundColor: AppTheme.ctaText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerButton(
      String label, String value, IconData icon, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: SediPalette.pistachio900,
        side: const BorderSide(color: SediPalette.sageLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
