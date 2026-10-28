import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

/// P8 (Javad 2026-10-28): the Nutrition / Exercise plan can be set up and changed inside the page, and the plan
/// follow-up notification asks "did you do it?" - answers land in the existing I8 review / I10 ledger.
void main() {
  test('setup sheet composes a natural user message in every language', () {
    final fa = LifestyleL10n('fa').composeSetupMessage(
      nutrition: true,
      goalKey: 'sugar',
      count: 4,
      avoid: const ['fish', 'dairy'],
      extra: 'تند',
    );
    expect(fa.contains('برنامه غذایی'), isTrue);
    expect(fa.contains('کنترل قند خون'), isTrue);
    expect(fa.contains('ماهی'), isTrue);
    expect(fa.contains('تند'), isTrue);
    expect(fa.contains('سدی'), isFalse);

    final en = LifestyleL10n('en').composeSetupMessage(
      nutrition: false,
      goalKey: 'strength',
      count: 3,
      avoid: const [],
    );
    expect(en, 'Please build me a weekly exercise plan. My goal: Get stronger. I can exercise 3 days a week.');

    final ar = LifestyleL10n('ar').composeSetupMessage(
      nutrition: true,
      goalKey: 'weight',
      count: 3,
      avoid: const [],
    );
    expect(ar.contains('خطة تغذية'), isTrue);
    expect(LifestyleL10n('fa').alternativeMessage('املت').contains('«املت»'), isTrue);
  });

  test('plan strings exist in fa/en/ar', () {
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      for (final s in [
        l.planSetupButton, l.allWeekHeading, l.planSetupTitle(true), l.planSetupTitle(false), l.planSetupIntro,
        l.knownFactsTitle, l.goalQuestion, l.planGoalLabel('sugar'), l.mealsQuestion, l.mealsOption(4),
        l.daysQuestion, l.daysOption(3), l.avoidQuestion, l.avoidLabel('fish'), l.otherThingHint,
        l.buildPlanButton, l.itemMoveTime, l.itemSkipToday, l.itemRemove, l.itemRemoveQuestion, l.itemAskAlternative,
      ]) {
        expect(s, isNotEmpty, reason: lang);
      }
    }
  });

  test('the plan page edits items through the I8 owner and hands setup to the canonical chat', () {
    final view = _read('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart');
    expect(view.contains('showPlanSetupSheet'), isTrue);
    expect(view.contains('showPlanItemSheet'), isTrue);
    expect(view.contains('_svc.moveAction'), isTrue);
    expect(view.contains('_svc.removeAction'), isTrue);
    expect(view.contains('Gate3UserMessageBus.instance.publish'), isTrue);
    expect(view.contains('DateTime.now()'), isFalse);
    final svc = _read('lib/services/lifestyle/lifestyle_weekly_plan_service.dart');
    expect(svc.contains("'/lifestyle/actions/\$actionId'"), isTrue);
    expect(svc.contains("'local_time': localTime"), isTrue);
    final chat = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
    expect(chat.contains('Gate3UserMessageBus.instance.stream.listen'), isTrue);
    expect(chat.contains('_controller.sendUserMessage(text)'), isTrue);
    expect(chat.contains('_userMessageSub?.cancel()'), isTrue);
  });

  test('skip reasons offered by the item sheet are the bounded backend reasons', () {
    final sheets = _read('lib/features/lifestyle/presentation/widgets/lifestyle_plan_sheets.dart');
    for (final r in ['no_time', 'dont_like', 'not_feeling_well', 'forgot']) {
      expect(sheets.contains("'$r'"), isTrue, reason: r);
    }
  });

  test('tray plan follow-up buttons are understood by the background handler', () {
    final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
    expect(bg.contains("planNotDoneAction = 'plan_not_done'"), isTrue);
    expect(bg.contains('planNotDoneReasons'), isTrue);
    expect(bg.contains('_handlePlanReasonAnswer'), isTrue);
  });

  test('P8b: alternatives, replace and corrections happen in the page and Sedi is told through the backend', () {
    final svc = _read('lib/services/lifestyle/lifestyle_weekly_plan_service.dart');
    expect(svc.contains("'/lifestyle/actions/\$actionId/alternatives'"), isTrue);
    expect(svc.contains("'/lifestyle/actions/\$actionId/replace'"), isTrue);
    expect(svc.contains("'item_id': itemId"), isTrue);
    expect(svc.contains("'duration_minutes': durationMinutes"), isTrue);
    final view = _read('lib/features/lifestyle/presentation/widgets/lifestyle_weekly_plan_view.dart');
    expect(view.contains('_svc.fetchAlternatives'), isTrue);
    expect(view.contains('_svc.replaceAction'), isTrue);
    expect(view.contains('_svc.editAction'), isTrue);
    expect(view.contains('showPlanItemEditSheet'), isTrue);
    expect(view.contains('planChangedSnack'), isTrue);
    final sheets = _read('lib/features/lifestyle/presentation/widgets/lifestyle_plan_sheets.dart');
    expect(sheets.contains("PlanItemChoice('replace', picked)"), isTrue);
    expect(sheets.contains('loadAlternatives'), isTrue);
    for (final lang in ['fa', 'en', 'ar']) {
      final l = LifestyleL10n(lang);
      for (final t in [
        l.alternativesTitle, l.alternativesEmpty, l.applyChange, l.itemEdit, l.editTitleHint, l.editNoteHint,
        l.editDurationHint, l.planChangedSnack,
      ]) {
        expect(t, isNotEmpty, reason: lang);
      }
    }
  });
}
