import 'package:flutter/material.dart';

import '../../../../core/locale/sedi_locale_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/lifestyle/lifestyle_health_service.dart';
import '../../../gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import '../../../gate3_interactive/presentation/widgets/a3_page_app_bar.dart';
import '../../../../core/locale/calendar_date_math.dart';
import '../lifestyle_l10n.dart';
import '../widgets/hr_chart.dart';
import 'lifestyle_hr_status_page.dart';

class LifestyleHealthPage extends StatefulWidget {
  const LifestyleHealthPage({super.key});

  @override
  State<LifestyleHealthPage> createState() => _LifestyleHealthPageState();
}

class _LifestyleHealthPageState extends State<LifestyleHealthPage> {
  final _svc = LifestyleHealthService();
  String _range = '7d';
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
    final res = await _svc.fetchHr(rangeKey: _range);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok && res.data != null) {
        _data = res.data;
      } else {
        _error = res.errorMessage;
        _data = null;
      }
    });
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
                const SizedBox(height: 12),
                _dataStatusCard(l10n),
                const SizedBox(height: 16),
                _rangeCard(l10n),
                const SizedBox(height: 16),
                _historyCard(l10n),
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

  Widget _rangeCard(LifestyleL10n l10n) {
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.historyRange,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _rangeChip('7d', l10n.range7d),
              _rangeChip('30d', l10n.range30d),
              _rangeChip('3m', l10n.range3m),
              _rangeChip('1y', l10n.range1y),
            ],
          ),
        ],
      ),
    );
  }

  /// Exact gadget data state, one tap away from the full status page.
  Widget _dataStatusCard(LifestyleL10n l10n) {
    final st = _data?.dataStatus ?? const HrDataStatus();
    final active = st.state == 'receiving';
    final color = active ? AppTheme.statusStableOlive : AppTheme.statusNeutralMuted;
    return A3DestinationCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LifestyleHrStatusPage(status: st)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hrStateTitle(st.state),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (st.state != 'never')
                  Text(
                    CalendarDateMath.localizeDigitsForLanguage(
                      '${l10n.hrReadingsReceived}: ${st.todayCount}',
                      l10n.lang,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          Icon(
            l10n.isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  List<HrChartPoint> _chartPoints() {
    final out = <HrChartPoint>[];
    for (final p in _data?.history ?? const <Map<String, dynamic>>[]) {
      final day = CalendarDateMath.parseIsoLocalDate(
        (p['bucket_start']?.toString() ?? '').split('T').first,
      );
      final avg = p['avg'];
      if (day == null || avg is! num) continue;
      out.add(HrChartPoint(day: day, avg: avg.toDouble()));
    }
    return out;
  }

  Widget _historyCard(LifestyleL10n l10n) {
    final points = _chartPoints();
    final weekly = _range == '1y';
    final summary = _data?.summary;
    String digits(Object v) => CalendarDateMath.localizeDigitsForLanguage('$v', l10n.lang);
    String date(DateTime d) => CalendarDateMath.formatIsoForProfileDisplay(
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          l10n.lang,
        );
    return A3DestinationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekly ? l10n.hrChartTitleWeekly : l10n.hrChartTitleDaily,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (points.isEmpty)
            Text(l10n.noHrData, style: const TextStyle(color: AppTheme.textSecondary))
          else ...[
            HrChart(points: points, bars: weekly, semanticsLabel: l10n.hrChartLabel),
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 4, 6, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date(points.first.day),
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                  Text(date(points.last.day),
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (summary != null) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(l10n.hrSummaryAvg, digits(summary.avg)),
                  _summaryItem(l10n.hrSummaryMin, digits(summary.min)),
                  _summaryItem(l10n.hrSummaryMax, digits(summary.max)),
                ],
              ),
            ],
            if (l10n.hrTrendNote(_data?.trend ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.hrTrendNote(_data!.trend),
                style: const TextStyle(fontSize: 13.5, height: 1.7, color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.hrMemoryNote,
              style: const TextStyle(fontSize: 13, height: 1.7, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      );

  Widget _rangeChip(String key, String label) {
    return A3DestinationChip(
      label: label,
      selected: _range == key,
      onTap: () {
        if (_range == key) return;
        setState(() => _range = key);
        _load();
      },
    );
  }
}
