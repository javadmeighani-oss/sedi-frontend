import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';
import '../../../../data/dto/lifestyle/plan_alternative.dart';
import '../../../../data/dto/lifestyle/plan_settings_dto.dart';
import '../../../../services/lifestyle/lifestyle_weekly_plan_service.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/gate3_user_message_bus.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../lifestyle_l10n.dart';
import '../pages/lifestyle_page.dart';
import '../plan_coach_l10n.dart';
import 'lifestyle_plan_sheets.dart';
import 'plan_dish_art.dart';
import 'plan_setup_sheet.dart';

enum LifestyleWeeklyDomain { nutrition, exercise }

/// Shared weekly-plan presentation for Nutrition and Exercise - the "plan coach" (pilot V1 screen 6, R-034 / R-035).
/// Sedi speaks as a coach above a week strip and the day's timeline (vector dishes / symbols), the setup is three calm
/// steps that build the plan right here, and the weekly review comes from what the user marked.
/// Renders backend days in order; never fabricates plan content.
class LifestyleWeeklyPlanView extends StatefulWidget {
  final LifestyleWeeklyDomain domain;
  final LifestyleWeeklyPlanService? service;

  const LifestyleWeeklyPlanView({
    super.key,
    required this.domain,
    this.service,
  });

  @override
  State<LifestyleWeeklyPlanView> createState() =>
      _LifestyleWeeklyPlanViewState();
}

