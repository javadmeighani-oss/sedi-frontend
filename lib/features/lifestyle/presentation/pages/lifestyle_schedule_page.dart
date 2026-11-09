import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../services/lifestyle/lifestyle_schedule_service.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../../domain/schedule_today.dart';
import '../../logic/lifestyle_summary_cache.dart';
import '../lifestyle_l10n.dart';
import '../widgets/schedule_add_sheets.dart';
import '../widgets/schedule_amount_sheet.dart';
import '../widgets/schedule_reminder_sheets.dart';

/// "My Schedule" (R-026 / R-031, pilot V1 redesign R-034): today first - what is next, by category, with a tick for
/// "done" that Sedi remembers (I7). The user adds anything in ONE sheet (type, title, day, time, repeat on chosen
/// weekdays at the same time, when to notify) and Sedi notifies on time. The only notification setting is the bell in
/// the header (how many). Items Sedi created from chat are marked.
class LifestyleSchedulePage extends StatefulWidget {
  const LifestyleSchedulePage({super.key});

  @override
  State<LifestyleSchedulePage> createState() => _LifestyleSchedulePageState();
}

class _LifestyleSchedulePageState extends State<LifestyleSchedulePage> {
  final _svc = LifestyleScheduleService();
  List<LifestyleUserEventDto> _events = const [];
  List<LifestyleMedicationDto> _meds = const [];
  Set<String> _doneIds = <String>{};
  // Optimistic ticks until the next reload confirms them.
  final Map<String, bool> _doneOverride = <String, bool>{};
  bool _loading = true;
  String? _error;
  ScheduleCategory? _filter;

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    // R-050: what was seen last (or loaded by A3 in the background) paints at once; the fresh read replaces it.
    final seen = ScheduleSnapshot.today();
    if (seen != null) {
      _events = seen.events;
      _meds = seen.meds;
      _doneIds = seen.doneIds;
      _loading = false;
    }
    _load(silent: seen != null);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final today = isoDay(DateTime.now());
    // The three reads run together (they used to wait for each other).
    final evF = _svc.listEvents();
    final mdF = _svc.listMedications();
    final dnF = _svc.listDone(today);
    final ev = await evF;
    final md = await mdF;
    final dn = await dnF;
    if (!mounted) return;
    if (ev.ok) ScheduleSnapshot.remember(ev.data ?? const [], md.data ?? const [], dn.data ?? <String>{});
    if (!ev.ok && silent && (_events.isNotEmpty || _meds.isNotEmpty)) {
      return; // a failed refresh never wipes what the user already sees
    }
    setState(() {
      _loading = false;
      _events = ev.data ?? const [];
      _meds = md.data ?? const [];
      _doneIds = dn.data ?? <String>{};
      _doneOverride.clear();
      _error = ev.ok ? null : ev.errorMessage;
    });
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<ScheduleItem> _todayItems() {
    final items = buildToday(
      events: _events,
      medications: _meds,
      doneIds: _doneIds,
      today: DateTime.now(),
    );
    return [
      for (final i in items) i.withDone(_doneOverride[i.occurrenceId] ?? i.done),
    ];
  }

  bool _passes(ScheduleItem i) => _filter == null || i.category == _filter;

  // ------------------------------------------------------------------ actions
  Future<void> _toggleDone(ScheduleItem item) async {
    final next = !item.done;
    setState(() => _doneOverride[item.occurrenceId] = next);
    final res = await _svc.markDone(
      kind: item.kind,
      id: item.refId,
      day: isoDay(item.when),
      time: item.medTime,
      done: next,
    );
    if (!mounted) return;
    if (!res.ok) {
      setState(() => _doneOverride.remove(item.occurrenceId));
      _toast(_l10n.saveFailed);
      return;
    }
    if (next) {
      _toast(res.data?.inMemory == true ? _l10n.rememberedBySedi : _l10n.doneSaved);
    }
    _load(silent: true); // in the background: the tick already shows
  }

  Future<void> _setReminder(LifestyleUserEventDto e, int? minutes) async {
    // Instant: the bell shows the new lead time at once; the server answer only confirms or undoes it.
    final before = _events;
    setState(() {
      _events = [
        for (final x in _events)
          if (x.id == e.id)
            _copyEvent(x,
                reminderEnabled: minutes != null,
                reminderOffsets: minutes == null ? <int>[] : <int>[minutes])
          else
            x,
      ];
    });
    final res = await _svc.patchReminder(
      eventId: e.id,
      enabled: minutes != null,
      offsets: minutes == null ? <int>[] : <int>[minutes],
    );
    if (!mounted) return;
    if (res.ok) {
      _load(silent: true);
    } else {
      setState(() => _events = before);
      _toast(_failText(res));
    }
  }

