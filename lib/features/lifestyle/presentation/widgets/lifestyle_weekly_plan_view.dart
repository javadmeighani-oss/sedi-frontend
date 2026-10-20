import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';
import '../../../../services/lifestyle/lifestyle_weekly_plan_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import '../pages/lifestyle_page.dart';

enum LifestyleWeeklyDomain { nutrition, exercise }

/// Shared weekly-plan presentation for Nutrition and Exercise.
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
  bool _loading = true;
  bool _fetchFailed = false;
  final Set<int> _reviewing = <int>{};

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);

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
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _plan = res.data;
        _fetchFailed = false;
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

  bool get _ctaProminent =>
      _effectiveState == 'empty' || _effectiveState == 'review_due';

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final isNutrition = widget.domain == LifestyleWeeklyDomain.nutrition;
    final title = isNutrition ? l10n.nutritionPlan : l10n.exercisePlan;
    final starter = isNutrition
        ? l10n.nutritionChatStarter
        : l10n.exerciseChatStarter;

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(title),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        body: RefreshIndicator(
          color: AppTheme.gate2ButtonOlive,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.gate2ButtonOlive,
                    ),
                  ),
                )
              else ...[
                _buildStateHeader(l10n),
                if (_plan?.adherence != null && _plan!.adherence!.total > 0) ...[
                  const SizedBox(height: 12),
                  _adherenceCard(l10n),
                ],
                const SizedBox(height: 16),
                _talkToSediCard(l10n, starter),
                if (_effectiveState == 'active' ||
                    _effectiveState == 'review_due') ...[
                  const SizedBox(height: 20),
                  ..._buildDays(l10n),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _talkToSediCard(LifestyleL10n l10n, String starter) {
    return A3DestinationCard(
      child: SizedBox(
        width: double.infinity,
        height: _ctaProminent ? 52 : 48,
        child: ElevatedButton(
          onPressed: () =>
              openLifestyleChat(context, starterMessage: starter),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gate2ButtonOlive,
            foregroundColor: AppTheme.backgroundWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: Text(
            l10n.openChat,
            style: TextStyle(
              fontSize: _ctaProminent ? 16 : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateHeader(LifestyleL10n l10n) {
    final isNutrition = widget.domain == LifestyleWeeklyDomain.nutrition;
    late final String title;
    late final String? body;
    switch (_effectiveState) {
      case 'empty':
        title = isNutrition ? l10n.noNutrition : l10n.noExercise;
        body = l10n.talkToCreate;
        break;
      case 'review_due':
        title = l10n.reviewDueTitle;
        body = l10n.reviewDueBody;
        break;
      case 'unavailable':
        title = l10n.planUnavailable;
        body = l10n.planUnavailableBody;
        break;
      default: // active
        title = isNutrition ? l10n.nutritionActive : l10n.exerciseActive;
        if (_plan?.cycleStart != null && _plan!.cycleStart!.isNotEmpty) {
          body = l10n.cycleRangeLabel(
            CalendarDateMath.formatIsoForLanguage(
              _plan!.cycleStart!,
              l10n.lang,
            ),
            _plan!.cycleEnd != null && _plan!.cycleEnd!.isNotEmpty
                ? CalendarDateMath.formatIsoForLanguage(
                    _plan!.cycleEnd!,
                    l10n.lang,
                  )
                : '',
          );
        } else {
          body = null;
        }
    }

    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDays(LifestyleL10n l10n) {
    final days = _plan?.days ?? const <LifestyleWeeklyDayDto>[];
    // Backend provides exact 7-day order — do not reorder or invent days.
    return days.map((day) {
      final weekday = CalendarDateMath.weekdayFromIso(day.localDate);
      final weekdayLabel =
          weekday == null ? '' : l10n.weekdayShort(weekday);
      final dateLabel = day.localDate.isEmpty
          ? ''
          : CalendarDateMath.formatIsoForLanguage(day.localDate, l10n.lang);
      final actions = _actionsFor(day);
      final today = _plan?.todayLocal;
      final reviewable = today != null &&
          today.isNotEmpty &&
          day.localDate.isNotEmpty &&
          day.localDate.compareTo(today) <= 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: A3DestinationCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weekdayLabel.isNotEmpty)
                Text(
                  weekdayLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                  ),
                ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (actions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l10n.noActionsThisDay,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              else
                ...actions.map((a) => _actionBlock(a, l10n, reviewable)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _actionBlock(
    LifestyleWeeklyActionDto a,
    LifestyleL10n l10n,
    bool reviewable,
  ) {
    final title = a.title ?? a.activityTitle;
    final rows = <Widget>[];
    if (widget.domain == LifestyleWeeklyDomain.nutrition) {
      if (a.mealSlot != null && a.mealSlot!.isNotEmpty) {
        rows.add(_metaLine(l10n.mealSlotLabel(a.mealSlot!)));
      }
      if (title != null && title.isNotEmpty) {
        rows.add(_titleLine(title));
      }
      if (a.localTime != null && a.localTime!.isNotEmpty) {
        rows.add(_metaLine(a.localTime!));
      }
      if (a.status != null && a.status!.isNotEmpty) {
        rows.add(_metaLine(l10n.scheduleStatusLabel(a.status!)));
      }
    } else {
      if (title != null && title.isNotEmpty) {
        rows.add(_titleLine(title));
      }
      if (a.activityType != null && a.activityType!.isNotEmpty) {
        rows.add(_metaLine(l10n.activityTypeLabel(a.activityType!)));
      }
      if (a.durationMinutes != null) {
        rows.add(_metaLine(l10n.durationMinutes(a.durationMinutes!)));
      }
      if (a.localTime != null && a.localTime!.isNotEmpty) {
        rows.add(_metaLine(a.localTime!));
      }
      if (a.status != null && a.status!.isNotEmpty) {
        rows.add(_metaLine(l10n.scheduleStatusLabel(a.status!)));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    if (a.detail != null && a.detail!.isNotEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            a.detail!,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      );
    }
    final reviewRow = _reviewRow(a, l10n, reviewable);
    if (reviewRow != null) rows.add(reviewRow);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _adherenceCard(LifestyleL10n l10n) {
    final ad = _plan!.adherence!;
    return A3DestinationCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.adherenceTitle(ad.done, ad.total),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '${ad.percent}%',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.gate2ButtonOlive,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _reviewRow(
    LifestyleWeeklyActionDto a,
    LifestyleL10n l10n,
    bool reviewable,
  ) {
    if (a.id == null) return null;
    final status = (a.status ?? '').toUpperCase();
    if (a.reviewOutcome == 'skipped') {
      return _metaLine(
        '${l10n.markSkipped}: ${l10n.skipReasonLabel(a.reviewReason ?? 'other')}',
      );
    }
    if (status != 'ACTIVE' || !reviewable) return null;
    final busy = _reviewing.contains(a.id);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        children: [
          FilledButton(
            onPressed: busy ? null : () => _review(a, 'done'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gate2ButtonOlive,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.markDone),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => _askReasonAndSkip(a, l10n),
            child: Text(l10n.markSkipped),
          ),
        ],
      ),
    );
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

  Future<void> _askReasonAndSkip(
    LifestyleWeeklyActionDto a,
    LifestyleL10n l10n,
  ) async {
    const reasons = <String>[
      'no_time',
      'too_hard',
      'not_feeling_well',
      'dont_like',
      'forgot',
      'other',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      builder: (ctx) => Directionality(
        textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whySkippedTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.whySkippedHint,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons
                      .map(
                        (r) => ActionChip(
                          label: Text(l10n.skipReasonLabel(r)),
                          onPressed: () => Navigator.of(ctx).pop(r),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _review(a, 'skipped', reason: picked);
  }

  Widget _titleLine(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      );

  Widget _metaLine(String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      );
}
