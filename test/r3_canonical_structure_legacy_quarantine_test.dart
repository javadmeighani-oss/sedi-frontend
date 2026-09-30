import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/navigation/app_gate.dart';
import 'package:sedi_app/core/navigation/app_gate_router.dart';
import 'package:sedi_app/features/auth_otp/presentation/pages/otp_login_page.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart';
import 'package:sedi_app/features/intro/presentation/pages/intro_page.dart';

String _read(String relativePath) => File(relativePath).readAsStringSync();

bool _exists(String relativePath) => File(relativePath).existsSync();

/// Production lib paths that must never import deleted legacy product pages.
const _canonicalProductSurfaces = <String>[
  'lib/app.dart',
  'lib/main.dart',
  'lib/core/navigation/app_gate_router.dart',
  'lib/core/navigation/session_gate_resolver.dart',
  'lib/core/auth/auth_helper.dart',
  'lib/core/notifications/notification_bootstrap.dart',
  'lib/features/intro/presentation/pages/intro_page.dart',
  'lib/features/auth_otp/presentation/pages/otp_login_page.dart',
  'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
  'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
  'lib/features/gate3_interactive/presentation/pages/gate3_memory_privacy_page.dart',
  'lib/features/gate3_interactive/presentation/widgets/gate3_settings_menu.dart',
  'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
  'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
  'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
  'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
];

/// Legacy product surfaces that must be ABSENT after hygiene recovery.
const _absentLegacySurfaces = <String>[
  'lib/features/chat/presentation/pages/chat_page.dart',
  'lib/features/chat/presentation/pages/chat_history_page.dart',
  'lib/features/onboarding/presentation/pages/onboarding_page.dart',
  'lib/features/user_verification/presentation/pages/user_verification_page.dart',
  'lib/features/health/presentation/pages/vitals_page.dart',
  'lib/features/health/presentation/pages/heart_rate_page.dart',
  'lib/features/health/presentation/pages/health_alerts_page.dart',
  'lib/features/gate3_interactive/presentation/sections/health_care/gate3_health_care_placeholder.dart',
  'lib/features/gate3_interactive/presentation/sections/gadgets/gate3_gadgets_placeholder.dart',
  'lib/features/gate3_interactive/presentation/sections/lifestyle/gate3_lifestyle_placeholder.dart',
  'lib/features/gate3_interactive/presentation/sections/history/gate3_history_placeholder.dart',
  'lib/features/gate3_interactive/presentation/sections/notifications/gate3_notifications_placeholder.dart',
  'lib/features/gate4_notifications/presentation/pages/gate4_notifications_placeholder_page.dart',
  'lib/features/notification/presentation/pages/notifications_inbox_page.dart',
  'lib/features/chat/chat_service.dart',
];

const _legacyPageImportNeedles = <String>[
  'chat/presentation/pages/chat_page.dart',
  'onboarding/presentation/pages/onboarding_page.dart',
  'user_verification/presentation/pages/user_verification_page.dart',
  'health/presentation/pages/vitals_page.dart',
  'health/presentation/pages/heart_rate_page.dart',
  'health/presentation/pages/health_alerts_page.dart',
  'gate3_health_care_placeholder.dart',
  'package:sedi_app/features/notification/',
  'Gate3NotificationsPlaceholder',
  'Gate4NotificationsPlaceholderPage',
];

