import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/calendar_date_math.dart';
import 'package:sedi_app/core/theme/app_theme.dart';
import 'package:sedi_app/data/dto/lifestyle/lifestyle_weekly_plan_dto.dart';
import 'package:sedi_app/features/auth_otp/presentation/birth_calendar_helper.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_health_page.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_page.dart';

void main() {
  test('1 lifestyle has exactly 5 primary sections', () {
    final l10n = LifestyleL10n('en');
    expect(l10n.sectionTitles.length, 5);
    expect(l10n.sectionTitles.toSet().length, 5);
  });

  test('2/3 health top icon removed; profile/lifestyle/gadgets/notifications present',
      () {
    final src = File(
      'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
    ).readAsStringSync();
    expect(src.contains('onHealthCare'), isFalse);
    expect(src.contains('healthCare'), isFalse);
    expect(src.contains('onNotifications'), isTrue);
    expect(src.contains('onLifestyle'), isTrue);
    expect(src.contains('onGadgets'), isTrue);
    expect(src.contains('Gate3ProfilePage'), isTrue);
  });

  test('4 AppTheme status tokens exist (no red for I9 change)', () {
    expect(AppTheme.statusStableOlive, isNot(AppTheme.dangerRed));
    expect(AppTheme.statusChangeAmber, isNot(AppTheme.dangerRed));
    expect(AppTheme.statusNeutralMuted, isNot(AppTheme.dangerRed));
  });

  test('5 en/fa/ar + RTL/LTR', () {
    expect(LifestyleL10n('en').isRtl, isFalse);
    expect(LifestyleL10n('fa').isRtl, isTrue);
    expect(LifestyleL10n('ar').isRtl, isTrue);
    expect(LifestyleL10n('fa').health, isNotEmpty);
    expect(LifestyleL10n('ar').mySchedule, isNotEmpty);
  });

  test('6/7/8 DEVICE_REPORTED status mapping — amber not red for UNSTABLE', () {
    final l10n = LifestyleL10n('en');
    expect(l10n.deviceReportedHrStatusLabel('STABLE'), contains('Stable'));
    expect(l10n.deviceReportedHrStatusLabel('UNSTABLE'), contains('Unstable'));
    expect(l10n.hrStatusLabel('UNSTABLE_OR_CHANGED'), contains('Change'));
    expect(l10n.hrStatusLabel('INSUFFICIENT_DATA'), contains('Not enough'));
    final healthSrc = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    ).readAsStringSync();
    expect(healthSrc.contains('isDeviceReportedStatus'), isTrue);
    expect(healthSrc.contains('statusChangeAmber'), isTrue);
    expect(healthSrc.contains('statusStableOlive'), isTrue);
    // Device-reported UNSTABLE must not use dangerRed in status mapping.
    final statusFn = RegExp(
      r'Color _statusColor[\s\S]*?default:\s*return AppTheme\.statusNeutralMuted;',
    ).firstMatch(healthSrc)?.group(0);
    expect(statusFn, isNotNull);
    expect(statusFn!.contains('dangerRed'), isFalse);
    expect(statusFn.contains("'UNSTABLE'"), isTrue);
  });

  test('9/10 health page uses backend projection + ranges', () {
    final src = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    ).readAsStringSync();
    expect(src.contains('LifestyleHealthService'), isTrue);
    expect(src.contains("'7d'"), isTrue);
    expect(src.contains("'30d'"), isTrue);
    expect(src.contains("'3m'"), isTrue);
    expect(src.contains("'1y'"), isTrue);
    expect(src.contains('latest_value') || src.contains('latestValue'), isTrue);
  });

  test('11/12 history retention + summary UI', () {
    final src = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart',
    ).readAsStringSync();
    expect(src.contains('/memory/history'), isTrue);
    expect(src.contains('/memory/period-summary'), isTrue);
    expect(src.contains('daily'), isTrue);
    expect(src.contains('weekly'), isTrue);
    expect(src.contains('monthly'), isTrue);
    expect(src.contains('yearly'), isTrue);
    expect(src.contains('historyExplain'), isTrue);
  });

  test('13/14 schedule grouping + reminder PATCH', () {
    final src = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_schedule_page.dart',
    ).readAsStringSync();
    // R-031: today first (with a "next" bar), then what is coming up; reminder presets (incl. 1440) live in the sheets.
    expect(src.contains('today'), isTrue);
    expect(src.contains('buildUpcoming'), isTrue);
    expect(src.contains('patchReminder'), isTrue);
    final sheets = File(
      'lib/features/lifestyle/presentation/widgets/schedule_reminder_sheets.dart',
    ).readAsStringSync();
    expect(sheets.contains('1440'), isTrue);
  });

  test('15/16 nutrition + exercise weekly plan projection (no fake content)', () {
    final n = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_nutrition_page.dart',
    ).readAsStringSync();
    final e = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_exercise_page.dart',
    ).readAsStringSync();
    final view = File(
      'lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart',
    ).readAsStringSync();
    final svc = File(
      'lib/services/lifestyle/lifestyle_weekly_plan_service.dart',
    ).readAsStringSync();
    expect(n.contains('LifestyleWeeklyPlanView'), isTrue);
    expect(n.contains('LifestyleWeeklyDomain.nutrition'), isTrue);
    expect(e.contains('LifestyleWeeklyPlanView'), isTrue);
    expect(e.contains('LifestyleWeeklyDomain.exercise'), isTrue);
    expect(view.contains('LifestyleWeeklyPlanService'), isTrue);
    expect(view.contains('openLifestyleChat'), isTrue);
    expect(view.contains('noNutrition'), isTrue);
    expect(view.contains('noExercise'), isTrue);
    expect(view.contains("'Mon'"), isFalse);
    expect(view.contains("'Tue'"), isFalse);
    expect(svc.contains('/lifestyle/weekly-plan'), isTrue);
    // One shared service path — no domain-specific weekly services.
    expect(
      Directory('lib/services/lifestyle')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => p.contains('weekly'))
          .length,
      1,
    );
  });

  test('17 no frontend clinical/plan inference markers', () {
    final hub = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
    ).readAsStringSync();
    expect(hub.toLowerCase().contains('medically safe'), isFalse);
    expect(hub.toLowerCase().contains('diagnosis'), isFalse);
    final health = File(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    ).readAsStringSync();
    expect(health.contains('deviceReportedHrStatusLabel'), isTrue);
    expect(health.contains('isDeviceReportedStatus'), isTrue);
  });

  test('18 weekly DTO parse + domain split + states (CI coverage)', () {
    final dto = LifestyleWeeklyPlanDto.fromJson({
      'cycle_start': '2026-03-10',
      'cycle_end': '2026-03-16',
      'timezone': 'Asia/Tehran',
      'state': 'active',
      'review_due': false,
      'days': [
        {
          'local_date': '2026-03-10',
          'day_index': 1,
          'nutrition': [
            {
              'title': 'Oats',
              'status': 'ACTIVE',
              'meal_slot': 'breakfast',
              'local_time': '08:00',
            }
          ],
          'exercise': [
            {
              'title': 'Walk',
              'status': 'ACTIVE',
              'duration_minutes': 30,
              'local_time': '18:00',
            }
          ],
        },
      ],
    });
    expect(dto.state, 'active');
    expect(dto.days.single.nutrition.single.title, 'Oats');
    expect(dto.days.single.exercise.single.durationMinutes, 30);
    for (final state in ['empty', 'review_due', 'unavailable']) {
      expect(
        LifestyleWeeklyPlanDto.fromJson({'state': state, 'days': []}).state,
        state,
      );
    }
    final view = File(
      'lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart',
    ).readAsStringSync();
    expect(view.contains("'active'"), isTrue);
    expect(view.contains("'empty'"), isTrue);
    expect(view.contains("'review_due'"), isTrue);
    expect(view.contains("'unavailable'"), isTrue);
  });

  test('19 locale calendars + weekday + composer draft (CI coverage)', () {
    expect(LifestyleL10n('en').isRtl, isFalse);
    expect(LifestyleL10n('fa').isRtl, isTrue);
    expect(LifestyleL10n('ar').isRtl, isTrue);
    expect(LifestyleL10n('en').weekdayShort(1), 'Mon');
    expect(LifestyleL10n('fa').weekdayShort(1), isNot(equals('Mon')));
    expect(CalendarDateMath.formatIsoForLanguage('2026-03-10', 'en'),
        '2026-03-10');
    expect(CalendarDateMath.formatIsoForLanguage('2026-03-10', 'fa'),
        isNot(equals('2026-03-10')));
    expect(CalendarDateMath.formatIsoForLanguage('2026-03-10', 'ar'),
        isNot(equals('2026-03-10')));
    expect(
      BirthCalendarHelper.gregorianToJalali(2026, 3, 10),
      CalendarDateMath.gregorianToJalali(2026, 3, 10),
    );
    final page = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    ).readAsStringSync();
    final composer = File(
      'lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart',
    ).readAsStringSync();
    expect(page.contains('initialDraft'), isTrue);
    expect(page.contains('_composerDraftSeed'), isTrue);
    expect(page.contains('Gate3AssistantStarterBus'), isTrue);
    expect(page.contains('initialMessage: widget.initialMessage'), isTrue);
    final init = RegExp(r'void initState\(\)[\s\S]*?_onTextChanged\(\);')
        .firstMatch(composer)
        ?.group(0);
    expect(init, isNotNull);
    expect(init!.contains('onSendText'), isFalse);
    expect(init.contains('_send'), isFalse);
  });

  testWidgets('top row structure smoke', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3MainIconRow(
            onLifestyle: () {},
            onGadgets: () {},
            onNotifications: () {},
            lang: 'en',
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    expect(find.byType(LifestylePage), findsNothing);
    expect(Gate3Localization('en').notifications, isNotEmpty);
  });
}
