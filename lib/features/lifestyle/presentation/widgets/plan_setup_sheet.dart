import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../data/dto/lifestyle/plan_settings_dto.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../plan_coach_l10n.dart';
import 'plan_dish_art.dart';

/// What happened when the sheet asked the backend to build the plan.
enum PlanSetupOutcome { built, needsAllergy, consentNeeded, failed }

const List<String> _mealSlots = <String>['breakfast', 'lunch', 'dinner', 'snack'];
const List<String> _nutritionGoals = <String>['sugar', 'weight', 'fitness', 'health'];
const List<String> _exerciseGoals = <String>['fitness', 'weight', 'strength', 'mobility'];
const List<String> _avoidKeys = <String>['fish', 'dairy', 'red_meat', 'eggs'];
const List<int?> _leads = <int?>[null, 0, 15, 30];

String _hhmm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay _parse(String raw, TimeOfDay fallback) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
  if (m == null) return fallback;
  return TimeOfDay(hour: int.parse(m.group(1)!) % 24, minute: int.parse(m.group(2)!) % 60);
}

/// Set up (or change) the plan IN the page, in three calm steps (Javad 2026-10-29): goal and foods to avoid, meals and
/// times, reminders and weekly review. The answers are the same fields Sedi asks in chat; [onSubmit] builds the plan
/// with the backend composer. Returns true when the plan was built.
Future<bool?> showPlanSetupSheet(
  BuildContext context, {
  required PlanCoachL10n l10n,
  required bool nutrition,
  required PlanSettingsDto initialSettings,
  Map<String, String> initialMealTimes = const {},
  String? initialExerciseTime,
  required Future<PlanSetupOutcome> Function(PlanSetupInput input) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlanSetupSheet(
      l10n: l10n,
      nutrition: nutrition,
      initialSettings: initialSettings,
      initialMealTimes: initialMealTimes,
      initialExerciseTime: initialExerciseTime,
      onSubmit: onSubmit,
    ),
  );
}

class _PlanSetupSheet extends StatefulWidget {
  final PlanCoachL10n l10n;
  final bool nutrition;
  final PlanSettingsDto initialSettings;
  final Map<String, String> initialMealTimes;
  final String? initialExerciseTime;
  final Future<PlanSetupOutcome> Function(PlanSetupInput input) onSubmit;

  const _PlanSetupSheet({
    required this.l10n,
    required this.nutrition,
    required this.initialSettings,
    required this.initialMealTimes,
    required this.initialExerciseTime,
    required this.onSubmit,
  });

  @override
  State<_PlanSetupSheet> createState() => _PlanSetupSheetState();
}

class _PlanSetupSheetState extends State<_PlanSetupSheet> {
  String? _mode; // null = still choosing; 'simple' | 'pro'
  int _step = 0;
  bool _busy = false;
  String? _notice;

  late String _goal = widget.nutrition ? _nutritionGoals.first : _exerciseGoals.first;
  final Set<String> _avoid = <String>{};
  bool _noAllergy = false;
  final TextEditingController _allergyCtl = TextEditingController();
  final TextEditingController _avoidCtl = TextEditingController();
  late final Map<String, String> _mealTimes = <String, String>{
    'breakfast': '08:00',
    'lunch': '13:00',
    'dinner': '20:00',
    'snack': '16:30',
    ...widget.initialMealTimes,
  };
  late String _exerciseTime = widget.initialExerciseTime ?? '17:00';
  late PlanSettingsDto _settings = widget.initialSettings;
  // The weekdays to train on: the simple exercise plan and the professional plan both start from Mon / Wed / Fri.
  late final Set<int> _trainDays = widget.initialSettings.days.length < 7
      ? widget.initialSettings.days.toSet()
      : <int>{1, 3, 5};

  bool get _pro => _mode == 'pro';
  bool get _nutritionFields => _pro || widget.nutrition;

  PlanCoachL10n get _l => widget.l10n;

