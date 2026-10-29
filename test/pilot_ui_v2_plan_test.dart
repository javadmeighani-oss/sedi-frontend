import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/lifestyle/plan_settings_dto.dart';
import 'package:sedi_app/features/lifestyle/presentation/plan_coach_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/plan_dish_art.dart';

String _read(String path) => File(path).readAsStringSync();

/// Pilot V1 screen 6 (R-034 / R-035, Javad 2026-10-29): the plan page is a coach - week strip, day timeline with vector
/// dishes, a three-step setup that builds the plan right there, and a weekly review from what the user marked.
void main() {
  final view = _read('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart');
  final sheet = _read('lib/features/lifestyle/presentation/widgets/plan_setup_sheet.dart');
  final svc = _read('lib/services/lifestyle/lifestyle_weekly_plan_service.dart');

  test('the sphere sits on the start side of the title (R-035) and the page is liquid glass', () {
    expect(view.indexOf('const SediHologramOrb('), lessThan(view.indexOf(RegExp(r'Text\(\s*title,'))));
    expect(view.contains('SediSceneBackdrop()'), isTrue);
    expect(view.contains('SediGlass.card'), isTrue);
    expect(view.contains('textAlign: TextAlign.justify'), isTrue);
  });

  test('the page shows the coach, a week strip, the day timeline with dishes and the review', () {
    for (final s in ['_coachCard(', '_weekStrip(', '_dayTimeline(', '_mealRow(', '_reviewCard(', 'PlanDishArt(']) {
      expect(view.contains(s), isTrue, reason: s);
    }
    expect(view.contains('_svc.fetchWeeklyReview'), isTrue);
    expect(view.contains('_svc.fetchPlanSettings'), isTrue);
    expect(view.contains('DateTime.now()'), isFalse);
  });

  test('setup builds the plan here with the backend composer, never a frontend planner', () {
    expect(view.contains('showPlanSetupSheet('), isTrue);
    expect(view.contains('_svc.buildPlan(input)'), isTrue);
    expect(view.contains("'NEEDS_INFO'"), isTrue);
    expect(svc.contains("'/lifestyle/plan/build'"), isTrue);
    expect(svc.contains("'/lifestyle/plan-settings'"), isTrue);
    expect(svc.contains("'/lifestyle/weekly-review'"), isTrue);
    expect(sheet.contains('onSubmit'), isTrue);
    expect(view.contains('generatePlan'), isFalse);
  });

  test('the setup is three calm steps and meals need the allergy answer first', () {
    expect(sheet.contains('_step == 0'), isTrue);
    expect(sheet.contains('last = _step == 2'), isTrue);
    expect(sheet.contains('_allergyOk'), isTrue);
    expect(sheet.contains('allergyNeeded'), isTrue);
    expect(sheet.contains('onSubmit(input)'), isTrue);
  });

  test('settings round trip through the DTO and keep the lead null = off', () {
    final s = PlanSettingsDto.fromJson({
      'days': [1, 3, 5],
      'lead': null,
      'review_weekday': 7,
      'review_time': '09:30',
    });
    expect(s.days, [1, 3, 5]);
    expect(s.lead, isNull);
    expect(s.reviewWeekday, 7);
    expect(s.toJson()['lead'], isNull);
    expect(s.copyWith(lead: 15).lead, 15);
    expect(s.copyWith(clearLead: true).lead, isNull);
    expect(const PlanSettingsDto().reviewWeekday, 5); // Friday is the Persian default; the backend sends the real one

    final input = PlanSetupInput(
      domain: 'nutrition',
      goal: ' ورزش ',
      noAllergies: true,
      mealTimes: const {'lunch': '13:00'},
      settings: s,
    ).toJson();
    expect(input['goal'], 'ورزش');
    expect(input['no_allergies'], true);
    expect(input.containsKey('avoid'), isFalse);
    expect((input['settings'] as Map)['review_time'], '09:30');
  });

  test('review and build results parse without inventing anything', () {
    final r = WeeklyReviewDto.fromJson({'state': 'empty'});
    expect(r.hasStory, isFalse);
    final ready = WeeklyReviewDto.fromJson({
      'state': 'ready',
      'done': 5,
      'total': 9,
      'percent': 56,
      'best_weekday': 3,
      'delta': -4,
      'message': 'x',
    });
    expect(ready.hasStory, isTrue);
    expect(ready.bestWeekday, 3);
    expect(PlanBuildResultDto.fromJson({'status': 'NEEDS_INFO', 'needs': ['allergies']}).needs, ['allergies']);
    expect(PlanBuildResultDto.fromJson({'status': 'BUILT', 'created': 28}).built, isTrue);
  });

  test('coach strings exist in fa / ar / en and never use the wrong brand spelling', () {
    for (final lang in ['fa', 'ar', 'en']) {
      final l = PlanCoachL10n(lang);
      final strings = <String>[
        l.coachEmpty(true),
        l.coachEmpty(false),
        l.coachToday(1, 4),
        l.coachNothingToday,
        l.coachReviewDue,
        l.setupButton,
        l.buildNow,
        l.reviewTitle,
        l.reviewCount(3, 9),
        l.reviewBest('x'),
        l.reviewDelta(5),
        l.reviewDelta(-5),
        l.reviewChatMessage,
        l.stepTitle(0, true),
        l.stepTitle(1, false),
        l.stepTitle(2, true),
        l.stepOf(1),
        l.allergyNeeded,
        l.leadLabel(null),
        l.leadLabel(0),
        l.leadLabel(15),
        l.reviewDayQuestion,
        l.buildAndSave,
        l.buildOk,
        l.buildFailed,
        l.consentNeeded,
      ];
      for (final s in strings) {
        expect(s.trim(), isNotEmpty, reason: lang);
        expect(s.contains('سدی'), isFalse, reason: '$lang $s');
      }
    }
    expect(PlanCoachL10n('fa').isRtl, isTrue);
    expect(PlanCoachL10n('en').isRtl, isFalse);
  });

  test('the illustration key follows the meal slot or the activity', () {
    expect(PlanDishArt.kindFor(mealSlot: 'Lunch'), 'lunch');
    expect(PlanDishArt.kindFor(activityType: 'light_walk'), 'walk');
    expect(PlanDishArt.kindFor(activityType: 'band_strength'), 'strength');
    expect(PlanDishArt.kindFor(activityType: 'rest'), 'rest');
    expect(PlanDishArt.kindFor(), 'exercise');
  });

  testWidgets('every illustration paints without errors', (tester) async {
    const kinds = ['breakfast', 'lunch', 'dinner', 'snack', 'walk', 'strength', 'stretch', 'rest', 'exercise'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(children: [for (final k in kinds) PlanDishArt(kind: k, size: 60)]),
        ),
      ),
    );
    expect(find.byType(PlanDishArt), findsNWidgets(kinds.length));
    expect(tester.takeException(), isNull);
  });
}
