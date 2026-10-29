import 'package:flutter/material.dart';

import '../../../../core/auth/user_identity_service.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../data/repositories/notification_prefs_repository.dart';
import '../lifestyle_l10n.dart';

/// The bell in the My Schedule header (pilot V1, R-034, Javad 2026-10-29): ONE setting - how many notifications Sedi
/// sends (less / usual / more). The old "Sedi notifications" card (channels, night window) is gone; Sedi keeps adapting
/// the timing and the wording from the user's reactions. Backend authority = GET/PUT /notifications/prefs
/// (`engagement_level`), the same value the send guard reads.
Future<void> showScheduleAmountSheet(BuildContext context, LifestyleL10n l10n) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => ScheduleAmountSheet(l10n: l10n),
  );
}

class ScheduleAmountSheet extends StatefulWidget {
  final LifestyleL10n l10n;
  const ScheduleAmountSheet({super.key, required this.l10n});

  @override
  State<ScheduleAmountSheet> createState() => _ScheduleAmountSheetState();
}

class _ScheduleAmountSheetState extends State<ScheduleAmountSheet> {
  final _repo = NotificationPrefsRepository();
  int? _userId;
  String _level = 'normal';
  bool _loading = true;
  String? _message;

  LifestyleL10n get _l10n => widget.l10n;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String level = 'normal';
    try {
      _userId = await UserIdentityService.resolveUserId();
      if (_userId != null) {
        final view = await _repo.fetch(userId: _userId!);
        if (view != null) level = view.engagement;
      }
    } catch (_) {
      // fail-open: the sheet still works with the default
    }
    if (!mounted) return;
    setState(() {
      _level = level;
      _loading = false;
    });
  }

  Future<void> _pick(String level) async {
    if (level == _level || _userId == null) return;
    final previous = _level;
    setState(() {
      _level = level;
      _message = null;
    });
    bool ok = false;
    try {
      final res = await _repo.updatePartial(userId: _userId!, engagementLevel: level);
      ok = res.ok;
    } catch (_) {
      ok = false;
    }
    if (!mounted || ok) return;
    setState(() {
      _level = previous;
      _message = _l10n.saveFailed;
    });
  }

  Widget _chip(String key, String label) {
    final on = _level == key;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _loading ? null : () => _pick(key),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: on
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.5),
                      radius: 1.2,
                      colors: [
                        Color(0xFFF6FBD6),
                        Color(0xFFCFE27C),
                        Color(0xFFA9C648),
                        Color(0xFF8FAE3E),
                      ],
                      stops: [0.0, 0.36, 0.78, 1.0],
                    ),
                  )
                : SediGlass.tile().copyWith(borderRadius: BorderRadius.circular(22)),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: on ? FontWeight.w800 : FontWeight.w700,
                color: on ? SediGlass.inkDeep : SediGlass.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    const radius = BorderRadius.all(Radius.circular(36));
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        child: SafeArea(
          top: false,
          child: SediGlass.blur(
            radius: radius,
            sigma: 26,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.74),
                    Colors.white.withOpacity(0.46),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.88)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0x5948551F),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      container: true,
                      label: l10n.engagementTitle,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: SediGlass.tile(),
                            child: const Icon(Icons.tune_rounded, size: 26, color: SediGlass.ink),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              children: [
                                _chip('low', l10n.engagementLow),
                                _chip('normal', l10n.engagementNormal),
                                _chip('high', l10n.engagementHigh),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _message!,
                          style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
