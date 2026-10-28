import 'package:flutter/material.dart';

import '../../../../core/locale/calendar_date_math.dart';
import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/lifestyle/lifestyle_health_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait(
      _averageRanges.map((r) => _svc.fetchHr(rangeKey: r)),
    );
    if (!mounted) return;
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
    return Directionality(
      textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: A3DestinationSurface.canvas,
        appBar: A3PageAppBar(
          title: Text(l10n.health),
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
                  const SizedBox(height: 16),
                  _statusBlock(l10n),
                ],
                const SizedBox(height: 16),
                _averagesCard(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _latestHrCard(LifestyleL10n l10n) {
    final value = _data?.latestValue;
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.latestHr,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (value != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${value.round()}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text: '  bpm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              l10n.noHrData,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.lastReceived,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTs(_data?.latestReceivedAt),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
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
    return A3DestinationCard(
      borderColor: color.withOpacity(0.45),
      child: Row(
        children: [
          Icon(Icons.monitor_heart_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deviceReportedHrStatusLabel(code),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _averagesCard(LifestyleL10n l10n) {
    final rows = <(String, String)>[
      ('7d', l10n.avgLastWeek),
      ('30d', l10n.avgLastMonth),
      ('1y', l10n.avgLastYear),
    ];
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.avgHeartRateTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _averages[r.$1] == null
                        ? '—'
                        : CalendarDateMath.localizeDigitsForLanguage(
                            '${_averages[r.$1]} bpm',
                            l10n.lang,
                          ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _averages[r.$1] == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
