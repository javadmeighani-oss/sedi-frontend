import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_palette.dart';
import '../../../../data/repositories/notification_prefs_repository.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../lifestyle_l10n.dart';

/// Notification settings shown on "My Schedule" (R-026): which kinds of notifications Sedi may send, quiet hours
/// and how often she writes. Backend authority = GET/PUT /notifications/prefs (same prefs the send guard reads).
class ScheduleNotificationSettingsCard extends StatefulWidget {
  final LifestyleL10n l10n;

  /// Reports whether appointment/event reminders are enabled (page shows a warning when off).
  final ValueChanged<bool>? onAppointmentChannelChanged;

  const ScheduleNotificationSettingsCard({
    super.key,
    required this.l10n,
    this.onAppointmentChannelChanged,
  });

  @override
  State<ScheduleNotificationSettingsCard> createState() =>
      _ScheduleNotificationSettingsCardState();
}

class _ScheduleNotificationSettingsCardState
    extends State<ScheduleNotificationSettingsCard> {
  final _repo = NotificationPrefsRepository();
  NotificationPrefsView? _prefs;
  int? _userId;
  bool _loading = true;
  bool _expanded = false;
  String? _message;

  LifestyleL10n get _l10n => widget.l10n;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    NotificationPrefsView? view;
    try {
      _userId = await UserIdentityService.resolveUserId();
      if (_userId != null) view = await _repo.fetch(userId: _userId!);
    } catch (_) {
      view = null;
    }
    if (!mounted) return;
    setState(() {
      _prefs = view;
      _loading = false;
    });
    if (view != null) {
      widget.onAppointmentChannelChanged
          ?.call(view.channels['appointment'] ?? true);
    }
  }

  Future<void> _apply(
    NotificationPrefsView next, {
    Map<String, bool>? channelUpdates,
    bool? quietEnabled,
    String? quietStart,
    String? quietEnd,
    String? engagement,
  }) async {
    final previous = _prefs;
    setState(() {
      _prefs = next;
      _message = null;
    });
    if (channelUpdates?.containsKey('appointment') == true) {
      widget.onAppointmentChannelChanged?.call(channelUpdates!['appointment']!);
    }
    bool ok = false;
    try {
      final res = await _repo.updatePartial(
        userId: _userId!,
        channelUpdates: channelUpdates,
        quietEnabled: quietEnabled,
        quietStart: quietStart,
        quietEnd: quietEnd,
        engagementLevel: engagement,
      );
      ok = res.ok;
    } catch (_) {
      ok = false;
    }
    if (!mounted || ok) return;
    setState(() {
      _prefs = previous;
      _message = _l10n.saveFailed;
    });
    if (previous != null) {
      widget.onAppointmentChannelChanged
          ?.call(previous.channels['appointment'] ?? true);
    }
  }

  NotificationPrefsView _copy(
    NotificationPrefsView p, {
    Map<String, bool>? channels,
    bool? quietEnabled,
    String? quietStart,
    String? quietEnd,
    String? engagement,
  }) =>
      NotificationPrefsView(
        channels: channels ?? p.channels,
        quietEnabled: quietEnabled ?? p.quietEnabled,
        quietStart: quietStart ?? p.quietStart,
        quietEnd: quietEnd ?? p.quietEnd,
        engagement: engagement ?? p.engagement,
      );

  void _toggleChannel(String key, bool value) {
    final p = _prefs;
    if (p == null) return;
    _apply(
      _copy(p, channels: {...p.channels, key: value}),
      channelUpdates: {key: value},
    );
  }

  void _toggleQuiet(bool value) {
    final p = _prefs;
    if (p == null) return;
    _apply(
      _copy(p, quietEnabled: value),
      quietEnabled: value,
      quietStart: p.quietStart,
      quietEnd: p.quietEnd,
    );
  }

  Future<void> _pickQuiet({required bool start}) async {
    final p = _prefs;
    if (p == null) return;
    final raw = start ? p.quietStart : p.quietEnd;
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 22,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final hhmm =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _apply(
      _copy(p, quietStart: start ? hhmm : null, quietEnd: start ? null : hhmm),
      quietEnabled: true,
      quietStart: start ? hhmm : p.quietStart,
      quietEnd: start ? p.quietEnd : hhmm,
    );
  }

  void _setEngagement(String value) {
    final p = _prefs;
    if (p == null || p.engagement == value) return;
    _apply(_copy(p, engagement: value), engagement: value);
  }

  @override
  Widget build(BuildContext context) {
    final p = _prefs;
    return A3DestinationCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            onTap:
                p == null ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: SediPalette.pistachio900,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _l10n.notifSettingsTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _loading
                              ? '…'
                              : (p == null
                                  ? _l10n.settingsLoadFailed
                                  : _l10n.notifSettingsSubtitle),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p != null)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: SediPalette.pistachio900,
                    ),
                ],
              ),
            ),
          ),
          if (p != null && _expanded) ...[
            Divider(height: 1, color: A3DestinationSurface.hairline),
            _channel('appointment', _l10n.chAppointment, p),
            _channel('medication', _l10n.chMedication, p),
            _channel('companion', _l10n.chCompanion, p),
            _channel('system', _l10n.chSystem, p),
            _channel('health_alert', _l10n.chHealthAlert, p),
            Divider(height: 1, color: A3DestinationSurface.hairline),
            SwitchListTile(
              value: p.quietEnabled,
              onChanged: _toggleQuiet,
              activeColor: SediPalette.pistachio900,
              title: Text(
                _l10n.quietHours,
                style: const TextStyle(
                    fontSize: 14.5, color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _l10n.quietHoursHint,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
            if (p.quietEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _timeButton(_l10n.quietFrom, p.quietStart,
                          () => _pickQuiet(start: true)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _timeButton(_l10n.quietTo, p.quietEnd,
                          () => _pickQuiet(start: false)),
                    ),
                  ],
                ),
              ),
            Divider(height: 1, color: A3DestinationSurface.hairline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.engagementTitle,
                    style: const TextStyle(
                        fontSize: 14.5, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _levelChip('low', _l10n.engagementLow, p),
                      _levelChip('normal', _l10n.engagementNormal, p),
                      _levelChip('high', _l10n.engagementHigh, p),
                    ],
                  ),
                ],
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  _message!,
                  style: const TextStyle(
                      color: AppTheme.dangerRed, fontSize: 12.5),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _channel(String key, String label, NotificationPrefsView p) {
    return SwitchListTile(
      value: p.channels[key] ?? true,
      onChanged: (v) => _toggleChannel(key, v),
      activeColor: SediPalette.pistachio900,
      dense: true,
      title: Text(
        label,
        style: const TextStyle(fontSize: 14.5, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _timeButton(String label, String value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: SediPalette.pistachio900,
        side: const BorderSide(color: SediPalette.sageLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text('$label  $value'),
    );
  }

  Widget _levelChip(String value, String label, NotificationPrefsView p) {
    final selected = p.engagement == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setEngagement(value),
      selectedColor: SediPalette.pistachio500,
      backgroundColor: SediPalette.sageInput,
      labelStyle: TextStyle(
        color: selected ? SediPalette.charcoal950 : AppTheme.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: const BorderSide(color: SediPalette.sageLine),
    );
  }
}
