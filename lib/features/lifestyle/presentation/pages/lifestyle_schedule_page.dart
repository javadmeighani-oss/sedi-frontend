import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../services/lifestyle/lifestyle_schedule_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../lifestyle_l10n.dart';
import '../widgets/schedule_notification_settings_card.dart';
import '../widgets/schedule_reminder_sheets.dart';

/// "My Schedule" (R-026 redesign): everything Sedi will remind you of, how she notifies you, and a way to add
/// reminders by hand. Items Sedi created from chat are marked.
class LifestyleSchedulePage extends StatefulWidget {
  const LifestyleSchedulePage({super.key});

  @override
  State<LifestyleSchedulePage> createState() => _LifestyleSchedulePageState();
}

class _LifestyleSchedulePageState extends State<LifestyleSchedulePage> {
  final _svc = LifestyleScheduleService();
  List<LifestyleUserEventDto> _events = const [];
  List<LifestyleI8ActionDto> _actions = const [];
  bool _loading = true;
  bool _appointmentChannelOn = true;
  String? _error;

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
      _error = null;
    });
    final ev = await _svc.listEvents();
    final ac = await _svc.listI8Actions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _events = ev.data ?? const [];
      _actions = ac.data ?? const [];
      if (!ev.ok) _error = ev.errorMessage;
    });
  }

  DateTime? _parse(String? s) =>
      s == null ? null : DateTime.tryParse(s)?.toLocal();

  String _bucketFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'today';
    if (d == today.add(const Duration(days: 1))) return 'tomorrow';
    if (d.isAfter(today) && d.isBefore(today.add(const Duration(days: 7)))) {
      return 'week';
    }
    return 'later';
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setReminder(LifestyleUserEventDto e, int? minutes) async {
    final enabled = minutes != null;
    final offsets = minutes == null ? <int>[] : <int>[minutes];
    final res = await _svc.patchReminder(
      eventId: e.id,
      enabled: enabled,
      offsets: offsets,
    );
    if (!mounted) return;
    if (res.ok) {
      await _load();
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

  Future<void> _addReminder() async {
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
    final res = await _svc.createReminder(
      title: input.title,
      startsAt: input.startsAt,
      offsetMinutes: input.offsetMinutes,
    );
    if (!mounted) return;
    if (res.ok) {
      await _load();
    } else {
      _toast(_l10n.saveFailed);
    }
  }

  Future<void> _delete(LifestyleUserEventDto e) async {
    final res = await _svc.deleteEvent(e.id);
    if (!mounted) return;
    if (res.ok) {
      await _load();
    } else {
      _toast(_l10n.saveFailed);
    }
  }

  String _presetLabel(LifestyleL10n l10n, int? m) =>
      schedulePresetLabel(l10n, m);

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final grouped = <String, List<LifestyleUserEventDto>>{
      'today': [],
      'tomorrow': [],
      'week': [],
      'later': [],
    };
    for (final e in _events) {
      final dt = _parse(e.startsAt);
      if (dt == null) {
        grouped['later']!.add(e);
      } else {
        grouped[_bucketFor(dt)]!.add(e);
      }
    }

    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.mySchedule),
          backgroundColor: A3DestinationSurface.canvas,
        ),
        body: RefreshIndicator(
          color: AppTheme.gate2ButtonOlive,
          onRefresh: _load,
          child: _loading
              ? ListView(children: const [
                  SizedBox(height: 80),
                  Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.gate2ButtonOlive,
                    ),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _hero(l10n),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _addButton(l10n),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: A3DestinationCard(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.dangerRed),
                          ),
                        ),
                      ),
                    _section(l10n.today, grouped['today']!, l10n),
                    _section(l10n.tomorrow, grouped['tomorrow']!, l10n),
                    _section(l10n.thisWeek, grouped['week']!, l10n),
                    _section(l10n.later, grouped['later']!, l10n),
                    const SizedBox(height: 8),
                    Text(
                      l10n.governedActions,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_actions.isEmpty)
                      A3DestinationCard(
                        child: Text(
                          l10n.noEvents,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ..._actions.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: A3DestinationCard(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.scheduleStatusLabel(a.status),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _hero(LifestyleL10n l10n) {
    return A3DestinationCard(
      backgroundColor: SediPalette.pistachio100,
      borderColor: SediPalette.pistachio500,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: SediPalette.pistachio900, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleHeroTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scheduleHeroBody,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const Icon(Icons.notifications_off_outlined,
              size: 20, color: SediPalette.pistachio900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton(LifestyleL10n l10n) {
    return FilledButton.icon(
      onPressed: _addReminder,
      icon: const Icon(Icons.add_alert_outlined),
      label: Text(l10n.addReminder),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.ctaFill,
        foregroundColor: AppTheme.ctaText,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _section(
      String title, List<LifestyleUserEventDto> items, LifestyleL10n l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            A3DestinationCard(
              child: Text(
                l10n.noEvents,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...items.map((e) => _eventTile(e, l10n)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SediPalette.sageInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SediPalette.sageLine, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SediPalette.pistachio900),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(LifestyleUserEventDto e, LifestyleL10n l10n) {
    // 60 = one hour before, 1440 = one day before (locked presets).
    final current = !e.reminderEnabled
        ? null
        : (e.reminderOffsets.isEmpty ? 0 : e.reminderOffsets.first);
    // A repeating reminder shows its rhythm («هر روز · 08:00»), not the date of its first occurrence.
    final repeat = l10n.repeatLabel(e.recurrenceRule, e.startsAt);
    final when =
        repeat ?? A3DestinationSurface.formatIsoTimestamp(e.startsAt, l10n.lang);
    final fromChat = e.source == 'conversation';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: A3DestinationCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.deleteItem,
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.textSecondary),
                  onSelected: (v) {
                    if (v == 'delete') _delete(e);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'delete', child: Text(l10n.deleteItem)),
                  ],
                ),
              ],
            ),
            Text(
              when,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (e.location != null && e.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                e.location!,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _chooseReminder(e),
                  child: _chip(
                    current == null
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined,
                    '${l10n.reminder}: ${_presetLabel(l10n, current)}',
                  ),
                ),
                if (fromChat)
                  _chip(Icons.chat_bubble_outline_rounded, l10n.fromChat),
                if (l10n.eventTypeLabel(e.eventType) != null)
                  _chip(Icons.label_outline, l10n.eventTypeLabel(e.eventType)!),
                _chip(Icons.flag_outlined, l10n.scheduleStatusLabel(e.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
