import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/memory/memory_consent_service.dart';
import 'package:sedi_app/core/memory/memory_consent_status.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/core/profile/profile_snapshot_cache.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_profile_memory_control.dart';

class _FakeMemoryConsentService extends MemoryConsentService {
  _FakeMemoryConsentService({required this.granted, this.failRevoke = false});

  bool granted;
  bool failRevoke;
  int grants = 0;
  int revokes = 0;

  MemoryConsentStatus _status() {
    return MemoryConsentStatus(
      granted: granted,
      status: granted ? 'active' : 'revoked',
      writeAllowed: granted,
      readAllowed: granted,
      forgetAllowed: granted,
      policyVersion: 'i6-v1',
    );
  }

  @override
  Future<ApiResponse<MemoryConsentStatus>> fetchStatus() async {
    return ApiResponse(ok: true, data: _status());
  }

  @override
  Future<ApiResponse<MemoryConsentStatus>> grant() async {
    grants++;
    granted = true;
    return ApiResponse(ok: true, data: _status());
  }

  @override
  Future<ApiResponse<MemoryConsentStatus>> revoke() async {
    revokes++;
    if (failRevoke) {
      return const ApiResponse(ok: false);
    }
    granted = false;
    return ApiResponse(ok: true, data: _status());
  }
}

void main() {
  // The profile snapshot cache is static: every test starts without what an earlier one stored.
  setUp(ProfileSnapshotCache.reset);

  test('Profile hosts Memory & Privacy; Settings duplicate is removed', () {
    final profile = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/features/gate3_interactive/presentation/widgets/gate3_settings_menu.dart',
    ).readAsStringSync();
    final control = File(
      'lib/features/gate3_interactive/presentation/widgets/gate3_profile_memory_control.dart',
    ).readAsStringSync();
    final service = File('lib/core/memory/memory_consent_service.dart')
        .readAsStringSync();

    expect(profile.contains('Gate3ProfileMemoryControl'), isTrue);
    expect(settings.contains('Gate3MemoryPrivacyPage'), isFalse);
    expect(settings.contains('l10n.memoryAndPrivacy'), isFalse);
    expect(control.contains('fetchStatus()'), isTrue);
    expect(control.contains('.grant()'), isTrue);
    expect(control.contains('.revoke()'), isTrue);
    expect(control.contains('memoryOffConfirmTitle'), isTrue);
    expect(control.contains('granted == true'), isTrue);
    expect(service.contains('/memory/consent/grant'), isTrue);
    expect(service.contains('/memory/consent/revoke'), isTrue);
  });

  test('FA/EN/AR off-confirmation copy is present', () {
    final fa = Gate3Localization('fa');
    final en = Gate3Localization('en');
    final ar = Gate3Localization('ar');
    expect(fa.memoryOffConfirmTitle, 'خاموش کردن حافظه صدی؟');
    expect(
      fa.memoryOffConfirmBody,
      'با خاموش کردن حافظه، از این لحظه صدی اطلاعات جدید گفتگو را برای استفاده در دفعات بعد ذخیره نمی‌کند و از حافظه ذخیره‌شده برای پیوستگی گفتگو استفاده نخواهد کرد. در نتیجه پیوستگی مراقبت، شخصی‌سازی و دقت همراهی صدی کاهش می‌یابد. آیا مطمئن هستید؟',
    );
    expect(fa.memoryOffConfirmKeepOn, 'خیر، حافظه روشن بماند');
    expect(fa.memoryOffConfirmTurnOff, 'بله، حافظه خاموش شود');
    expect(en.memoryOffConfirmTitle, isNotEmpty);
    expect(en.memoryOffConfirmBody, isNotEmpty);
    expect(en.memoryOffConfirmKeepOn, isNotEmpty);
    expect(en.memoryOffConfirmTurnOff, isNotEmpty);
    expect(ar.memoryOffConfirmTitle, isNotEmpty);
    expect(ar.memoryOffConfirmBody, isNotEmpty);
    expect(ar.memoryOffConfirmKeepOn, isNotEmpty);
    expect(ar.memoryOffConfirmTurnOff, isNotEmpty);
  });

  testWidgets('ON to OFF opens confirmation; cancel keeps ON; confirm revokes',
      (tester) async {
    final service = _FakeMemoryConsentService(granted: true);
    final l10n = Gate3Localization('en');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3ProfileMemoryControl(service: service),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.memoryControlOn), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text(l10n.memoryOffConfirmTitle), findsOneWidget);
    expect(service.revokes, 0);

    await tester.tap(find.text(l10n.memoryOffConfirmKeepOn));
    await tester.pumpAndSettle();
    expect(service.revokes, 0);
    expect(find.text(l10n.memoryControlOn), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.memoryOffConfirmTurnOff));
    await tester.pumpAndSettle();
    expect(service.revokes, 1);
    expect(find.text(l10n.memoryControlOff), findsOneWidget);
  });

  testWidgets('OFF to ON grants; revoke failure keeps prior ON and shows error',
      (tester) async {
    final grantService = _FakeMemoryConsentService(granted: false);
    final l10n = Gate3Localization('en');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3ProfileMemoryControl(service: grantService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.memoryControlOff), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(grantService.grants, 1);
    expect(find.text(l10n.memoryControlOn), findsOneWidget);

    final failService = _FakeMemoryConsentService(granted: true, failRevoke: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3ProfileMemoryControl(service: failService),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.memoryOffConfirmTurnOff));
    await tester.pumpAndSettle();
    expect(failService.revokes, 1);
    expect(failService.granted, isTrue);
    expect(find.text(l10n.memoryControlOn), findsOneWidget);
    expect(find.text(l10n.memoryConsentActionError), findsOneWidget);
  });
}
