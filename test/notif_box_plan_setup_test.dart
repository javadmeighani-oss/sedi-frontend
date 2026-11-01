import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/notifications/background_notification_action_handler.dart';
import 'package:sedi_app/data/dto/lifestyle/plan_settings_dto.dart';
import 'package:sedi_app/features/lifestyle/presentation/plan_coach_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/widgets/plan_setup_sheet.dart';

String _read(String path) => File(path).readAsStringSync();

/// Javad 2026-11-01: (1) the "why?" of a notification is a visibly separate block; (2) "Next" in step 1 of 3 must never
/// look dead - the missing allergy answer lights up where it belongs; (3) "Professional" is ONE plan, diet and exercise
/// together, named the same on the meal page and the exercise page.
void main() {
  group('the feedback is a separate block inside the same notification', () {
    test('the original text stays first and escaped; the block follows it with rules, side bars and a bold question', () {
      final html = BackgroundNotificationActionHandler.growWithQuestionHtml(
        originalBody: 'امروز چطوری؟ <b>x</b>\nدلم می‌خواست بپرسم.',
        question: 'چرا نپسندیدی؟',
        hint: 'یکی رو بزن تا دفعه‌ی بعد توی وقت بهتری برات بفرستم.',
        rtl: true,
      );
      // dart:convert HtmlEscape (default mode) writes '/' as &#47;
      expect(html.startsWith('امروز چطوری؟ &lt;b&gt;x&lt;&#47;b&gt;'), isTrue, reason: html);
      expect(html.contains('<br>دلم'), isTrue); // a line break stays a line break
      final bodyEnd = html.indexOf('<br><br>');
      expect(bodyEnd, greaterThan(0));
      final block = html.substring(bodyEnd);
      expect(block.contains('&#9472;'), isTrue); // the rule
      expect(block.contains('&#9612;'), isTrue); // the side bar
      expect(block.contains('<b>چرا نپسندیدی؟</b>'), isTrue);
      expect(block.contains('&#8207;'), isTrue); // RTL: lines start on the right
      expect(block.trimRight().endsWith('</font>'), isTrue); // closed by the bottom rule
    });

    test('English has no right-to-left mark; with no stored original the block stands alone', () {
      final html = BackgroundNotificationActionHandler.growWithQuestionHtml(
        originalBody: '   ',
        question: 'Why?',
        hint: 'Pick one so I can send it at a better time.',
      );
      expect(html.contains('&#8207;'), isFalse);
      expect(html.startsWith('<font color="#8FAE3E">'), isTrue);
      expect(html.contains('<b>Why?</b>'), isTrue);
    });

    test('the hint is wrapped on word boundaries so every line carries the bar', () {
      final lines = BackgroundNotificationActionHandler.wrapWords(
        'یکی رو بزن تا دفعه‌ی بعد توی وقت بهتری برات بفرستم و بعد هم یه چیز دیگه',
        34,
      );
      expect(lines.length, greaterThan(1));
      for (final l in lines) {
        expect(l.length, lessThanOrEqualTo(34));
      }
      expect(lines.join(' '), 'یکی رو بزن تا دفعه‌ی بعد توی وقت بهتری برات بفرستم و بعد هم یه چیز دیگه');
      expect(BackgroundNotificationActionHandler.wrapWords('averyveryverylongsingleword', 5), ['averyveryverylongsingleword']);
    });

    test('both tray prompts use the block (HTML big text) and still show before the network', () {
      final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(RegExp('growWithQuestionHtml\\(').allMatches(bg).length, 3); // the definition + the two prompts
      expect(RegExp('htmlFormatBigText: true').allMatches(bg).length, 2);
      expect(bg.contains('final expanded = growWithQuestion('), isFalse);
    });
  });

  group('plan setup: "Next" never looks dead', () {
    test('the missing allergy answer lights up its own block and scrolls to it (no far-away bottom message)', () {
      final sheet = _read('lib/features/lifestyle/presentation/widgets/plan_setup_sheet.dart');
      expect(sheet.contains('void _flagAllergy()'), isTrue);
      expect(sheet.contains('Widget _allergyBlock()'), isTrue);
      expect(sheet.contains('Scrollable.ensureVisible'), isTrue);
      expect(sheet.contains('_notice = _l.allergyNeeded'), isFalse);
      expect(RegExp('_allergyBlock\\(\\)').allMatches(sheet).length, 3); // the definition + the goal step + the simple meal step
    });

    testWidgets('step 1 of 3: Next without the allergy answer stays, says why right under the answer; answering moves on',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final l = PlanCoachL10n('fa');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showPlanSetupSheet(
                  ctx,
                  l10n: l,
                  nutrition: false,
                  initialSettings: const PlanSettingsDto(),
                  onSubmit: (_) async => PlanSetupOutcome.built,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.modePro));
      await tester.pumpAndSettle();
      expect(find.text(l.stepOf(0)), findsOneWidget);

      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.allergyNeeded), findsOneWidget); // once, inline - not a second line at the bottom
      expect(find.text(l.stepOf(0)), findsOneWidget); // still step 1

      await tester.tap(find.text(l.noAllergy));
      await tester.pumpAndSettle();
      expect(find.text(l.allergyNeeded), findsNothing);
      await tester.tap(find.text(l.next));
      await tester.pumpAndSettle();
      expect(find.text(l.stepOf(1)), findsOneWidget);
    });
  });

  group('"Professional" is one plan: diet and exercise together', () {
    test('the same professional choice on both pages; the simple choice names its own page', () {
      for (final lang in ['fa', 'ar', 'en']) {
        final l = PlanCoachL10n(lang);
        expect(l.modePro.trim(), isNotEmpty, reason: lang);
        expect(l.modeProHint.trim(), isNotEmpty, reason: lang);
        expect(l.modeSimpleFor(true), isNot(l.modeSimpleFor(false)), reason: lang);
        expect(l.openOtherPlan(true), isNot(l.openOtherPlan(false)), reason: lang);
        expect(l.proBuiltOk(true), isNot(l.proBuiltOk(false)), reason: lang);
        for (final s in [l.modePro, l.modeProHint, l.modeSimpleFor(true), l.modeSimpleFor(false), l.proBuiltOk(true), l.openOtherPlan(false)]) {
          expect(s.contains('سدی'), isFalse, reason: lang);
        }
      }
      final fa = PlanCoachL10n('fa');
      expect(fa.modePro, 'حرفه‌ای · رژیم غذایی و ورزش با هم');
      expect(fa.modeSimpleFor(true), 'ساده · برنامه‌ی غذایی');
      expect(fa.modeSimpleFor(false), 'ساده · برنامه‌ی ورزشی');
      expect(fa.modePro.contains('با رژیم غذایی'), isFalse); // the old, meaningless-on-the-meal-page wording
    });

    test('after a professional build the page says both plans exist and opens the other page in one tap', () {
      final view = _read('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart');
      expect(view.contains('_lastSetupWasPro = input.mode == \'pro\''), isTrue);
      expect(view.contains('coach.proBuiltOk(_isNutrition)'), isTrue);
      expect(view.contains('SnackBarAction('), isTrue);
      expect(view.contains('coach.openOtherPlan(_isNutrition)'), isTrue);
      expect(view.contains('_isNutrition ? LifestyleWeeklyDomain.exercise : LifestyleWeeklyDomain.nutrition'), isTrue);
      // the mode cards use the page-aware texts
      final sheet = _read('lib/features/lifestyle/presentation/widgets/plan_setup_sheet.dart');
      expect(sheet.contains('_l.modeSimpleFor(widget.nutrition)'), isTrue);
      expect(sheet.contains('title: _l.modePro'), isTrue);
    });
  });
}