  Future<void> _chooseReminder(LifestyleUserEventDto e) async {
    final current = !e.reminderEnabled
        ? null
        : (e.reminderOffsets.isEmpty ? 0 : e.reminderOffsets.first);
    final choice = await showReminderPresetSheet(
      context,
      l10n: _l10n,
      current: current,
    );
    if (choice == null) return;
    await _setReminder(e, choice.minutes);
  }

  Future<void> _delete(ScheduleItem item) async {
    // Instant: the card disappears at once; if the server refuses it comes back with a short message.
    final beforeEvents = _events;
    final beforeMeds = _meds;
    setState(() {
      if (item.kind == 'medication') {
        _meds = [for (final m in _meds) if (m.id != item.refId) m];
      } else {
        _events = [for (final e in _events) if (e.id != item.refId) e];
      }
    });
    final res = item.kind == 'medication'
        ? await _svc.deleteMedication(item.refId)
        : await _svc.deleteEvent(item.refId);
    if (!mounted) return;
    if (res.ok || res.statusCode == 404) {
      // 404 = it was already gone: the card stays removed.
      ScheduleSnapshot.remember(_events, _meds, _doneIds);
      _load(silent: true);
    } else {
      setState(() {
        _events = beforeEvents;
        _meds = beforeMeds;
      });
      _toast(_failText(res));
    }
  }