void main() {
  test('AppGateRouter product graph is Intro → OtpLogin → Gate3Interactive only',
      () {
    expect(AppGateRouter.buildGatePage(SediAppGate.splash), isA<IntroPage>());
    expect(AppGateRouter.buildGatePage(SediAppGate.login), isA<OtpLoginPage>());
    expect(
      AppGateRouter.buildGatePage(SediAppGate.heart),
      isA<Gate3InteractivePage>(),
    );

    final router = _read('lib/core/navigation/app_gate_router.dart');
    expect(router.contains('IntroPage'), isTrue);
    expect(router.contains('OtpLoginPage'), isTrue);
    expect(router.contains('Gate3InteractivePage'), isTrue);
    expect(router.contains('ChatPage'), isFalse);
    expect(router.contains('OnboardingPage'), isFalse);
    expect(router.contains('UserVerificationPage'), isFalse);
    expect(router.contains('VitalsPage'), isFalse);
    expect(router.contains('HeartRatePage'), isFalse);

    final app = _read('lib/app.dart');
    expect(app.contains('home: const IntroPage()'), isTrue);
    expect(app.contains('SediLocaleController'), isTrue);
    expect(app.contains('SediLocaleRegistry'), isTrue);
    expect(app.contains('AppTheme'), isTrue);
    expect(app.contains('routes:'), isFalse);
    expect(app.contains('onGenerateRoute'), isFalse);
  });

  test('A3 four-icon structure preserved (Profile|Lifestyle|Gadgets|Notifications)',
      () {
    final row = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
    );
    expect(row.contains('A3 top row: Profile | Lifestyle | Gadgets | Smart Notifications'),
        isTrue);
    expect('Gate3MainIconButton'.allMatches(row).length, 4);
    expect(row.contains('l10n.profileTitle'), isTrue);
    expect(row.contains('l10n.lifestyle'), isTrue);
    expect(row.contains('l10n.gadgets'), isTrue);
    expect(row.contains('l10n.notifications'), isTrue);
    expect(row.contains('Gate3ProfilePage'), isTrue);
    expect(row.contains('onLifestyle'), isTrue);
    expect(row.contains('onGadgets'), isTrue);
    expect(row.contains('onNotifications'), isTrue);
    expect(row.contains('healthCare'), isFalse);
    expect(row.contains('Intelligence'), isFalse);
    expect(row.contains('Icons.favorite'), isFalse);
    expect(row.contains('HeartRatePage'), isFalse);
    expect(row.contains('VitalsPage'), isFalse);
    expect(row.contains('ChatPage'), isFalse);

    final gate3 = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(gate3.contains('LifestylePage'), isTrue);
    expect(gate3.contains('DevicesPage'), isTrue);
    expect(gate3.contains('NotificationInboxPage'), isTrue);
    expect(gate3.contains('ChatPage'), isFalse);
    expect(gate3.contains('VitalsPage'), isFalse);
    expect(gate3.contains('HeartRatePage'), isFalse);
    expect(gate3.contains('OnboardingPage'), isFalse);
  });

  test('canonical Lifestyle Health and Smart Notifications remain reachable', () {
    final lifestyle = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
    );
    expect(lifestyle.contains('LifestyleHealthPage'), isTrue);
    expect(lifestyle.contains('HeartRatePage'), isFalse);
    expect(lifestyle.contains('VitalsPage'), isFalse);

    final health = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_health_page.dart',
    );
    expect(health.contains('LifestyleHealthService'), isTrue);
    expect(health.contains('SediLocaleController'), isTrue);

    final inbox = _read(
      'lib/features/notifications/presentation/pages/notification_inbox_page.dart',
    );
    // A4 final: Inbox recovery actions go through coordinator; no direct A3 nav.
    expect(inbox.contains('AppGateRouter.goToHeart'), isFalse);
    expect(inbox.contains('fromNotification: true'), isFalse);
    expect(inbox.contains('ChatPage'), isFalse);
    expect(inbox.contains('NotificationActionCoordinator'), isTrue);
    expect(inbox.contains('categoryLabel'), isTrue);

    final bootstrap = _read('lib/core/notifications/notification_bootstrap.dart');
    expect(bootstrap.contains('NotificationActionCoordinator'), isTrue);
    expect(bootstrap.contains('ChatPage'), isFalse);
    final coordinator =
        _read('lib/core/notifications/notification_action_coordinator.dart');
    expect(coordinator.contains('AppGateRouter.goToHeart'), isTrue);
    expect(coordinator.contains('fromNotification: true'), isTrue);
  });

  test('logout returns through canonical AppGateRouter login', () {
    final auth = _read('lib/core/auth/auth_helper.dart');
    expect(auth.contains('AppGateRouter.goToLogin'), isTrue);
    expect(auth.contains('UserIdentityService.clearCache'), isTrue);
    expect(auth.contains('ChatPage'), isFalse);
    expect(auth.contains('OnboardingPage'), isFalse);

    final profile = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    );
    expect(profile.contains('AuthHelper.performLogout'), isTrue);
  });

  test('legacy product surfaces are absent and unreachable from canonical graph',
      () {
    for (final path in _absentLegacySurfaces) {
      expect(_exists(path), isFalse, reason: '$path must be deleted');
    }

    for (final path in _canonicalProductSurfaces) {
      final src = _read(path);
      for (final needle in _legacyPageImportNeedles) {
        expect(
          src.contains(needle),
          isFalse,
          reason: '$path must not reference $needle',
        );
      }
      expect(src.contains('ChatPage('), isFalse, reason: path);
      expect(src.contains('OnboardingPage('), isFalse, reason: path);
      expect(src.contains('UserVerificationPage('), isFalse, reason: path);
      expect(src.contains('HeartRatePage('), isFalse, reason: path);
      expect(src.contains('VitalsPage('), isFalse, reason: path);
      expect(src.contains('HealthAlertsPage('), isFalse, reason: path);
    }

    // Production Gate3 must open canonical NotificationInboxPage directly.
    final gate3 = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(gate3.contains('Gate3NotificationsPlaceholder'), isFalse);
    expect(gate3.contains('Gate4NotificationsPlaceholderPage'), isFalse);
    expect(gate3.contains('NotificationsInboxPage'), isFalse);
    expect(gate3.contains('NotificationInboxPage'), isTrue);

    // Singular legacy notification tree must be gone.
    expect(Directory('lib/features/notification').existsSync(), isFalse);
  });

  test('gates.dart / app_gate.dart document Gate3InteractivePage authority', () {
    final gates = _read('lib/core/navigation/gates.dart');
    expect(gates.contains('Gate3InteractivePage'), isTrue);
    expect(gates.contains('→ ChatPage'), isFalse);

    final appGate = _read('lib/core/navigation/app_gate.dart');
    expect(appGate.contains('Gate3InteractivePage'), isTrue);
    expect(appGate.contains('ChatPage'), isFalse);
  });
}
