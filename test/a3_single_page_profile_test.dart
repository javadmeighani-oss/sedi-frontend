import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sedi_app/core/locale/calendar_date_math.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/data/dto/auth/me_profile.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/pages/gate3_profile_page.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart';

void main() {
  test('1 profile has user info, summary, and one logout button label', () {
    final en = Gate3Localization('en');
    final labels = [
      en.userInformationSection,
      en.userSummarySection,
      en.logoutApp,
    ];
    expect(labels.toSet().length, 3);
    expect(labels.any((s) => s.toLowerCase().contains('what sedi')), isFalse);
    expect(Gate3Localization('fa').logoutApp, 'خروج از برنامه');
  });

  test('2/3 /auth/me field labels include preferred language', () {
    final l10n = Gate3Localization('en');
    expect(l10n.profileNameLabel, isNotEmpty);
    expect(l10n.profileDobLabel, isNotEmpty);
    expect(l10n.profileSexLabel, isNotEmpty);
    expect(l10n.profileLanguageLabel.toLowerCase(), contains('language'));
    expect(l10n.profilePhoneLabel, isNotEmpty);
  });

  test('profile DOB/sex presentation localization EN/FA/AR', () {
    expect(
      CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'en'),
      '1990-05-15',
    );
    final fa = CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'fa');
    expect(RegExp(r'[۰-۹]').hasMatch(fa), isTrue);
    expect(RegExp(r'[0-9]').hasMatch(fa), isFalse);
    final ar = CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'ar');
    expect(RegExp(r'[٠-٩]').hasMatch(ar), isTrue);
    expect(Gate3Localization('en').profileSexValue('male'), 'Male');
    expect(Gate3Localization('fa').profileSexValue('female'), 'زن');
    expect(Gate3Localization('fa').profileSexValue('other'), 'سایر');
    expect(Gate3Localization('ar').profileSexValue('male'), 'ذكر');
    final profile = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    expect(profile.contains('formatIsoForProfileDisplay'), isTrue);
    expect(profile.contains('profileSexValue'), isTrue);
  });

  test('4 phone OTP strings preserved', () {
    final l10n = Gate3Localization('en');
    expect(l10n.changePhone, isNotEmpty);
    expect(l10n.sendPhoneOtp, isNotEmpty);
    expect(l10n.verifyPhoneOtp, isNotEmpty);
    expect(l10n.phoneChangeSuccess, isNotEmpty);
  });

  test('5 I7 known-facts absent from profile page source', () {
    final src = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    expect(src.contains('/user/me/known-facts'), isFalse);
    expect(src.contains('whatSediKnows'), isFalse);
    expect(src.contains('profile-summary'), isTrue);
    expect(src.contains('AuthHelper.performLogout'), isTrue);
  });

  test('profile phone card keeps Change Phone and Gate2OtpInput inside', () {
    final src = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    expect(src.contains('Gate2OtpInput'), isTrue);
    expect(src.contains('_phoneCard'), isTrue);
    expect(src.contains('changePhone'), isTrue);
    final phoneCardIdx = src.indexOf('Widget _phoneCard');
    final changeIdx = src.indexOf('l10n.changePhone', phoneCardIdx);
    expect(phoneCardIdx, greaterThan(0));
    expect(changeIdx, greaterThan(phoneCardIdx));
  });

  test('6 summary table maps backend projection keys/status', () {
    final l10n = Gate3Localization('en');
    expect(l10n.summaryRowLabel('memory_consent'), isNotEmpty);
    expect(l10n.summaryStatusLabel('granted'), isNotEmpty);
    expect(l10n.summaryStatusLabel('in_progress'), isNotEmpty);
  });

  test('profile summary shows empty state, not status rows', () {
    const payload = {
      'rows': [
        {'key': 'memory_consent', 'status': 'granted'},
        {'key': 'memory_write', 'status': 'allowed'},
        {'key': 'memory_read', 'status': 'allowed'},
        {'key': 'daily_plan', 'status': 'active'},
        {'key': 'plan_actions', 'status': 'in_progress'},
      ],
    };
    expect(canonicalProfileSummaryText(payload), isEmpty);
    expect(canonicalProfileSummaryText(null), isEmpty);
    expect(canonicalProfileSummaryText(<String, Object>{}), isEmpty);
    expect(
      canonicalProfileSummaryText({
        'rows': [],
        'facts': [
          {'key': 'health_concerns', 'value': 'دیابت'},
        ],
        'summary': '  جواد، تا اینجا این‌طور می‌شناسمت: وضعیت سلامتت: دیابت.  ',
      }),
      'جواد، تا اینجا این‌طور می‌شناسمت: وضعیت سلامتت: دیابت.',
    );
    // structured facts alone are never shown as the card text
    expect(
      canonicalProfileSummaryText({
        'facts': [
          {'key': 'interests', 'value': 'x'},
        ],
      }),
      isEmpty,
    );

    final src = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    expect(src.contains('userSummaryEmpty'), isTrue);
    expect(src.contains('summaryRowLabel'), isFalse);
    expect(src.contains('summaryStatusLabel'), isFalse);
    expect(src.contains('_summaryRow'), isFalse);
    expect(
      Gate3Localization('fa').userSummaryEmpty,
      'در حال حاضر، اطلاعات کافی از شما در حافظه صدی ثبت نشده است. با ادامه گفت‌وگو و استفاده از صدی، این بخش به‌تدریج کامل‌تر می‌شود.',
    );
    expect(Gate3Localization('en').userSummaryEmpty, isNotEmpty);
    expect(Gate3Localization('ar').userSummaryEmpty, isNotEmpty);
  });

  test('7 no technical IDs / Sedi ID / I9 in profile l10n surface', () {
    final l10n = Gate3Localization('en');
    final blob = [
      l10n.profileTitle,
      l10n.userInformationSection,
      l10n.userSummarySection,
      l10n.logoutApp,
      l10n.summaryRowLabel('daily_plan'),
    ].join(' ').toLowerCase();
    expect(blob.contains('sedi id'), isFalse);
    expect(blob.contains('health_subject'), isFalse);
    expect(blob.contains('heart-rate'), isFalse);
    expect(blob.contains('unstable'), isFalse);
  });

  testWidgets('8/9 logout at bottom contract + direct profile navigation',
      (tester) async {
    final src = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    final summaryCallIdx = src.indexOf('_buildSummaryCard(l10n)');
    final logoutCallIdx =
        src.indexOf('AuthHelper.performLogout(context: context)');
    expect(summaryCallIdx, greaterThanOrEqualTo(0));
    expect(logoutCallIdx, greaterThanOrEqualTo(0));
    expect(logoutCallIdx, greaterThan(summaryCallIdx));

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
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline));
    // Do not pumpAndSettle — Profile _load hits network and would hang.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(Gate3ProfilePage), findsOneWidget);
  });

  test('10 en/fa/ar + RTL/LTR', () {
    expect(Gate3Localization('en').isRtl, isFalse);
    expect(Gate3Localization('fa').isRtl, isTrue);
    expect(Gate3Localization('ar').isRtl, isTrue);
    expect(Gate3Localization('fa').userInformationSection, isNotEmpty);
    expect(Gate3Localization('ar').userSummarySection, isNotEmpty);
    expect(Gate3Localization('en').logoutApp, 'Log out of app');
  });

  test('MeProfileDto preferred_language parse regression', () {
    final me = MeProfileDto.fromJson({
      'user_id': 1,
      'name': 'Ada',
      'preferred_language': 'fa',
      'phone': '+15551212',
      'sex': 'female',
    });
    expect(me.preferredLanguage, 'fa');
    expect(me.name, 'Ada');
    SediLocaleController.instance.reconcileFromBackendConfirmed('fa');
    expect(SediLocaleController.instance.languageCode, 'fa');
  });
}