  /// ONE sheet for everything: the type is chosen inside it (medication keeps its dose times).
  Future<void> _add() async {
    final input = await showModalBottomSheet<NewReminderInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleAddReminderSheet(l10n: _l10n),
    );
    if (input == null || !mounted) return;
    if (input.type == ScheduleAddType.medication) {
      await _addMedication(input);
    } else {
      await _addEvent(input);
    }
  }

  Future<void> _addMedication(NewReminderInput input) async {
    final res = await _svc.createMedication(name: input.title, times: input.times);
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(_failText(res));
    }
  }

  Future<void> _addEvent(NewReminderInput input) async {
    final String domain;
    final String eventType;
    switch (input.type) {
      case ScheduleAddType.appointment:
        domain = 'medical';
        eventType = 'doctor_visit';
        break;
      case ScheduleAddType.meeting:
        domain = 'work';
        eventType = 'work_meeting';
        break;
      default:
        domain = 'lifestyle';
        eventType = 'other';
    }
    final res = await _svc.createReminder(
      title: input.title,
      startsAt: input.startsAt,
      offsetMinutes: input.offsetMinutes,
      eventDomain: domain,
      eventType: eventType,
      recurrenceRule: input.recurrenceRule,
    );
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(_failText(res));
    }
  }

  /// R-074 step 5b: the user's own week in one sheet (Sedi's sentence + done / not done).
  Future<void> _showWeeklyReport() async {
    final res = await _svc.weeklyReport();
    if (!mounted) return;
    final data = res.ok ? res.data : null;
    final totals = data?['totals'];
    final done = (totals is Map ? totals['done'] : null) ?? 0;
    final notDone = (totals is Map ? totals['not_done'] : null) ?? 0;
    final message = (data?['message'] ?? '').toString().trim();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.weeklyReportTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
              ),
              const SizedBox(height: 10),
              if (data == null)
                Text(_l10n.weeklyUnavailable)
              else ...[
                if (message.isNotEmpty) Text(message, style: const TextStyle(fontSize: 15, height: 1.5)),
                const SizedBox(height: 12),
                Text('${_l10n.weeklyDone}: $done    ${_l10n.weeklyNotDone}: $notDone',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Why a save failed: no answer from the server (network / VPN) is said plainly; anything else keeps the short message.
  String _failText(ApiResponse<void> res) {
    debugPrint('[Schedule] save failed status=${res.statusCode} code=${res.error?.code}');
    return res.statusCode == null ? _l10n.saveFailedNetwork : _l10n.saveFailed;
  }

  /// Javad 2026-11-09: edit the plan name and its day / time (the notification follows the new time).
  Future<void> _edit(ScheduleItem item) async {
    if (item.event == null) return;
    final result = await showDialog<_EditedPlan>(
      context: context,
      builder: (ctx) => _EditPlanDialog(l10n: _l10n, title: item.title, when: item.when),
    );
    if (result == null || !mounted) return;
    final titleChanged = result.title != item.title;
    final timeChanged = result.when != item.when;
    if (!titleChanged && !timeChanged) return;
    // The new name shows at once; the server and the reload follow in the background.
    final before = _events;
    if (titleChanged) {
      setState(() {
        _events = [
          for (final e in _events)
            if (e.id == item.refId) _copyEvent(e, title: result.title) else e,
        ];
      });
    }
    final res = await _svc.updateEvent(
      eventId: item.refId,
      title: titleChanged ? result.title : null,
      startsAt: timeChanged ? result.when : null,
    );
    if (!mounted) return;
    if (res.ok) {
      _load(silent: true);
    } else {
      setState(() => _events = before);
      _toast(_failText(res));
    }
  }

  /// A copy of an event with some fields changed (the DTO is immutable) - used for instant, optimistic updates.
  LifestyleUserEventDto _copyEvent(
    LifestyleUserEventDto e, {
    String? title,
    bool? reminderEnabled,
    List<int>? reminderOffsets,
  }) {
    return LifestyleUserEventDto(
      id: e.id,
      title: title ?? e.title,
      location: e.location,
      eventType: e.eventType,
      status: e.status,
      startsAt: e.startsAt,
      reminderEnabled: reminderEnabled ?? e.reminderEnabled,
      reminderOffsets: reminderOffsets ?? e.reminderOffsets,
      source: e.source,
      recurrenceRule: e.recurrenceRule,
    );
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final now = DateTime.now();
    final all = _todayItems();
    final shownToday = all.where(_passes).toList();
    final upcoming = buildUpcoming(events: _events, today: now).where(_passes).toList();
    final next = nextUp(all, now);
    // Javad 2026-10-28: with nothing planned there is ONE clear thing to do - add. No empty boxes, no filter chips.
    final hasAny = all.isNotEmpty || upcoming.isNotEmpty;
    final categories = all.map((i) => i.category).toSet().length;
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
                l10n.mySchedule,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.inkDeep,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: l10n.weeklyReportTitle,
              icon: const Icon(Icons.insights_rounded, color: SediGlass.inkDeep),
              onPressed: _showWeeklyReport,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Tooltip(
                message: l10n.engagementTitle,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => showScheduleAmountSheet(context, l10n),
                    child: Container(
                      width: 44,
                      height: 44,
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
                      child: const Icon(Icons.notifications_none_rounded,
                          size: 22, color: SediGlass.ink),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: hasAny
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: _addPill(l10n),
                ),
              )
            : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SediSceneBackdrop(),
            RefreshIndicator(
              color: AppTheme.gate2ButtonOlive,
              onRefresh: _load,
              child: _loading
                  ? ListView(children: const [
                      SizedBox(height: 160),
                      Center(
                        child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive),
                      ),
                    ])
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, top, 16, 24),
                      children: [
                        if (!hasAny) ...[
                          _emptyAddCard(l10n),
                          const SizedBox(height: 14),
                        ] else ...[
                          // Javad 2026-11-09: the "next" card only helps when there is something to choose from; with ONE item it
                          // just repeats the card right below it.
                          if (all.length >= 2) ...[
                            _nextCard(next, all, l10n, now),
                            const SizedBox(height: 12),
                          ],
                          if (categories >= 2) ...[
                            _chips(all, l10n),
                            const SizedBox(height: 14),
                          ],
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: A3DestinationCard(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.dangerRed),
                              ),
                            ),
                          ),
                        if (all.isNotEmpty) ...[
                          if (shownToday.isEmpty)
                            _emptyCard(l10n.allDoneToday)
                          else
                            ...shownToday.map((i) => _itemCard(i, l10n)),
                        ],
                        if (upcoming.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _sectionTitle(l10n.upcoming),
                          ...upcoming.map((i) => _itemCard(i, l10n, upcoming: true)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The 3D pistachio Add pill (one short word).
  Widget _addPill(LifestyleL10n l10n, {bool wide = false}) {
    return Semantics(
      button: true,
      label: l10n.addAction,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _add,
        child: Container(
          height: 56,
          width: wide ? double.infinity : null,
          constraints: const BoxConstraints(minWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const RadialGradient(
              center: Alignment(-0.5, -0.8),
              radius: 1.6,
              colors: [
                Color(0xFFF6FBD6),
                Color(0xFFCFE27C),
                Color(0xFFA9C648),
                Color(0xFF8FAE3E),
              ],
              stops: [0.0, 0.38, 0.8, 1.0],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x57608022),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, size: 26, color: SediGlass.inkDeep),
              const SizedBox(width: 10),
              Text(
                l10n.addAction,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.inkDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _glass(double radius) => SediGlass.card(BorderRadius.circular(radius));

  /// The one empty state: what this page is for and a big Add button (replaces the empty "nothing today" boxes).
  Widget _emptyAddCard(LifestyleL10n l10n) {
    final radius = BorderRadius.circular(34);
    return SediGlass.blur(
      radius: radius,
      sigma: 18,
      child: DecoratedBox(
        decoration: SediGlass.card(radius, strong: true),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: SediGlass.tile().copyWith(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.event_available_rounded,
                      size: 44, color: SediGlass.ink),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.scheduleEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SediGlass.inkDeep,
                ),
              ),
              const SizedBox(height: 16),
              // what can be added: icons only
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final icon in const [
                    Icons.medication_outlined,
                    Icons.local_hospital_outlined,
                    Icons.groups_outlined,
                    Icons.notifications_active_outlined,
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: SediGlass.tile().copyWith(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, size: 26, color: SediGlass.ink),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _addPill(l10n, wide: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 17, color: SediPalette.sageMuted),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: SediPalette.sageMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );

  Widget _emptyCard(String text, {String? hint}) => A3DestinationCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ],
        ),
      );

  Widget _nextCard(ScheduleItem? next, List<ScheduleItem> all, LifestyleL10n l10n, DateTime now) {
    final title = next == null
        ? (all.isEmpty ? l10n.nothingToday : l10n.allDoneToday)
        : next.title;
    final label = next == null
        ? null
        : '${l10n.nextUp} · ${l10n.relativeIn(next.when.difference(now))}';
    const ink = Color(0xFF1B2208);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SediPalette.pistachio300, SediPalette.pistachio500],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: SediPalette.pistachio700.withOpacity(0.30),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(20)),
            child: Icon(
              next == null ? Icons.event_available_rounded : _iconFor(next.category),
              size: 30,
              color: SediGlass.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2B3316)),
                  ),
                Text(
                  title, // the full name the user gave (Javad 2026-11-09): no cut-off
                  softWrap: true,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink, height: 1.3),
                ),
              ],
            ),
          ),
          if (next != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                l10n.timeText(next.when),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink),
              ),
            ),
        ],
      ),
    );
  }

  /// Category filter: icons only (shown only when there are two or more categories).
  Widget _chips(List<ScheduleItem> all, LifestyleL10n l10n) {
    int count(ScheduleCategory c) => all.where((i) => i.category == c).length;
    Widget chip(Widget child, String semantic, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Semantics(
          button: true,
          selected: selected,
          label: semantic,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: 38,
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: selected
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.6),
                        radius: 1.6,
                        colors: [
                          Color(0xFFF6FBD6),
                          Color(0xFFCFE27C),
                          Color(0xFFA9C648),
                        ],
                      ),
                    )
                  : SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(19)),
              child: child,
            ),
          ),
        ),
      );
    }

    final cats = <ScheduleCategory>[
      ScheduleCategory.medication,
      ScheduleCategory.appointment,
      ScheduleCategory.meeting,
      ScheduleCategory.other,
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(
            Text(
              l10n.catAll(all.length),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SediGlass.inkDeep),
            ),
            l10n.catAll(all.length),
            _filter == null,
            () => setState(() => _filter = null),
          ),
          for (final c in cats)
            if (count(c) > 0 || _filter == c)
              chip(
                Icon(_iconFor(c), size: 20, color: SediGlass.ink),
                _catLabel(c, l10n),
                _filter == c,
                () => setState(() => _filter = c),
              ),
        ],
      ),
    );
  }

  IconData _iconFor(ScheduleCategory c) {
    switch (c) {
      case ScheduleCategory.medication:
        return Icons.medication_outlined;
      case ScheduleCategory.appointment:
        return Icons.local_hospital_outlined;
      case ScheduleCategory.meeting:
        return Icons.groups_outlined;
      case ScheduleCategory.other:
        return Icons.event_note_outlined;
    }
  }

  String _catLabel(ScheduleCategory c, LifestyleL10n l10n) {
    switch (c) {
      case ScheduleCategory.medication:
        return l10n.catMedication;
      case ScheduleCategory.appointment:
        return l10n.catAppointment;
      case ScheduleCategory.meeting:
        return l10n.catMeeting;
      case ScheduleCategory.other:
        return l10n.catOther;
    }
  }

  /// A compact glass row: the category icon, the title with its time (and repeat), a small bell for the lead, the tick.
  Widget _itemCard(ScheduleItem i, LifestyleL10n l10n, {bool upcoming = false}) {
    final repeat = l10n.repeatLabel(i.recurrenceRule, i.when.toIso8601String());
    final dateText = upcoming
        ? A3DestinationSurface.formatIsoTimestamp(i.when.toIso8601String(), l10n.lang)
        : null;
    final done = i.done;
    final radius = BorderRadius.circular(24);
    final ink = done ? const Color(0xFF8A936B) : const Color(0xFF1F2A09);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SediGlass.blur(
        radius: radius,
        sigma: 14,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
          decoration: _glass(24),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(16)),
                child: Icon(_iconFor(i.category), size: 25, color: SediGlass.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.title, // the full name the user gave: it wraps instead of being cut off
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              dateText == null
                                  ? l10n.timeText(i.when)
                                  : '$dateText  ${l10n.timeText(i.when)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B6640),
                              ),
                            ),
                          ),
                        ),
                        if (repeat != null) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFF5B6640)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              repeat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B6640),
                              ),
                            ),
                          ),
                        ],
                        if (i.fromChat) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: l10n.fromChat,
                            child: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 14, color: Color(0xFF5B6640)),
                          ),
                        ],
                      ],
                    ),
                    if (!done && i.event != null && i.reminderMinutes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '${l10n.notifyAtLabel}: ${l10n.timeText(i.when.subtract(Duration(minutes: i.reminderMinutes!)))}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3F4A24),
                            ),
                          ),
                        ),
                      ),
                    if (i.event?.location != null && i.event!.location!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          i.event!.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              if (!done && i.event != null && i.reminderMinutes != null)
                Tooltip(
                  message: '${l10n.reminder}: ${schedulePresetLabel(l10n, i.reminderMinutes)}',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _chooseReminder(i.event!),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.notifications_none_rounded, size: 20, color: SediGlass.ink),
                    ),
                  ),
                ),
              if (!upcoming)
                Semantics(
                  button: true,
                  label: done ? l10n.undoDone : l10n.markDone,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _toggleDone(i),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: done
                            ? SediGlass.pistachioSphere()
                            : BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.35),
                                border: Border.all(
                                  color: const Color(0x7348551F),
                                  width: 1.6,
                                ),
                              ),
                        child: done
                            ? const Icon(Icons.check_rounded, size: 20, color: SediGlass.inkDeep)
                            : null,
                      ),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: l10n.deleteItem,
                icon: const Icon(Icons.more_horiz_rounded, color: AppTheme.textSecondary),
                onSelected: (v) {
                  if (v == 'delete') _delete(i);
                  if (v == 'edit') _edit(i);
                },
                itemBuilder: (_) => [
                  if (i.kind != 'medication' && i.event != null)
                    PopupMenuItem(value: 'edit', child: Text(l10n.editItem)),
                  PopupMenuItem(value: 'delete', child: Text(l10n.deleteItem)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The result of the edit dialog: the new plan name and its (possibly new) day and time.
class _EditedPlan {
  final String title;
  final DateTime when;
  const _EditedPlan(this.title, this.when);
}

/// The edit dialog owns its controller (initState / dispose) - see the name dialog of the profile.
class _EditPlanDialog extends StatefulWidget {
  final LifestyleL10n l10n;
  final String title;
  final DateTime when;

  const _EditPlanDialog({required this.l10n, required this.title, required this.when});

  @override
  State<_EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends State<_EditPlanDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.title);
  late DateTime _when = widget.when;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.editItemTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 120,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.editNameHint),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_rounded),
              label: Text('${l10n.editChangeDay}: ${_when.year}-${_two(_when.month)}-${_two(_when.day)}'),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _when,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (d != null && mounted) {
                  setState(() => _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
                }
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule_rounded),
              label: Text('${l10n.editChangeTime}: ${_two(_when.hour)}:${_two(_when.minute)}'),
              onPressed: () async {
                final tm = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _when.hour, minute: _when.minute),
                );
                if (tm != null && mounted) {
                  setState(() => _when = DateTime(_when.year, _when.month, _when.day, tm.hour, tm.minute));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_EditedPlan(name, _when));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
