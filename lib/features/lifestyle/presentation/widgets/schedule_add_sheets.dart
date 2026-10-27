import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../lifestyle_l10n.dart';

/// What the user is adding to My Schedule (R-031): each type has its own form, so Sedi can notify on time and ask
/// "did you take it?" / "did you go?".
enum ScheduleAddType { medication, appointment, meeting, free }

/// First step of "add": a 2x2 type picker.
Future<ScheduleAddType?> showAddTypeSheet(
  BuildContext context,
  LifestyleL10n l10n,
) {
  Widget tile(BuildContext ctx, ScheduleAddType type, IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(ctx).pop(type),
      child: Container(
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: SediPalette.sageInput,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: SediPalette.sageLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: SediPalette.pistachio900),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<ScheduleAddType>(
    context: context,
    backgroundColor: SediPalette.sageSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addWhatTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                childAspectRatio: 2.1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  tile(ctx, ScheduleAddType.medication, Icons.medication_outlined, l10n.typeMedication),
                  tile(ctx, ScheduleAddType.appointment, Icons.local_hospital_outlined, l10n.typeAppointment),
                  tile(ctx, ScheduleAddType.meeting, Icons.groups_outlined, l10n.typeMeeting),
                  tile(ctx, ScheduleAddType.free, Icons.notifications_active_outlined, l10n.typeFree),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Result of the medication sheet.
class NewMedicationInput {
  final String name;

  /// 'HH:MM' times, sorted.
  final List<String> times;
  const NewMedicationInput({required this.name, required this.times});
}

/// Bottom sheet: medication name + the times of day.
class ScheduleAddMedicationSheet extends StatefulWidget {
  final LifestyleL10n l10n;
  const ScheduleAddMedicationSheet({super.key, required this.l10n});

  @override
  State<ScheduleAddMedicationSheet> createState() =>
      _ScheduleAddMedicationSheetState();
}

class _ScheduleAddMedicationSheetState
    extends State<ScheduleAddMedicationSheet> {
  final _name = TextEditingController();
  final List<String> _times = <String>['08:00'];
  String? _error;

  LifestyleL10n get _l10n => widget.l10n;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    final v = _fmt(picked);
    if (_times.contains(v)) return;
    setState(() {
      _times
        ..add(v)
        ..sort();
      _error = null;
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = _l10n.medNeedName);
      return;
    }
    if (_times.isEmpty) {
      setState(() => _error = _l10n.medNeedTime);
      return;
    }
    Navigator.of(context).pop(NewMedicationInput(name: name, times: List.of(_times)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.typeMedication,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.medName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: SediPalette.sageInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: SediPalette.sageLine),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: SediPalette.sageLine),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.medTimes,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _times)
                      InputChip(
                        label: Text(
                          l10n.timeText(DateTime(2000, 1, 1, int.parse(t.substring(0, 2)), int.parse(t.substring(3, 5)))),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: SediPalette.sageFill,
                        onDeleted: () => setState(() => _times.remove(t)),
                      ),
                    ActionChip(
                      label: Text(
                        l10n.addTime,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _addTime,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SediPalette.sageInput,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SediPalette.sageLine),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 22, color: SediPalette.pistachio900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.medHint,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppTheme.dangerRed)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.ctaFill,
                          foregroundColor: AppTheme.ctaText,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: Text(
                          l10n.medSave,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
