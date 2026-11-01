import '../../../../core/cache/page_snapshot_cache.dart';
import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/sedi_glass.dart';
import '../../../../services/lifestyle/lifestyle_health_service.dart';
import '../../../gate3_interactive/models/gate3_interaction_state.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import '../../../gate3_interactive/presentation/widgets/sedi_scene_backdrop.dart';
import '../lifestyle_l10n.dart';

class LifestyleHealthPage extends StatefulWidget {
  const LifestyleHealthPage({super.key});

  @override
  State<LifestyleHealthPage> createState() => _LifestyleHealthPageState();
}

class _LifestyleHealthPageState extends State<LifestyleHealthPage> {
  final _svc = LifestyleHealthService();
  /// Javad 2026-10-28: no history list - just the average heart rate over the last week, month and year.
  static const List<String> _averageRanges = ['7d', '30d', '1y'];
  final Map<String, int?> _averages = <String, int?>{};
  LifestyleHealthHrDto? _data;
  bool _loading = true;
  String? _error;

  LifestyleL10n get _l10n =>
      LifestyleL10n(SediLocaleController.instance.languageCode);

  @override
  void initState() {
    super.initState();
    // R-050: the last values seen paint at once; the fresh read replaces them.
    final seen = PageSnapshotCache.get<_HealthSnapshot>(PageSnapshotCache.health);
    if (seen != null) {
      _data = seen.data;
      _averages.addAll(seen.averages);
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
    final results = await Future.wait(
      _averageRanges.map((r) => _svc.fetchHr(rangeKey: r)),
    );
    if (!mounted) return;
    if (silent && !(results.first.ok && results.first.data != null)) return; // a failed refresh keeps what is shown
    setState(() {
      _loading = false;
      final first = results.first;
      if (first.ok && first.data != null) {
        _data = first.data; // latest value + the gadget's own status come with every range
        for (var i = 0; i < _averageRanges.length; i++) {
          _averages[_averageRanges[i]] =
              results[i].ok ? _averageOf(results[i].data) : null;
        }
      } else {
        _error = first.errorMessage;
        _data = null;
      }
    });
    if (_data != null) {
      PageSnapshotCache.put(PageSnapshotCache.health, _HealthSnapshot(_data, Map<String, int?>.from(_averages)));
    }
  }

  /// Plain average of the range's daily/weekly averages (weighted by sample count when the backend sends it).
  int? _averageOf(LifestyleHealthHrDto? dto) {
    var sum = 0.0;
    var weight = 0.0;
    for (final p in dto?.history ?? const <Map<String, dynamic>>[]) {
      final avg = p['avg'];
      if (avg is! num) continue;
      final c = p['count'];
      final w = (c is num && c > 0) ? c.toDouble() : 1.0;
      sum += avg.toDouble() * w;
      weight += w;
    }
    return weight == 0 ? null : (sum / weight).round();
  }

  Color _statusColor(String code) {
    switch (code.toUpperCase()) {
      case 'STABLE':
        return AppTheme.statusStableOlive;
      case 'UNSTABLE':
        return AppTheme.statusChangeAmber;
      default:
        return AppTheme.statusNeutralMuted;
    }
  }

  String _formatTs(String? raw) =>
      A3DestinationSurface.formatIsoTimestamp(raw, _l10n.lang);

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
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
                l10n.health,
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SediSceneBackdrop(),
            RefreshIndicator(
              color: AppTheme.gate2ButtonOlive,
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, top, 16, 28),
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
                  else if (_error != null)
                    A3DestinationCard(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.dangerRed),
                      ),
                    )
                  else ...[
                    _latestHrCard(l10n),
                    if (_data?.isDeviceReportedStatus == true) ...[
                      const SizedBox(height: 14),
                      _statusBlock(l10n),
                    ],
                    const SizedBox(height: 14),
                    _averagesCard(l10n),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glass({required Widget child, bool strong = false, EdgeInsets padding = const EdgeInsets.all(18)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: SediGlass.card(BorderRadius.circular(28), strong: strong),
      child: child,
    );
  }

  Widget _latestHrCard(LifestyleL10n l10n) {
    final value = _data?.latestValue;
    return _glass(
      strong: true,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.35)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: const Icon(Icons.favorite_border_rounded, size: 30, color: SediGlass.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.latestHr,
                  style: TextStyle(
                    color: SediGlass.ink.withOpacity(0.75),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (value != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: CalendarDateMath.localizeDigitsForLanguage('${value.round()}', l10n.lang),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: SediGlass.inkDeep,
                            ),
                          ),
                          TextSpan(
                            text: '  bpm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: SediGlass.ink.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    l10n.noHrData,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      color: SediGlass.inkDeep,
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(height: 26, width: double.infinity, child: CustomPaint(painter: _PulsePainter(live: value != null))),
                const SizedBox(height: 8),
                Text(
                  '${l10n.lastReceived}: ${_formatTs(_data?.latestReceivedAt)}',
                  style: TextStyle(
                    color: SediGlass.ink.withOpacity(0.7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBlock(LifestyleL10n l10n) {
    // Caller must already gate with isDeviceReportedStatus (STABLE|UNSTABLE only).
    final code = (_data?.hrStatus ?? '').trim().toUpperCase();
    final color = _statusColor(code);
    return _glass(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
              border: Border.all(color: color.withOpacity(0.55)),
            ),
            child: Icon(Icons.monitor_heart_outlined, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deviceReportedHrStatusLabel(code),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SediGlass.inkDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The average of the last week, month and year as three glass tiles side by side (Javad 2026-10-28: only averages).
  Widget _averagesCard(LifestyleL10n l10n) {
    final rows = <(String, String)>[
      ('7d', l10n.avgLastWeek),
      ('30d', l10n.avgLastMonth),
      ('1y', l10n.avgLastYear),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
          child: Text(
            l10n.avgHeartRateTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SediGlass.inkDeep,
            ),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _averageTile(rows[i].$2, _averages[rows[i].$1], l10n)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _averageTile(String label, int? value, LifestyleL10n l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: SediGlass.card(BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: SediGlass.ink.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value == null ? '\u2014' : CalendarDateMath.localizeDigitsForLanguage('$value', l10n.lang),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: value == null ? SediGlass.ink.withOpacity(0.5) : SediGlass.inkDeep,
            ),
          ),
          Text(
            'bpm',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: SediGlass.ink.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }
}

/// A calm, decorative pulse line (never data): brighter when a value exists.
class _PulsePainter extends CustomPainter {
  final bool live;

  const _PulsePainter({required this.live});

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final path = Path()..moveTo(0, mid);
    final unit = size.width / 12;
    path
      ..lineTo(unit * 3, mid)
      ..lineTo(unit * 3.8, mid - size.height * 0.42)
      ..lineTo(unit * 4.7, mid + size.height * 0.45)
      ..lineTo(unit * 5.5, mid - size.height * 0.12)
      ..lineTo(unit * 6.2, mid)
      ..lineTo(unit * 9, mid)
      ..lineTo(unit * 9.7, mid - size.height * 0.3)
      ..lineTo(unit * 10.4, mid)
      ..lineTo(size.width, mid);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = live ? const Color(0xFF48551F) : const Color(0xFF48551F).withOpacity(0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => oldDelegate.live != live;
}

/// The health numbers as last seen (R-050).
class _HealthSnapshot {
  final LifestyleHealthHrDto? data;
  final Map<String, int?> averages;
  const _HealthSnapshot(this.data, this.averages);
}
