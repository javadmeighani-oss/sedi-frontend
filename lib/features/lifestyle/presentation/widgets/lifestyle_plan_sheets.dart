import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/lifestyle/plan_alternative.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../lifestyle_l10n.dart';

/// What the user chose for one plan item (P8). [kind]: 'alternative' | 'move' | 'skip' | 'remove'.
/// [value]: the new HH:MM for 'move', the bounded skip reason for 'skip'.
class PlanItemChoice {
  final String kind;
  final String? value;

  const PlanItemChoice(this.kind, [this.value]);
}

const List<String> _skipReasons = <String>['no_time', 'dont_like', 'not_feeling_well', 'forgot'];

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parseTime(String? raw) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw ?? '');
  if (m == null) return const TimeOfDay(hour: 12, minute: 0);
  return TimeOfDay(hour: int.parse(m.group(1)!) % 24, minute: int.parse(m.group(2)!) % 60);
}

Widget _sheetShell(LifestyleL10n l10n, BuildContext ctx, List<Widget> children) {
  return Directionality(
    textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
    child: SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

Widget _optionRow(IconData icon, String label, VoidCallback onTap, {Color? color}) {
  final c = color ?? AppTheme.textPrimary;
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: A3DestinationCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? AppTheme.gate2ButtonOlive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: c)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The user's own correction of an item's text / duration.
class PlanItemEdit {
  final String title;
  final String note;
  final int? durationMinutes;

  const PlanItemEdit({required this.title, required this.note, this.durationMinutes});
}

/// Change one plan item IN THE PAGE: pick one of the offered alternatives, correct its text, move its time, skip it with
/// a reason, remove it from the week - or ask Sedi in chat. Choice kinds: 'replace' (value = item_id) | 'edit' |
/// 'move' (HH:MM) | 'skip' (reason) | 'remove' | 'chat'.
Future<PlanItemChoice?> showPlanItemSheet(
  BuildContext context, {
  required LifestyleL10n l10n,
  required String title,
  String? time,
  required bool canSkip,
  required Future<List<PlanAlternative>> Function() loadAlternatives,
}) {
  final alternatives = loadAlternatives();
  return showModalBottomSheet<PlanItemChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: A3DestinationSurface.canvas,
    builder: (ctx) {
      var askingReason = false;
      String? picked;
      return StatefulBuilder(
        builder: (ctx, setSheet) => _sheetShell(l10n, ctx, [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, height: 1.5, color: AppTheme.textPrimary)),
          if (time != null && time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(time, style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          const SizedBox(height: 14),
          Text(l10n.alternativesTitle,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          FutureBuilder<List<PlanAlternative>>(
            future: alternatives,
            builder: (c, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive)),
                );
              }
              final items = snap.data ?? const <PlanAlternative>[];
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(l10n.alternativesEmpty,
                      style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textSecondary)),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: A3DestinationCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderColor: picked == a.itemId ? AppTheme.gate2ButtonOlive : null,
                        onTap: () => setSheet(() => picked = a.itemId),
                        child: Row(
                          children: [
                            Icon(
                              picked == a.itemId
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: AppTheme.gate2ButtonOlive,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(a.title,
                                  style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                      color: AppTheme.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppTheme.ctaFill,
                      foregroundColor: AppTheme.textPrimary,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    onPressed: picked == null ? null : () => Navigator.pop(ctx, PlanItemChoice('replace', picked)),
                    child: Text(l10n.applyChange),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            },
          ),
          _optionRow(Icons.edit_outlined, l10n.itemEdit, () => Navigator.pop(ctx, const PlanItemChoice('edit'))),
          _optionRow(Icons.schedule_rounded, l10n.itemMoveTime, () async {
            final t = await showTimePicker(context: ctx, initialTime: _parseTime(time));
            if (t != null && ctx.mounted) Navigator.pop(ctx, PlanItemChoice('move', _hhmm(t)));
          }),
          if (canSkip)
            _optionRow(Icons.remove_circle_outline_rounded, l10n.itemSkipToday,
                () => setSheet(() => askingReason = !askingReason)),
          if (canSkip && askingReason) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(l10n.whySkippedHint,
                  style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _skipReasons)
                  ActionChip(
                    label: Text(l10n.skipReasonLabel(r)),
                    onPressed: () => Navigator.pop(ctx, PlanItemChoice('skip', r)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _optionRow(Icons.chat_bubble_outline_rounded, l10n.itemAskAlternative,
              () => Navigator.pop(ctx, const PlanItemChoice('chat'))),
          _optionRow(Icons.delete_outline_rounded, l10n.itemRemove, () async {
            final ok = await showDialog<bool>(
              context: ctx,
              builder: (d) => Directionality(
                textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: AlertDialog(
                  content: Text(l10n.itemRemoveQuestion),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(d, true), child: Text(l10n.deleteItem)),
                  ],
                ),
              ),
            );
            if (ok == true && ctx.mounted) Navigator.pop(ctx, const PlanItemChoice('remove'));
          }, color: AppTheme.dangerRed),
        ]),
      );
    },
  );
}

/// Correct an item's own words: title, note and (exercise) duration.
Future<PlanItemEdit?> showPlanItemEditSheet(
  BuildContext context, {
  required LifestyleL10n l10n,
  required String title,
  String note = '',
  int? durationMinutes,
  required bool isExercise,
}) {
  final titleCtl = TextEditingController(text: title);
  final noteCtl = TextEditingController(text: note);
  final durationCtl = TextEditingController(text: durationMinutes?.toString() ?? '');
  return showModalBottomSheet<PlanItemEdit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: A3DestinationSurface.canvas,
    builder: (ctx) => _sheetShell(l10n, ctx, [
      Text(l10n.itemEdit,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 12),
      TextField(
        controller: titleCtl,
        maxLength: 120,
        decoration: InputDecoration(labelText: l10n.editTitleHint),
      ),
      TextField(
        controller: noteCtl,
        maxLength: 240,
        minLines: 1,
        maxLines: 4,
        decoration: InputDecoration(labelText: l10n.editNoteHint),
      ),
      if (isExercise)
        TextField(
          controller: durationCtl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.editDurationHint),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.ctaFill,
                foregroundColor: AppTheme.textPrimary,
              ),
              onPressed: () {
                final t = titleCtl.text.trim();
                if (t.isEmpty) return;
                final minutes = int.tryParse(durationCtl.text.trim());
                Navigator.pop(
                  ctx,
                  PlanItemEdit(
                    title: t,
                    note: noteCtl.text.trim(),
                    durationMinutes: (minutes != null && minutes >= 5 && minutes <= 180) ? minutes : null,
                  ),
                );
              },
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    ]),
  );
}

