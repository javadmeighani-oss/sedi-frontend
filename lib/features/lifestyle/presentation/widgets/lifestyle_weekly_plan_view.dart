import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';
import '../../../../services/lifestyle/lifestyle_weekly_plan_service.dart';
import '../../../gate3_interactive/presentation/gate3_user_message_bus.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import '../pages/lifestyle_page.dart';
import 'lifestyle_plan_sheets.dart';

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
        bottomNavigationBar: _loading ? null : _bottomBar(l10n, starter, isNutrition),
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
                if (_ctaProminent) ...[
                  const SizedBox(height: 16),
                  _talkToSediCard(l10n, starter),
                ],
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

  /// Set up or change the plan here (the sheet's answers go to the canonical chat as the user's own message), or just
  /// talk to Sedi. Always visible so the plan can be changed without hunting for it.
  Widget _bottomBar(LifestyleL10n l10n, String starter, bool isNutrition) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppTheme.ctaFill,
                  foregroundColor: AppTheme.ctaText,
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _openSetup(l10n, isNutrition),
                child: Text(l10n.planSetupButton),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: l10n.openChat,
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => openLifestyleChat(context, starterMessage: starter),
            ),
          ],
        ),
      ),
    );
  }

  /// Facts Sedi already remembers about the user (read-only chips, fail-open: no chips when memory is off).
  Future<List<String>> _knownFacts() async {
    try {
      final res = await ApiClient().getRaw('/memory/overview');
      final body = res.ok ? res.data : null;
      final facts = body == null ? null : body['facts'];
      if (facts is! List) return const [];
      return [
        for (final f in facts)
          if (f is Map && '${f['value'] ?? ''}'.trim().isNotEmpty) '${f['value']}'.trim(),
      ].take(4).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _openSetup(LifestyleL10n l10n, bool isNutrition) async {
    final facts = await _knownFacts();
    if (!mounted) return;
    final message = await showPlanSetupSheet(
      context,
      l10n: l10n,
      nutrition: isNutrition,
      knownFacts: facts,
    );
    if (message == null || !mounted) return;
    _sendToChat(message);
  }

  void _sendToChat(String message) {
    Gate3UserMessageBus.instance.publish(message);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

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
    );
    if (choice == null || !mounted) return;
    switch (choice.kind) {
      case 'alternative':
        _sendToChat(l10n.alternativeMessage(title));
        return;
      case 'skip':
        await _review(a, 'skipped', reason: choice.value);
        return;
      case 'move':
        await _edit(_svc.moveAction(id, choice.value ?? ''), l10n);
        return;
      case 'remove':
        await _edit(_svc.removeAction(id), l10n);
        return;
    }
  }

  Future<void> _edit(Future<dynamic> call, LifestyleL10n l10n) async {
    final res = await call;
    if (!mounted) return;
    if (res.ok == true) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    }
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
            backgroundColor: AppTheme.ctaFill,
            foregroundColor: AppTheme.ctaText,
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
    // Backend provides the 7 days in order and never invents any; only the display puts today's card first.
    final todayKey = _plan?.todayLocal;
    final ordered = [
      ...days.where((d) => todayKey != null && d.localDate == todayKey),
      ...days.where((d) => todayKey == null || d.localDate != todayKey),
    ];
    return ordered.map((day) {
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
      final isToday = todayKey != null && day.localDate == todayKey;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: A3DestinationCard(
          borderColor: isToday ? AppTheme.gate2ButtonOlive : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weekdayLabel.isNotEmpty)
                Text(
                  isToday ? '$weekdayLabel · ${l10n.todayLabel}' : weekdayLabel,
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
    final status = (a.status ?? '').toUpperCase();
    final canTick = a.id != null && status == 'ACTIVE' && reviewable && a.reviewOutcome != 'skipped';
    final canEdit = a.id != null && status == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == 'COMPLETED')
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 2, 10, 0),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
          if (canEdit)
            IconButton(
              tooltip: l10n.editItem,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.gate2ButtonOlive),
              onPressed: () => _openItem(a, l10n, reviewable),
            ),
        ],
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
    return null;
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