class _LifestyleWeeklyPlanViewState extends State<LifestyleWeeklyPlanView> {
  late final LifestyleWeeklyPlanService _svc =
      widget.service ?? LifestyleWeeklyPlanService();
  LifestyleWeeklyPlanDto? _plan;
  PlanSettingsDto _settings = const PlanSettingsDto();
  WeeklyReviewDto? _review;
  PlanProgressDto? _progress;
  bool _loading = true;
  bool _fetchFailed = false;
  String? _selectedDate;
  final Set<int> _reviewing = <int>{};

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);
  PlanCoachL10n get _coach =>
      PlanCoachL10n(SediLocaleController.instance.languageCode);

  bool get _isNutrition => widget.domain == LifestyleWeeklyDomain.nutrition;
  String get _domainKey => _isNutrition ? 'nutrition' : 'exercise';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _fetchFailed = false;
    });
    final res = await _svc.fetchWeeklyPlan();
    PlanSettingsDto? settings;
    WeeklyReviewDto? review;
    PlanProgressDto? progress;
    if (res.ok && res.data != null) {
      // Fail-open: the coach still works without them.
      final st = await _svc.fetchPlanSettings(_domainKey);
      if (st.ok) settings = st.data;
      final rv = await _svc.fetchWeeklyReview(_domainKey);
      if (rv.ok) review = rv.data;
      if (!_isNutrition) {
        final pr = await _svc.fetchPlanProgress(_domainKey);
        if (pr.ok) progress = pr.data;
      }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _plan = res.data;
        _fetchFailed = false;
        if (settings != null) _settings = settings;
        _review = review;
        _progress = progress;
        final dates = res.data!.days.map((d) => d.localDate).toList();
        if (_selectedDate == null || !dates.contains(_selectedDate)) {
          final today = res.data!.todayLocal;
          _selectedDate = (today != null && dates.contains(today))
              ? today
              : (dates.isEmpty ? null : dates.first);
        }
      } else {
        _plan = null;
        _fetchFailed = true;
      }
    });
  }

  String get _effectiveState {
    if (_fetchFailed || _plan == null) return 'unavailable';
    final s = _plan!.state;
    if (s == 'active' ||
        s == 'empty' ||
        s == 'review_due' ||
        s == 'unavailable') {
      return s;
    }
    return 'unavailable';
  }

  List<LifestyleWeeklyActionDto> _actionsFor(LifestyleWeeklyDayDto day) {
    switch (widget.domain) {
      case LifestyleWeeklyDomain.nutrition:
        return day.nutrition;
      case LifestyleWeeklyDomain.exercise:
        return day.exercise;
    }
  }

  LifestyleWeeklyDayDto? get _selectedDay {
    final days = _plan?.days ?? const <LifestyleWeeklyDayDto>[];
    for (final d in days) {
      if (d.localDate == _selectedDate) return d;
    }
    return days.isEmpty ? null : days.first;
  }

  bool get _ctaProminent =>
      _effectiveState == 'empty' || _effectiveState == 'review_due';

  bool _isReviewable(String localDate) {
    final today = _plan?.todayLocal;
    return today != null &&
        today.isNotEmpty &&
        localDate.isNotEmpty &&
        localDate.compareTo(today) <= 0;
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final coach = _coach;
    final title = _isNutrition ? l10n.nutritionPlan : l10n.exercisePlan;
    final starter =
        _isNutrition ? l10n.nutritionChatStarter : l10n.exerciseChatStarter;
    final top = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        extendBodyBehindAppBar: true,
        appBar: A3PageAppBar(
          // R-035: the small Sedi sphere sits on the START side of the title (right in fa/ar, left in en).
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SediHologramOrb(
                state: Gate3InteractionState.idle,
                diameter: 38,
                showRings: false,
                animate: false,
                keyedLogo: false,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.inkDeep,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
        bottomNavigationBar:
            _loading ? null : _bottomBar(l10n, coach, starter),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SediSceneBackdrop(),
            RefreshIndicator(
              color: AppTheme.gate2ButtonOlive,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, top, 16, 24),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.gate2ButtonOlive,
                        ),
                      ),
                    )
                  else ...[
                    if (!_isNutrition && _effectiveState == 'active' && _progress != null) ...[
                      // Pilot V1 screen 7: Sedi's motivation first, then today, then what is next.
                      _motivationPanel(l10n, coach),
                      const SizedBox(height: 14),
                      _todayWorkout(l10n, coach),
                      ..._nextDaysList(l10n, coach),
                    ] else ...[
                      _coachCard(l10n, coach, starter),
                      if (_effectiveState == 'active' ||
                          _effectiveState == 'review_due') ...[
                        const SizedBox(height: 14),
                        _weekStrip(l10n),
                        const SizedBox(height: 14),
                        _dayTimeline(l10n, coach),
                      ],
                    ],
                    if (_review != null && _review!.hasStory) ...[
                      const SizedBox(height: 14),
                      _reviewCard(l10n, coach),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass({required Widget child, EdgeInsets padding = const EdgeInsets.all(16), bool strong = false}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: SediGlass.card(BorderRadius.circular(26), strong: strong),
      child: child,
    );
  }

  // ------------------------------------------------------------------ coach card
  Widget _coachCard(LifestyleL10n l10n, PlanCoachL10n coach, String starter) {
    final state = _effectiveState;
    String headline;
    String? body;
    switch (state) {
      case 'empty':
        headline = _isNutrition ? l10n.noNutrition : l10n.noExercise;
        body = coach.coachEmpty(_isNutrition);
        break;
      case 'review_due':
        headline = l10n.reviewDueTitle;
        body = coach.coachReviewDue;
        break;
      case 'unavailable':
        headline = l10n.planUnavailable;
        body = l10n.planUnavailableBody;
        break;
      default: // active
        headline = _isNutrition ? l10n.nutritionActive : l10n.exerciseActive;
        final today = _todayDay();
        final actions = today == null ? const <LifestyleWeeklyActionDto>[] : _actionsFor(today);
        final total = actions.where((a) => a.localTime != null).length;
        final done = actions.where((a) => (a.status ?? '').toUpperCase() == 'COMPLETED').length;
        body = total == 0 ? coach.coachNothingToday : coach.coachToday(done, total);
        if (_plan?.cycleStart != null && _plan!.cycleStart!.isNotEmpty) {
          final end = _plan!.cycleEnd;
          headline = '$headline · ${l10n.cycleRangeLabel(CalendarDateMath.formatIsoForLanguage(_plan!.cycleStart!, l10n.lang), end != null && end.isNotEmpty ? CalendarDateMath.formatIsoForLanguage(end, l10n.lang) : '')}';
        }
    }
    if (state == 'unavailable') {
      return A3DestinationCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SediGlass.inkDeep)),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.justify, style: const TextStyle(height: 1.6, color: SediGlass.ink)),
            ],
          ],
        ),
      );
    }
    return _glass(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // R-035: the coach sphere is on the start side of her words.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SediHologramOrb(
                state: Gate3InteractionState.idle,
                diameter: 46,
                showRings: false,
                animate: false,
                keyedLogo: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: SediGlass.inkDeep,
                        height: 1.4,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        body,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          color: SediGlass.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_ctaProminent) ...[
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.ctaFill,
                foregroundColor: AppTheme.ctaText,
                textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
              onPressed: _openSetup,
              child: Text(coach.buildNow),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => openLifestyleChat(context, starterMessage: starter),
                child: Text(l10n.talkToCreate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ exercise: motivation panel
  Widget _motivationPanel(LifestyleL10n l10n, PlanCoachL10n coach) {
    final p = _progress!;
    final fraction = p.weekTotal <= 0 ? 0.0 : (p.weekDone / p.weekTotal).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCE98F), Color(0xFFB8CB55)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6E8C28).withOpacity(0.30), blurRadius: 32, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // R-035: the sphere is on the start side of Sedi's words.
          Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CircularProgressIndicator(
                        value: fraction,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        color: const Color(0xFF48551F),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${coach.n(p.weekDone)}/${coach.n(p.weekTotal)}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B2208)),
                        ),
                        Text(coach.weekTitle, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF2B3316))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  p.message,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, height: 1.6, color: Color(0xFF1B2208)),
                ),
              ),
            ],
          ),
          if (p.dayStates.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (final st in p.dayStates)
                  Expanded(
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: st == 'done' || st == 'today_done'
                            ? const Color(0xFF48551F)
                            : st == 'planned'
                                ? const Color(0xFF48551F).withOpacity(0.35)
                                : Colors.white.withOpacity(st == 'today' ? 0.95 : 0.5),
                        border: st == 'today' ? Border.all(color: const Color(0xFF48551F), width: 2) : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (p.streakWeeks >= 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 20, color: Color(0xFF2B3316)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    coach.streakLine(p.streakWeeks),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2B3316)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ exercise: today + next days
  List<LifestyleWeeklyActionDto> _timedActions(LifestyleWeeklyDayDto day) =>
      _actionsFor(day).where((a) => a.localTime != null && a.localTime!.isNotEmpty).toList();

  Widget _todayWorkout(LifestyleL10n l10n, PlanCoachL10n coach) {
    final day = _todayDay();
    final items = day == null ? const <LifestyleWeeklyActionDto>[] : _timedActions(day);
    if (items.isEmpty) {
      return _glass(child: Text(coach.restToday, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SediGlass.inkDeep)));
    }
    final open = items.where((a) => (a.status ?? '').toUpperCase() == 'ACTIVE' && a.reviewOutcome == null).toList();
    if (open.isEmpty) {
      return _glass(
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 30, color: AppTheme.gate2ButtonOlive),
            const SizedBox(width: 12),
            Expanded(child: Text(coach.todayWorkoutDone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SediGlass.inkDeep))),
          ],
        ),
      );
    }
    final a = open.first;
    final title = (a.title ?? a.activityTitle ?? '').trim();
    final meta = <String>[
      coach.n(a.localTime ?? ''),
      if (a.durationMinutes != null) l10n.durationMinutes(a.durationMinutes!),
    ].join(' · ');
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlanDishArt(kind: PlanDishArt.kindFor(activityType: a.activityType), size: 60),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.todayLabel} · $meta',
                      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SediGlass.ink.withOpacity(0.75)),
                    ),
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.45, color: SediGlass.inkDeep)),
                  ],
                ),
              ),
              if (a.id != null)
                IconButton(
                  tooltip: l10n.editItem,
                  icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.gate2ButtonOlive),
                  onPressed: () => _openItem(a, l10n, true),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppTheme.ctaFill,
                    foregroundColor: AppTheme.ctaText,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  onPressed: a.id == null || _reviewing.contains(a.id) ? null : () => _review(a, 'done'),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(coach.markDoneShort),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: SediGlass.ink,
                    side: BorderSide(color: Colors.white.withOpacity(0.95)),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: a.id == null ? null : () => _openItem(a, l10n, true),
                  child: Text(coach.notToday),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _nextDaysList(LifestyleL10n l10n, PlanCoachL10n coach) {
    final today = _plan?.todayLocal ?? '';
    final rows = <Widget>[];
    for (final d in _plan?.days ?? const <LifestyleWeeklyDayDto>[]) {
      if (d.localDate.compareTo(today) <= 0) continue;
      final items = _timedActions(d);
      if (items.isEmpty) continue;
      final a = items.first;
      final weekday = CalendarDateMath.weekdayFromIso(d.localDate);
      final title = (a.title ?? a.activityTitle ?? '').trim();
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  weekday == null ? '' : l10n.weekdayShort(weekday),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: SediGlass.ink),
                ),
              ),
              Expanded(
                child: Text(
                  a.durationMinutes == null ? title : '$title · ${l10n.durationMinutes(a.durationMinutes!)}',
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.4, color: SediGlass.inkDeep),
                ),
              ),
              Text(
                coach.n(a.localTime ?? ''),
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SediGlass.ink.withOpacity(0.75)),
              ),
            ],
          ),
        ),
      );
      if (rows.length >= 3) break;
    }
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 14),
      _glass(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: rows),
      ),
    ];
  }

  LifestyleWeeklyDayDto? _todayDay() {
    final today = _plan?.todayLocal;
    for (final d in _plan?.days ?? const <LifestyleWeeklyDayDto>[]) {
      if (d.localDate == today) return d;
    }
    return null;
  }

  // ------------------------------------------------------------------ week strip
  Widget _weekStrip(LifestyleL10n l10n) {
    final days = _plan?.days ?? const <LifestyleWeeklyDayDto>[];
    final today = _plan?.todayLocal;
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _dayChip(d, l10n, selected: d.localDate == _selectedDate, isToday: d.localDate == today),
            ),
          ),
      ],
    );
  }

  Widget _dayChip(LifestyleWeeklyDayDto d, LifestyleL10n l10n, {required bool selected, required bool isToday}) {
    final weekday = CalendarDateMath.weekdayFromIso(d.localDate);
    final actions = _actionsFor(d);
    final allDone = actions.isNotEmpty &&
        actions.every((a) => (a.status ?? '').toUpperCase() == 'COMPLETED');
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _selectedDate = d.localDate),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: selected
            ? SediGlass.pistachioSphere().copyWith(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(18),
              )
            : SediGlass.card(BorderRadius.circular(18)),
        child: Column(
          children: [
            Text(
              weekday == null ? '' : l10n.weekdayInitial(weekday),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: selected ? SediGlass.inkDeep : SediGlass.ink,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: allDone
                    ? AppTheme.gate2ButtonOlive
                    : isToday
                        ? SediGlass.ink.withOpacity(0.55)
                        : Colors.white.withOpacity(0.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ day timeline
  Widget _dayTimeline(LifestyleL10n l10n, PlanCoachL10n coach) {
    final day = _selectedDay;
    if (day == null) return const SizedBox.shrink();
    final actions = _actionsFor(day);
    final reviewable = _isReviewable(day.localDate);
    final isToday = day.localDate == _plan?.todayLocal;
    final weekday = CalendarDateMath.weekdayFromIso(day.localDate);
    final label = weekday == null ? '' : l10n.weekdayShort(weekday);
    final date = day.localDate.isEmpty
        ? ''
        : CalendarDateMath.formatIsoForLanguage(day.localDate, l10n.lang);
    return _glass(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? '$label · ${l10n.todayLabel}' : label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
          ),
          if (date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(date, style: TextStyle(fontSize: 13, color: SediGlass.ink.withOpacity(0.7))),
            ),
          const SizedBox(height: 6),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                l10n.noActionsThisDay,
                style: TextStyle(fontSize: 14.5, color: SediGlass.ink.withOpacity(0.75)),
              ),
            )
          else
            for (final a in actions) _mealRow(a, l10n, coach, reviewable),
        ],
      ),
    );
  }

  Widget _mealRow(LifestyleWeeklyActionDto a, LifestyleL10n l10n, PlanCoachL10n coach, bool reviewable) {
    final title = (a.title ?? a.activityTitle ?? '').trim();
    final status = (a.status ?? '').toUpperCase();
    final canTick = a.id != null && status == 'ACTIVE' && reviewable && a.reviewOutcome != 'skipped';
    final canEdit = a.id != null && status == 'ACTIVE';
    final kind = PlanDishArt.kindFor(mealSlot: a.mealSlot, activityType: a.activityType);
    final skipped = a.reviewOutcome == 'skipped';
    final slotLabel = _isNutrition
        ? ((a.mealSlot ?? '').isNotEmpty ? l10n.mealSlotLabel(a.mealSlot!) : '')
        : ((a.activityType ?? '').isNotEmpty ? l10n.activityTypeLabel(a.activityType!) : '');
    final meta = <String>[
      if (slotLabel.isNotEmpty) slotLabel,
      if (!_isNutrition && a.durationMinutes != null) l10n.durationMinutes(a.durationMinutes!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                a.localTime == null ? '' : coach.n(a.localTime!),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: SediGlass.ink),
              ),
            ),
          ),
          PlanDishArt(kind: kind, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meta.isNotEmpty)
                  Text(meta, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SediGlass.ink.withOpacity(0.7))),
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      color: SediGlass.inkDeep,
                      decoration: status == 'COMPLETED' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                if (a.detail != null && a.detail!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      a.detail!,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 13, height: 1.55, fontWeight: FontWeight.w600, color: SediGlass.ink),
                    ),
                  ),
                if (skipped)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${l10n.markSkipped}: ${l10n.skipReasonLabel(a.reviewReason ?? 'other')}',
                      style: TextStyle(fontSize: 12.5, color: SediGlass.ink.withOpacity(0.75)),
                    ),
                  ),
              ],
            ),
          ),
          if (status == 'COMPLETED')
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.check_circle_rounded, size: 28, color: AppTheme.gate2ButtonOlive),
            )
          else if (canTick)
            IconButton(
              tooltip: l10n.markDone,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.radio_button_unchecked_rounded, size: 30, color: AppTheme.gate2ButtonOlive),
              onPressed: _reviewing.contains(a.id) ? null : () => _review(a, 'done'),
            ),
          if (canEdit)
            IconButton(
              tooltip: l10n.editItem,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.gate2ButtonOlive),
              onPressed: () => _openItem(a, l10n, reviewable),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ weekly review
  Widget _reviewCard(LifestyleL10n l10n, PlanCoachL10n coach) {
    final r = _review!;
    final best = r.bestWeekday;
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: (r.percent.clamp(0, 100)) / 100,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.7),
                        color: AppTheme.gate2ButtonOlive,
                      ),
                    ),
                    Text(
                      '${coach.n(r.percent)}٪',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coach.reviewTitle,
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: SediGlass.inkDeep)),
                    const SizedBox(height: 2),
                    Text(coach.reviewCount(r.done, r.total),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SediGlass.ink)),
                    if (best != null)
                      Text(coach.reviewBest(l10n.weekdayShort(best)),
                          style: TextStyle(fontSize: 13, color: SediGlass.ink.withOpacity(0.8))),
                    if (r.delta != null)
                      Text(coach.reviewDelta(r.delta!),
                          style: TextStyle(fontSize: 13, color: SediGlass.ink.withOpacity(0.8))),
                  ],
                ),
              ),
            ],
          ),
          if (r.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.message,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 14.5, height: 1.7, fontWeight: FontWeight.w600, color: SediGlass.ink),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _sendToChat(coach.reviewChatMessage),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text(coach.reviewChat),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ bottom bar
  /// Set up or change the plan HERE (three steps, the same fields Sedi asks in chat), or talk to Sedi.
  Widget _bottomBar(LifestyleL10n l10n, PlanCoachL10n coach, String starter) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppTheme.ctaFill,
                foregroundColor: AppTheme.ctaText,
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              onPressed: _openSetup,
              child: Text(coach.setupButton),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: l10n.openChat,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => openLifestyleChat(context, starterMessage: starter),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.78), Colors.white.withOpacity(0.36)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.9)),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: SediGlass.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _currentMealTimes() {
    final out = <String, String>{};
    for (final d in _plan?.days ?? const <LifestyleWeeklyDayDto>[]) {
      for (final a in d.nutrition) {
        final slot = a.mealSlot;
        final t = a.localTime;
        if (slot != null && t != null && !out.containsKey(slot)) out[slot] = t;
      }
    }
    return out;
  }

  String? _currentExerciseTime() {
    for (final d in _plan?.days ?? const <LifestyleWeeklyDayDto>[]) {
      for (final a in d.exercise) {
        if (a.localTime != null) return a.localTime;
      }
    }
    return null;
  }

  Future<void> _openSetup() async {
    final coach = _coach;
    final built = await showPlanSetupSheet(
      context,
      l10n: coach,
      nutrition: _isNutrition,
      initialSettings: _settings,
      initialMealTimes: _currentMealTimes(),
      initialExerciseTime: _currentExerciseTime(),
      onSubmit: _submitSetup,
    );
    if (built == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(coach.buildOk)));
      await _load();
    }
  }

  Future<PlanSetupOutcome> _submitSetup(PlanSetupInput input) async {
    final res = await _svc.buildPlan(input);
    if (!res.ok) {
      if (res.error?.code == 'CONSENT_DENIED') return PlanSetupOutcome.consentNeeded;
      return PlanSetupOutcome.failed;
    }
    final data = res.data;
    if (data == null) return PlanSetupOutcome.failed;
    if (data.status == 'NEEDS_INFO') return PlanSetupOutcome.needsAllergy;
    if (data.status == 'CONSENT_REQUIRED') return PlanSetupOutcome.consentNeeded;
    return data.built ? PlanSetupOutcome.built : PlanSetupOutcome.failed;
  }

  void _sendToChat(String message) {
    Gate3UserMessageBus.instance.publish(message);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ------------------------------------------------------------------ item actions
  Future<void> _openItem(LifestyleWeeklyActionDto a, LifestyleL10n l10n, bool reviewable) async {
    final id = a.id;
    if (id == null) return;
    final title = (a.title ?? a.activityTitle ?? '').trim();
    final choice = await showPlanItemSheet(
      context,
      l10n: l10n,
      title: title,
      time: a.localTime,
      canSkip: reviewable,
      loadAlternatives: () async {
        final res = await _svc.fetchAlternatives(id);
        return res.ok ? (res.data ?? const <PlanAlternative>[]) : const <PlanAlternative>[];
      },
    );
    if (choice == null || !mounted) return;
    switch (choice.kind) {
      case 'chat':
        _sendToChat(l10n.alternativeMessage(title));
        return;
      case 'skip':
        await _review(a, 'skipped', reason: choice.value);
        return;
      case 'replace':
        await _edit(_svc.replaceAction(id, choice.value ?? ''), l10n);
        return;
      case 'move':
        await _edit(_svc.moveAction(id, choice.value ?? ''), l10n);
        return;
      case 'remove':
        await _edit(_svc.removeAction(id), l10n);
        return;
      case 'edit':
        final edited = await showPlanItemEditSheet(
          context,
          l10n: l10n,
          title: title,
          note: a.detail ?? '',
          durationMinutes: a.durationMinutes,
          isExercise: widget.domain == LifestyleWeeklyDomain.exercise,
        );
        if (edited == null || !mounted) return;
        await _edit(
          _svc.editAction(
            id,
            title: edited.title,
            note: edited.note,
            durationMinutes: edited.durationMinutes,
          ),
          l10n,
        );
        return;
    }
  }

  Future<void> _edit(Future<dynamic> call, LifestyleL10n l10n) async {
    final res = await call;
    if (!mounted) return;
    if (res.ok == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.planChangedSnack)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    }
  }

  Future<void> _review(
    LifestyleWeeklyActionDto a,
    String outcome, {
    String? reason,
  }) async {
    final id = a.id;
    if (id == null || _reviewing.contains(id)) return;
    setState(() => _reviewing.add(id));
    final res = await _svc.reviewAction(id, outcome, reason: reason);
    if (!mounted) return;
    setState(() => _reviewing.remove(id));
    if (res.ok) await _load();
  }
}