/// Set up (or change) the plan from the page: what Sedi already knows, then only what is missing. Returns the user
/// message to send to the canonical chat, or null when cancelled.
Future<String?> showPlanSetupSheet(
  BuildContext context, {
  required LifestyleL10n l10n,
  required bool nutrition,
  List<String> knownFacts = const [],
}) {
  final goals = nutrition
      ? const ['sugar', 'weight', 'fitness', 'health']
      : const ['fitness', 'weight', 'strength', 'mobility'];
  final counts = nutrition ? const [3, 4, 5] : const [2, 3, 4, 5];
  final avoidOptions = const ['fish', 'dairy', 'red_meat', 'eggs'];
  final extra = TextEditingController();
  var goal = goals.first;
  var count = nutrition ? 4 : 3;
  final avoid = <String>{};

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: A3DestinationSurface.canvas,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => _sheetShell(l10n, ctx, [
        Text(l10n.planSetupTitle(nutrition),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(l10n.planSetupIntro,
            style: const TextStyle(fontSize: 14, height: 1.7, color: AppTheme.textSecondary)),
        if (knownFacts.isNotEmpty) ...[
          const SizedBox(height: 14),
          A3DestinationCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.knownFactsTitle,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final f in knownFacts) A3DestinationChip(label: f, selected: false, onTap: () {})],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _question(l10n.goalQuestion),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in goals)
              A3DestinationChip(
                label: l10n.planGoalLabel(g),
                selected: goal == g,
                onTap: () => setSheet(() => goal = g),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _question(nutrition ? l10n.mealsQuestion : l10n.daysQuestion),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in counts)
              A3DestinationChip(
                label: nutrition ? l10n.mealsOption(c) : l10n.daysOption(c),
                selected: count == c,
                onTap: () => setSheet(() => count = c),
              ),
          ],
        ),
        if (nutrition) ...[
          const SizedBox(height: 16),
          _question(l10n.avoidQuestion),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in avoidOptions)
                A3DestinationChip(
                  label: l10n.avoidLabel(a),
                  selected: avoid.contains(a),
                  onTap: () => setSheet(() {
                    if (!avoid.add(a)) avoid.remove(a);
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: extra,
          maxLength: 120,
          decoration: InputDecoration(hintText: l10n.otherThingHint),
        ),
        const SizedBox(height: 4),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppTheme.ctaFill,
            foregroundColor: AppTheme.textPrimary,
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          onPressed: () => Navigator.pop(
            ctx,
            l10n.composeSetupMessage(
              nutrition: nutrition,
              goalKey: goal,
              count: count,
              avoid: avoid.toList(),
              extra: extra.text,
            ),
          ),
          child: Text(l10n.buildPlanButton),
        ),
      ]),
    ),
  );
}

Widget _question(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    );
