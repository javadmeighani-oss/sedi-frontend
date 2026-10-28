import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../services/lifestyle/lifestyle_schedule_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../domain/schedule_today.dart';
import '../lifestyle_l10n.dart';
import '../widgets/schedule_add_sheets.dart';
import '../widgets/schedule_notification_settings_card.dart';
import '../widgets/schedule_reminder_sheets.dart';

/// "My Schedule" (R-026 / R-031 redesign): today first - what is next, by category, with a tick for "done" that Sedi
/// remembers (I7). The user adds their own plans by type (medication / doctor visit / meeting / other) and Sedi
/// notifies on time. Notification settings live in one compact, plain-language card. Items Sedi created from chat are
/// marked.
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
  bool _appointmentChannelOn = true;
  String? _error;
  ScheduleCategory? _filter;

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final today = isoDay(DateTime.now());
    final ev = await _svc.listEvents();
    final md = await _svc.listMedications();
    final dn = await _svc.listDone(today);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _events = ev.data ?? const [];
      _meds = md.data ?? const [];
      _doneIds = dn.data ?? <String>{};
      _doneOverride.clear();
      if (!ev.ok) _error = ev.errorMessage;
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
    await _load(silent: true);
  }

  Future<void> _setReminder(LifestyleUserEventDto e, int? minutes) async {
    final res = await _svc.patchReminder(
      eventId: e.id,
      enabled: minutes != null,
      offsets: minutes == null ? <int>[] : <int>[minutes],
    );
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(res.errorMessage);
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
    final res = item.kind == 'medication'
        ? await _svc.deleteMedication(item.refId)
        : await _svc.deleteEvent(item.refId);
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(_l10n.saveFailed);
    }
  }

  Future<void> _add() async {
    final type = await showAddTypeSheet(context, _l10n);
    if (type == null || !mounted) return;
    if (type == ScheduleAddType.medication) {
      await _addMedication();
    } else {
      await _addEvent(type);
    }
  }

  Future<void> _addMedication() async {
    final input = await showModalBottomSheet<NewMedicationInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SediPalette.sageSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ScheduleAddMedicationSheet(l10n: _l10n),
    );
    if (input == null || !mounted) return;
    final res = await _svc.createMedication(name: input.name, times: input.times);
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(_l10n.saveFailed);
    }
  }

  Future<void> _addEvent(ScheduleAddType type) async {
    final input = await showModalBottomSheet<NewReminderInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.gate2CardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ScheduleAddReminderSheet(l10n: _l10n),
    );
    if (input == null || !mounted) return;
    final String domain;
    final String eventType;
    switch (type) {
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
    );
    if (!mounted) return;
    if (res.ok) {
      await _load(silent: true);
    } else {
      _toast(_l10n.saveFailed);
    }
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

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.mySchedule),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addToSchedule),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.ctaFill,
              foregroundColor: AppTheme.ctaText,
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppTheme.gate2ButtonOlive,
          onRefresh: _load,
          child: _loading
              ? ListView(children: const [
                  SizedBox(height: 80),
                  Center(
                    child: CircularProgressIndicator(color: AppTheme.gate2ButtonOlive),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _nextCard(next, all, l10n, now),
                    const SizedBox(height: 12),
                    _chips(all, l10n),
                    const SizedBox(height: 14),
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
                    _sectionTitle(l10n.today),
                    if (shownToday.isEmpty)
                      _emptyCard(all.isEmpty ? l10n.nothingToday : l10n.allDoneToday, hint: all.isEmpty && _meds.isEmpty ? l10n.medsEmptyHint : null)
                    else
                      ...shownToday.map((i) => _itemCard(i, l10n)),
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _sectionTitle(l10n.upcoming),
                      ...upcoming.map((i) => _itemCard(i, l10n, upcoming: true)),
                    ],
                    const SizedBox(height: 14),
                    ScheduleNotificationSettingsCard(
                      l10n: l10n,
                      onAppointmentChannelChanged: (on) {
                        if (mounted) setState(() => _appointmentChannelOn = on);
                      },
                    ),
                    if (!_appointmentChannelOn) ...[
                      const SizedBox(height: 10),
                      _warning(l10n.appointmentOffWarning),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: SediPalette.sageMuted,
            fontSize: 15,
          ),
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
    final doneCount = all.where((i) => i.done).length;
    final title = next == null
        ? (all.isEmpty ? l10n.nothingToday : l10n.allDoneToday)
        : '${next.title} · ${l10n.timeText(next.when)}';
    final trailing = next == null ? null : l10n.relativeIn(next.when.difference(now));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SediPalette.pistachio300, SediPalette.pistachio500],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SediPalette.pistachio700.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded, color: Color(0xFF1B2208), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null ? l10n.today : l10n.nextUp,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2B3316)),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1B2208), height: 1.35),
                ),
                if (all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.hubToday(all.length, doneCount),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B3316)),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1B2208)),
            ),
        ],
      ),
    );
  }

  Widget _chips(List<ScheduleItem> all, LifestyleL10n l10n) {
    int count(ScheduleCategory c) => all.where((i) => i.category == c).length;
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFFF6F3E0) : SediPalette.sageMuted,
            ),
          ),
          selected: selected,
          showCheckmark: false,
          selectedColor: SediPalette.pistachio900,
          backgroundColor: SediPalette.sageSurface,
          side: const BorderSide(color: SediPalette.sageLine),
          onSelected: (_) => onTap(),
        ),
      );
    }

    final cats = <(ScheduleCategory, String)>[
      (ScheduleCategory.medication, l10n.catMedication),
      (ScheduleCategory.appointment, l10n.catAppointment),
      (ScheduleCategory.meeting, l10n.catMeeting),
      (ScheduleCategory.other, l10n.catOther),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(l10n.catAll(all.length), _filter == null, () => setState(() => _filter = null)),
          for (final c in cats)
            if (count(c.$1) > 0 || _filter == c.$1)
              chip(c.$2, _filter == c.$1, () => setState(() => _filter = c.$1)),
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

  Color _accentFor(ScheduleCategory c) {
    switch (c) {
      case ScheduleCategory.medication:
        return SediPalette.pistachio900;
      case ScheduleCategory.appointment:
        return SediPalette.skin700;
      case ScheduleCategory.meeting:
        return SediPalette.charcoal700;
      case ScheduleCategory.other:
        return SediPalette.charcoal500;
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

  Widget _itemCard(ScheduleItem i, LifestyleL10n l10n, {bool upcoming = false}) {
    final accent = _accentFor(i.category);
    final repeat = l10n.repeatLabel(i.recurrenceRule, i.when.toIso8601String());
    final dateText = upcoming
        ? A3DestinationSurface.formatIsoTimestamp(i.when.toIso8601String(), l10n.lang)
        : null;
    final reminderText = i.reminderMinutes == null
        ? null
        : '${l10n.reminder}: ${schedulePresetLabel(l10n, i.reminderMinutes)}';
    final done = i.done;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: done ? SediPalette.sageFill : SediPalette.sageSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SediPalette.sageLine),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                l10n.timeText(i.when),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: done ? SediPalette.sageMuted : AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: done ? SediPalette.sageMuted : AppTheme.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconFor(i.category), size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            repeat == null ? _catLabel(i.category, l10n) : '${_catLabel(i.category, l10n)} · $repeat',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accent),
                          ),
                        ],
                      ),
                      if (i.fromChat)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SediPalette.sagePage,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.fromChat,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SediPalette.sageMuted),
                          ),
                        ),
                    ],
                  ),
                  if (i.event?.location != null && i.event!.location!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(i.event!.location!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                    ),
                  if (dateText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(dateText, style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                    ),
                  if (done)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.doneLabel,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B3316)),
                      ),
                    )
                  else if (reminderText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: i.event == null ? null : () => _chooseReminder(i.event!),
                        child: Text(
                          reminderText,
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                ],
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? SediPalette.pistachio900 : Colors.transparent,
                        border: Border.all(color: SediPalette.pistachio900, width: 2),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded, size: 22, color: Color(0xFFF6F3E0))
                          : null,
                    ),
                  ),
                ),
              ),
            PopupMenuButton<String>(
              tooltip: l10n.deleteItem,
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onSelected: (v) {
                if (v == 'delete') _delete(i);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteItem)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _warning(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SediPalette.sageFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SediPalette.sageLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, size: 20, color: SediPalette.pistachio900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
