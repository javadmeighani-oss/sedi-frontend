import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/memory/memory_consent_status.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('B1 session refresh is single-flight and does not logout on transient',
      () {
    final refresh = _read('lib/core/auth/auth_refresh_service.dart');
    expect(refresh.contains('_refreshInProgress'), isFalse);
    expect(refresh.contains('Future<AuthRefreshOutcome>? _inFlight'), isTrue);
    expect(refresh.contains('refreshOnce()'), isTrue);
    expect(refresh.contains('transientFailure'), isTrue);
    expect(refresh.contains('invalidSession'), isTrue);

    final api = _read('lib/core/network/api_client.dart');
    expect(api.contains('AuthRefreshService.refreshOnce()'), isTrue);
    expect(api.contains('AuthRefreshOutcome.transientFailure'), isTrue);

    final gate = _read('lib/core/navigation/session_gate_resolver.dart');
    expect(gate.contains('AuthRefreshOutcome.transientFailure'), isTrue);
    expect(gate.contains('backendUnavailable'), isTrue);
  });

  test('P2 thinking dots stay three and are animated', () {
    final bubble = _read(
      'lib/features/chat/presentation/widgets/message_bubble.dart',
    );
    expect(bubble.contains('class _TypingDots extends StatefulWidget'), isTrue);
    expect(bubble.contains('AnimationController'), isTrue);
    expect(bubble.contains('_dot(0)'), isTrue);
    expect(bubble.contains('_dot(1)'), isTrue);
    expect(bubble.contains('_dot(2)'), isTrue);
    expect(bubble.contains('width: 6'), isTrue);
  });

  testWidgets('P3 user edit affordance is pen icon only', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MessageBubble(
          message: 'Original user text',
          isSedi: false,
          onEdit: () => taps++,
          editLabel: 'Edit',
        ),
      ),
    );
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    expect(taps, 1);

    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(page.contains('_beginEditUserMessage'), isTrue);
    expect(page.contains('updateMessage'), isFalse);
    expect(page.contains('patchMessage'), isFalse);
  });

  test('P5/P6 startup locale is pre-resolved and Firebase is after runApp', () {
    final mainSrc = _read('lib/main.dart');
    expect(mainSrc.contains('bootstrapFromCache()'), isTrue);
    expect(mainSrc.contains('runApp(const SediApp())'), isTrue);
    final runAppIdx = mainSrc.indexOf('runApp(const SediApp())');
    final firebaseIdx = mainSrc.indexOf('Firebase.initializeApp()');
    final localeIdx = mainSrc.indexOf('bootstrapFromCache()');
    expect(localeIdx, greaterThan(-1));
    expect(firebaseIdx, greaterThan(-1));
    expect(localeIdx, lessThan(runAppIdx));
    expect(runAppIdx, lessThan(firebaseIdx));
    expect(mainSrc.contains('unawaited(_bootstrapFirebaseAfterUi())'), isTrue);
    expect(mainSrc.contains('NotificationBootstrap.setup()'), isTrue);

    final app = _read('lib/app.dart');
    expect(app.contains('_bootstrapLocale'), isFalse);
    expect(app.contains('bootstrapFromCache()'), isFalse);
  });

  test('Settings FA logout text is خروج از برنامه', () {
    expect(Gate3Localization('fa').logoutApp, 'خروج از برنامه');
    final settings = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_settings_menu.dart',
    );
    expect(settings.contains('l10n.logoutApp'), isTrue);
    expect(settings.contains('title: Text(l10n.logout)'), isFalse);
  });

  test('Memory UX reuses I6 consent endpoints without silent grant', () {
    final service = _read('lib/core/memory/memory_consent_service.dart');
    expect(service.contains('/memory/consent'), isTrue);
    expect(service.contains('/memory/consent/grant'), isTrue);
    expect(service.contains('/memory/consent/revoke'), isTrue);

    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(page.contains('Gate3MemoryConsentInvitation'), isFalse);
    expect(page.contains('_grantMemoryConsentFromInvitation'), isFalse);
    expect(page.contains('_loadMemoryConsentInvitation'), isFalse);
    expect(page.contains('MemoryConsentService'), isFalse);

    final settings = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_settings_menu.dart',
    );
    expect(settings.contains('Gate3MemoryPrivacyPage'), isFalse);
    expect(settings.contains('l10n.memoryAndPrivacy'), isFalse);

    final profile = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    );
    expect(profile.contains('Gate3ProfileMemoryControl'), isTrue);

    final privacy = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_memory_privacy_page.dart',
    );
    expect(privacy.contains('fetchStatus()'), isTrue);
    expect(privacy.contains('.grant()'), isTrue);
    expect(privacy.contains('.revoke()'), isTrue);

    final parsed = MemoryConsentStatus.tryParse({
      'granted': true,
      'status': 'active',
      'permissions': {
        'memory.write': true,
        'memory.read': true,
        'memory.forget': true,
      },
      'policy_version': 'i6-v1',
    });
    expect(parsed, isNotNull);
    expect(parsed!.granted, isTrue);
    expect(parsed.status, 'active');
    expect(parsed.writeAllowed, isTrue);

    final none = MemoryConsentStatus.tryParse({
      'granted': false,
      'status': 'none',
      'permissions': {
        'memory.write': false,
        'memory.read': false,
        'memory.forget': false,
      },
    });
    expect(none!.granted, isFalse);
  });

  test('stable MobileInstallIdStore path is unchanged', () {
    final store = _read('lib/core/device/mobile_install_id_store.dart');
    expect(store.contains("storageKey = 'sedi_gateway_install_id_v1'"), isTrue);
    expect(store.contains('getOrCreate()'), isTrue);

    final push = _read('lib/services/push/push_service.dart');
    expect(push.contains('MobileInstallIdStore'), isTrue);
    expect(push.contains('deviceId: installId'), isTrue);
  });

  test('A3 Heart has no memory-consent invitation entry', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(page.contains('Allow Memory'), isFalse);
    expect(page.contains('memoryConsentGrant'), isFalse);
    expect(page.contains('Gate3MemoryConsentInvitation'), isFalse);
    expect(
      File(
        'lib/features/gate3_interactive/presentation/widgets/gate3_memory_consent_invitation.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
