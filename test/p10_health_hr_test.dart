import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/services/lifestyle/lifestyle_health_service.dart';
import 'package:sedi_app/services/lifestyle/memory_explorer_service.dart';

String _read(String path) => File(path).readAsStringSync();

/// P10 (Javad 2026-10-28): Health (heart rate only) shows a chart, the exact state of the gadget's data, a plain summary
/// and trend; no diagnosis, no thresholds, no colours that judge a value.
void main() {
  test('the HR projection parses summary, trend and data status', () {
    final dto = LifestyleHealthHrDto.fromJson({
      'range_key': '7d',
      'latest_value': 72.0,
      'history': [
        {'bucket_start': '2026-10-22T00:00:00+00:00', 'avg': 70.0, 'min': 60.0, 'max': 90.0, 'count': 40},
      ],
      'summary': {'avg': 73, 'min': 61, 'max': 94},
      'trend': 'steady',
      'data_status': {
        'state': 'receiving',
        'minutes_since_last': 5,
        'today': {'count': 144, 'first_at': '06:10', 'last_at': '14:45', 'longest_gap_minutes': 80},
        'week': {'days_with_data': 6, 'avg_per_day': 138},
      },
    });
    expect(dto.summary!.avg, 73);
    expect(dto.summary!.min, 61);
    expect(dto.trend, 'steady');
    expect(dto.dataStatus.state, 'receiving');
    expect(dto.dataStatus.todayCount, 144);
    expect(dto.dataStatus.longestGapMinutes, 80);
    expect(dto.dataStatus.weekDaysWithData, 6);
    // an old backend without the new keys still renders
    final old = LifestyleHealthHrDto.fromJson({'range_key': '7d', 'history': []});
    expect(old.summary, isNull);
    expect(old.trend, 'insufficient');
    expect(old.dataStatus.state, 'never');
  });

  test('every Health string exists in fa/en/ar and never claims a diagnosis', () {
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      for (final s in [
        l.hrDataStatusTitle, l.hrStateTitle('receiving'), l.hrStateTitle('quiet'), l.hrStateTitle('stale'),
        l.hrStateTitle('never'), l.hrLastReceivedAgo(5), l.hrLastReceivedAgo(200), l.hrLastReceivedAgo(3000),
        l.hrReadingsReceived, l.hrFirstAndLast, l.hrLongestGap, l.hrDuration(80), l.hrThisWeek, l.hrDaysWithData,
        l.hrOutOfSeven(6), l.hrAvgPerDay, l.hrGapHint, l.hrOnlyHeartRate, l.manageDevice, l.hrSummaryAvg,
        l.hrChartTitleDaily, l.hrChartTitleWeekly, l.hrChartLabel, l.hrTrendNote('up'), l.hrTrendNote('down'),
        l.hrTrendNote('steady'), l.hrMemoryNote, l.hrAvgChip(72),
      ]) {
        expect(s, isNotEmpty, reason: lang);
        expect(s.toLowerCase().contains('diagnos'), isFalse, reason: lang);
        expect(s.contains('سدی'), isFalse, reason: lang);
      }
      expect(l.hrTrendNote('insufficient'), isEmpty, reason: lang);
    }
    expect(LifestyleL10n('fa').hrDuration(80), '1 ساعت و 20 دقیقه');
  });

  test('the page draws the chart and status card from the backend, with no thresholds', () {
    final page = _read('lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart');
    expect(page.contains('HrChart('), isTrue);
    expect(page.contains('_dataStatusCard'), isTrue);
    expect(page.contains('LifestyleHrStatusPage('), isTrue);
    expect(page.contains('isDeviceReportedStatus'), isTrue);
    expect(page.contains('>100'), isFalse);
    expect(page.contains('<60'), isFalse);
    final chart = _read('lib/features/lifestyle/presentation/widgets/hr_chart.dart');
    expect(chart.contains('CustomPaint'), isTrue);
    expect(chart.contains('fl_chart'), isFalse);
    expect(chart.contains('dangerRed'), isFalse); // no colour judges a value
    final status = _read('lib/features/lifestyle/presentation/pages/lifestyle_hr_status_page.dart');
    expect(status.contains('DevicesPage'), isTrue);
  });

  test('the memory day view carries the HR average chip', () {
    final chips = MemorySummaryChips.fromJson({'hr_avg': 72, 'topics': <String>[]});
    expect(chips.hrAvg, 72);
    expect(chips.isEmpty, isFalse);
    expect(MemorySummaryChips.fromJson({}).isEmpty, isTrue);
    final day = _read('lib/features/lifestyle/presentation/pages/memory_day_page.dart');
    expect(day.contains('l10n.hrAvgChip(day.chips.hrAvg)'), isTrue);
  });
}
