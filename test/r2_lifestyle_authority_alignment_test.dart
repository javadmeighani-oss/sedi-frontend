import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/services/lifestyle/lifestyle_health_service.dart';

void main() {
  test('HR DTO requires DEVICE_REPORTED + STABLE|UNSTABLE', () {
    final madOnly = LifestyleHealthHrDto.fromJson({
      'hr_status': 'STABLE',
      'range_key': '7d',
    });
    expect(madOnly.isDeviceReportedStatus, isFalse);

    final device = LifestyleHealthHrDto.fromJson({
      'hr_status': 'STABLE',
      'hr_status_source': 'DEVICE_REPORTED',
      'range_key': '7d',
    });
    expect(device.isDeviceReportedStatus, isTrue);

    final invalid = LifestyleHealthHrDto.fromJson({
      'hr_status': 'INSUFFICIENT_DATA',
      'hr_status_source': 'DEVICE_REPORTED',
      'range_key': '7d',
    });
    expect(invalid.isDeviceReportedStatus, isFalse);
  });

  test('Lifestyle Health page gates status UI on device-reported provenance', () {
    final health = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    ).readAsStringSync();
    expect(health.contains('isDeviceReportedStatus'), isTrue);
    expect(health.contains('_statusBlock'), isTrue);
    // Must not apply BPM thresholds in Lifestyle Health.
    expect(health.contains('heart_rate_threshold'), isFalse);
    expect(health.contains('>100'), isFalse);
    expect(health.contains('<60'), isFalse);
  });

  test('History uses JWT-only memory endpoints and clears cached rows on reload',
      () {
    final hist = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart',
    ).readAsStringSync();
    expect(hist.contains('/memory/history'), isTrue);
    expect(hist.contains('/memory/period-summary'), isFalse); // the summaries card was removed (pilot V1)
    expect(hist.contains("'user_id'"), isFalse);
    expect(hist.contains('queryParams: {'), isTrue);
    expect(hist.contains('_history = null'), isTrue);
  });

  test('Nutrition/Exercise render backend weekly-plan only (no fake planner)', () {
    final view = File(
      'lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart',
    ).readAsStringSync();
    final svc = File('lib/services/lifestyle/lifestyle_weekly_plan_service.dart')
        .readAsStringSync();
    expect(view.contains('LifestyleWeeklyPlanService'), isTrue);
    expect(svc.contains('/lifestyle/weekly-plan'), isTrue);
    expect(view.contains('openLifestyleChat'), isTrue);
    expect(view.toLowerCase().contains('fake'), isFalse);
    expect(view.contains("'Mon'"), isFalse);
  });
}