  @override
  void dispose() {
    _allergyCtl.dispose();
    _avoidCtl.dispose();
    super.dispose();
  }

  Future<String?> _pickTime(String current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: _parse(current, const TimeOfDay(hour: 12, minute: 0)),
    );
    return t == null ? null : _hhmm(t);
  }

  bool get _allergyOk => !_nutritionFields || _noAllergy || _allergyCtl.text.trim().isNotEmpty;

  void _next() {
    if (_step == 0 && !_allergyOk) {
      setState(() => _notice = _l.allergyNeeded);
      return;
    }
    setState(() {
      _notice = null;
      _step += 1;
    });
  }

  String get _avoidText {
    final parts = <String>[
      for (final k in _avoidKeys)
        if (_avoid.contains(k)) _l.base.avoidLabel(k),
      if (_avoidCtl.text.trim().isNotEmpty) _avoidCtl.text.trim(),
    ];
    return parts.join('، ');
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    if (!_allergyOk) {
      setState(() {
        _busy = false;
        _step = 0;
        _notice = _l.allergyNeeded;
      });
      return;
    }
    final input = _pro
        ? PlanSetupInput(
            mode: 'pro',
            domain: 'nutrition',
            goal: _l.base.planGoalLabel(_goal),
            avoid: _avoidText,
            allergies: _allergyCtl.text,
            noAllergies: _noAllergy,
            mealTimes: Map<String, String>.from(_mealTimes),
            exerciseTime: _exerciseTime,
            exerciseDays: (_trainDays.toList()..sort()),
            settings: _settings,
          )
        : PlanSetupInput(
            domain: widget.nutrition ? 'nutrition' : 'exercise',
            allergies: widget.nutrition ? _allergyCtl.text : '',
            noAllergies: widget.nutrition && _noAllergy,
            mealTimes: widget.nutrition ? Map<String, String>.from(_mealTimes) : const {},
            exerciseTime: widget.nutrition ? null : _exerciseTime,
            settings: widget.nutrition ? _settings : _settings.copyWith(days: (_trainDays.toList()..sort())),
          );
    final outcome = await widget.onSubmit(input);
    if (!mounted) return;
    switch (outcome) {
      case PlanSetupOutcome.built:
        Navigator.of(context).pop(true);
        return;
      case PlanSetupOutcome.needsAllergy:
        setState(() {
          _busy = false;
          _step = 0;
          _notice = _l.allergyNeeded;
        });
        return;
      case PlanSetupOutcome.consentNeeded:
        setState(() {
          _busy = false;
          _notice = _l.consentNeeded;
        });
        return;
      case PlanSetupOutcome.failed:
        setState(() {
          _busy = false;
          _notice = _l.buildFailed;
        });
        return;
    }
  }

  // ------------------------------------------------------------------ pieces
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
        ),
      );

  Widget _chips(List<Widget> chips) => Wrap(spacing: 8, runSpacing: 8, children: chips);

  Widget _timeRow({required String kind, required String label, required String time, required ValueChanged<String> onPicked}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: SediGlass.card(BorderRadius.circular(20)),
        child: Row(
          children: [
            PlanDishArt(kind: kind, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await _pickTime(time);
                if (picked != null && mounted) setState(() => onPicked(picked));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: SediGlass.pill(),
                child: Text(
                  _l.n(time),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SediGlass.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChips({required Set<int> selected, required ValueChanged<int> onTap, bool single = false}) {
    return _chips([
      for (final d in _l.base.weekOrder)
        A3DestinationChip(
          label: _l.base.weekdayShort(d),
          selected: selected.contains(d),
          onTap: () => setState(() => onTap(d)),
        ),
    ]);
  }

  List<Widget> _stepGoal() {
    final goals = _nutritionFields ? _nutritionGoals : _exerciseGoals;
    return [
      _label(_l.base.goalQuestion),
      _chips([
        for (final g in goals)
          A3DestinationChip(
            label: _l.base.planGoalLabel(g),
            selected: _goal == g,
            onTap: () => setState(() => _goal = g),
          ),
      ]),
      if (_nutritionFields) ...[
        _label(_l.allergyQuestion),
        _chips([
          A3DestinationChip(
            label: _l.noAllergy,
            selected: _noAllergy,
            onTap: () => setState(() {
              _noAllergy = !_noAllergy;
              if (_noAllergy) _allergyCtl.clear();
            }),
          ),
        ]),
        if (!_noAllergy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _allergyCtl,
              maxLength: 120,
              onChanged: (_) => setState(() => _notice = null),
              decoration: InputDecoration(hintText: _l.allergyHint, counterText: ''),
            ),
          ),
        _label(_l.base.avoidQuestion),
        _chips([
          for (final a in _avoidKeys)
            A3DestinationChip(
              label: _l.base.avoidLabel(a),
              selected: _avoid.contains(a),
              onTap: () => setState(() {
                if (!_avoid.add(a)) _avoid.remove(a);
              }),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: _avoidCtl,
            maxLength: 120,
            decoration: InputDecoration(hintText: _l.avoidMore, counterText: ''),
          ),
        ),
      ],
    ];
  }

  Widget _exerciseTimeRow() => _timeRow(
        kind: 'exercise',
        label: _l.exerciseTimeQuestion,
        time: _exerciseTime,
        onPicked: (v) => _exerciseTime = v,
      );

  Widget _trainDayChips() => _dayChips(
        selected: _trainDays,
        onTap: (d) {
          if (!_trainDays.add(d) && _trainDays.length > 1) _trainDays.remove(d);
        },
      );

  Widget _mealRows() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final slot in _mealSlots)
            _timeRow(
              kind: slot,
              label: _l.base.mealSlotLabel(slot),
              time: _mealTimes[slot] ?? '12:00',
              onPicked: (v) => _mealTimes[slot] = v,
            ),
        ],
      );

  /// Simple plan: just the days and the time (plus the allergy answer for meals), one calm page.
  List<Widget> _stepSimple() {
    if (widget.nutrition) {
      return [
        _label(_l.allergyQuestion),
        _chips([
          A3DestinationChip(
            label: _l.noAllergy,
            selected: _noAllergy,
            onTap: () => setState(() {
              _noAllergy = !_noAllergy;
              if (_noAllergy) _allergyCtl.clear();
            }),
          ),
        ]),
        if (!_noAllergy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _allergyCtl,
              maxLength: 120,
              onChanged: (_) => setState(() => _notice = null),
              decoration: InputDecoration(hintText: _l.allergyHint, counterText: ''),
            ),
          ),
        const SizedBox(height: 12),
        _mealRows(),
      ];
    }
    return [
      _label(_l.workoutDaysQuestion),
      _trainDayChips(),
      const SizedBox(height: 14),
      _exerciseTimeRow(),
    ];
  }

  List<Widget> _stepTimes() {
    return [
      const SizedBox(height: 10),
      _mealRows(),
      _exerciseTimeRow(),
      _label(_l.workoutDaysQuestion),
      _trainDayChips(),
    ];
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String hint,
    required VoidCallback onTap,
    bool strong = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: SediGlass.card(BorderRadius.circular(24), strong: strong),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.72),
                border: Border.all(color: Colors.white.withOpacity(0.9)),
              ),
              child: Icon(icon, size: 22, color: SediGlass.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: SediGlass.inkDeep)),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(fontSize: 13, height: 1.55, fontWeight: FontWeight.w600, color: SediGlass.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _stepMode() => [
        const SizedBox(height: 14),
        _modeCard(
          icon: Icons.check_rounded,
          title: _l.modeSimple,
          hint: _l.modeSimpleHint,
          strong: true,
          onTap: () => setState(() {
            _mode = 'simple';
            _step = 0;
          }),
        ),
        const SizedBox(height: 10),
        _modeCard(
          icon: Icons.insights_rounded,
          title: _l.modePro,
          hint: _l.modeProHint,
          onTap: () => setState(() {
            _mode = 'pro';
            _step = 0;
          }),
        ),
      ];

  List<Widget> _stepReminders() {
    final days = _settings.days.toSet();
    return [
      _label(_l.leadQuestion),
      _chips([
        for (final lead in _leads)
          A3DestinationChip(
            label: _l.leadLabel(lead),
            selected: _settings.lead == lead,
            onTap: () => setState(() {
              _settings = lead == null ? _settings.copyWith(clearLead: true) : _settings.copyWith(lead: lead);
            }),
          ),
      ]),
      if (_settings.lead != null) ...[
        _label(_l.remindDaysQuestion),
        _dayChips(
          selected: days,
          onTap: (d) {
            final next = Set<int>.from(days);
            if (!next.add(d)) {
              if (next.length > 1) next.remove(d);
            }
            _settings = _settings.copyWith(days: (next.toList()..sort()));
          },
        ),
      ],
      _label(_l.reviewDayQuestion),
      _dayChips(
        selected: <int>{_settings.reviewWeekday},
        single: true,
        onTap: (d) => _settings = _settings.copyWith(reviewWeekday: d),
      ),
      _label(_l.reviewTimeQuestion),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final picked = await _pickTime(_settings.reviewTime);
            if (picked != null && mounted) setState(() => _settings = _settings.copyWith(reviewTime: picked));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: SediGlass.pill(strong: true),
            child: Text(
              _l.n(_settings.reviewTime),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SediGlass.ink),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: i == _step ? 22 : 8,
            height: 8,
            margin: const EdgeInsetsDirectional.only(end: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: i <= _step ? AppTheme.gate2ButtonOlive : Colors.white.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    final body = _mode == null
        ? _stepMode()
        : !_pro
            ? _stepSimple()
            : _step == 0
                ? _stepGoal()
                : _step == 1
                    ? _stepTimes()
                    : _stepReminders();
    final last = _mode != null && (!_pro || _step == 2);
    return Directionality(
      textDirection: l.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SediGlass.blur(
        radius: const BorderRadius.vertical(top: Radius.circular(30)),
        sigma: 18,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFF1F5DA).withOpacity(0.96), const Color(0xFFDDE5B6).withOpacity(0.97)],
            ),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.9))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 12 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: SediGlass.ink.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // R-035: the sphere is on the start side of the title.
                  Row(
                    children: [
                      const SediHologramOrb(
                        state: Gate3InteractionState.idle,
                        diameter: 38,
                        showRings: false,
                        animate: false,
                        keyedLogo: false,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mode == null
                                  ? l.modeTitle
                                  : !_pro
                                      ? (widget.nutrition ? l.base.nutritionPlan : l.base.exercisePlan)
                                      : l.stepTitle(_step, true),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: SediGlass.inkDeep,
                              ),
                            ),
                            if (_pro) ...[
                              const SizedBox(height: 2),
                              Text(
                                l.stepOf(_step),
                                style: TextStyle(fontSize: 12.5, color: SediGlass.ink.withOpacity(0.7)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_pro) _dots(),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: body,
                      ),
                    ),
                  ),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _notice!,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: AppTheme.dangerRed),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (_mode != null)
                  Row(
                    children: [
                      ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              foregroundColor: SediGlass.ink,
                              side: BorderSide(color: Colors.white.withOpacity(0.95)),
                            ),
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      if (_pro && _step > 0) {
                                        _step -= 1;
                                      } else {
                                        _mode = null;
                                        _notice = null;
                                      }
                                    }),
                            child: Text(l.back),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: AppTheme.ctaFill,
                            foregroundColor: AppTheme.ctaText,
                            textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                          ),
                          onPressed: _busy ? null : (last ? _submit : _next),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.ctaText),
                                )
                              : Text(last ? l.buildAndSave : l.next),
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
    );
  }
}
