import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/memory/memory_consent_service.dart';
import '../../../../core/memory/memory_consent_status.dart';
import '../../../../core/profile/profile_snapshot_cache.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../gate3_localization.dart';

/// Profile-only I6 Memory control. Shows backend consent state; never fabricates a default.
class Gate3ProfileMemoryControl extends StatefulWidget {
  const Gate3ProfileMemoryControl({super.key, this.service});

  final MemoryConsentService? service;

  @override
  State<Gate3ProfileMemoryControl> createState() =>
      _Gate3ProfileMemoryControlState();
}

class _Gate3ProfileMemoryControlState extends State<Gate3ProfileMemoryControl> {
  late final MemoryConsentService _service =
      widget.service ?? MemoryConsentService();

  // The last known switch is shown at once (A3 reads it in the background); the read below refreshes it silently, so
  // the profile has no spinner (Javad 2026-10-31). With nothing known yet the switch is simply disabled, never faked.
  MemoryConsentStatus? _status = ProfileSnapshotCache.memory;
  bool _busy = false;
  String? _error;

  Gate3Localization get _l10n =>
      Gate3Localization(SediLocaleController.instance.languageCode);

  bool get _granted => _status?.granted == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _service.fetchStatus();
    if (!mounted) return;
    setState(() {
      if (res.ok && res.data != null) {
        _status = res.data;
        _error = null;
        ProfileSnapshotCache.putMemory(res.data!);
      } else if (_status == null) {
        // A failed read never hides a status that is already known.
        _error = _l10n.memoryConsentLoadError;
      }
    });
  }

  Future<void> _grant() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await _service.grant();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.ok && res.data != null) {
        _status = res.data;
        ProfileSnapshotCache.putMemory(res.data!);
      } else {
        _error = _l10n.memoryConsentActionError;
      }
    });
  }

  Future<void> _revoke() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final res = await _service.revoke();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.ok && res.data != null) {
        _status = res.data;
        ProfileSnapshotCache.putMemory(res.data!);
      } else {
        _error = _l10n.memoryConsentActionError;
      }
    });
  }

  Future<void> _onToggle(bool next) async {
    if (_status == null || _busy) return;
    if (_granted && !next) {
      final confirmed = await _confirmTurnOff();
      if (confirmed == true) {
        await _revoke();
      }
      return;
    }
    if (!_granted && next) {
      await _grant();
    }
  }

  Future<bool?> _confirmTurnOff() {
    final l10n = _l10n;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.memoryOffConfirmTitle),
          content: Text(l10n.memoryOffConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.memoryOffConfirmKeepOn),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.memoryOffConfirmTurnOff),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final radius = BorderRadius.circular(26);
    final label = _status == null
        ? l10n.memoryConsentStatusLabel
        : (_granted ? l10n.memoryControlOn : l10n.memoryControlOff);
    return Semantics(
      container: true,
      label: l10n.memoryAndPrivacy,
      child: SediGlass.blur(
        radius: radius,
        sigma: 16,
        child: DecoratedBox(
          decoration: SediGlass.card(radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: SediGlass.tile(),
                      child: Icon(
                        _granted
                            ? Icons.verified_user_outlined
                            : Icons.shield_outlined,
                        size: 23,
                        color: SediGlass.ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SediGlass.inkDeep,
                        ),
                      ),
                    ),
                    Switch(
                      value: _granted,
                      onChanged: (_status == null || _busy) ? null : _onToggle,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF8FAE3E),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0x4D48551F),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.dangerRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
