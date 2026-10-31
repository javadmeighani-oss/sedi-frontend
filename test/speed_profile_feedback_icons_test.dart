import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedi_app/core/memory/memory_consent_service.dart';
import 'package:sedi_app/core/memory/memory_consent_status.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/core/profile/profile_snapshot_cache.dart';
import 'package:sedi_app/core/ui/sedi_warmup.dart';
import 'package:sedi_app/data/dto/auth/me_profile.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_profile_memory_control.dart';

String _read(String path) => File(path).readAsStringSync();

int _at(String src, String needle) {
  final i = src.indexOf(needle);
  expect(i, greaterThanOrEqualTo(0), reason: 'missing: $needle');
  return i;
}

/// A service whose answer never arrives: proves the control paints without waiting for the network.
class _NeverAnswers extends MemoryConsentService {
  final Completer<ApiResponse<MemoryConsentStatus>> never = Completer();

  @override
  Future<ApiResponse<MemoryConsentStatus>> fetchStatus() => never.future;
}

/// Javad 2026-10-31: the profile has no load time, the "why?" options open at once, and icons / A3 appear without a
/// pop-in; A1 -> A3 no longer waits for the push-token round trip.
void main() {
  setUp(() {
    ProfileSnapshotCache.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('profile snapshot cache', () {
    const me = MeProfileDto(userId: 7, name: 'Ada', preferredLanguage: 'fa', sex: 'female', phone: '+15551212');
    const memory = MemoryConsentStatus(
      granted: true,
      status: 'active',
      writeAllowed: true,
      readAllowed: true,
      forgetAllowed: true,
      policyVersion: 'i6-v1',
    );

    test('MeProfileDto.toJson round-trips through fromJson', () {
      final back = MeProfileDto.fromJson(me.toJson());
      expect(back.userId, 7);
      expect(back.name, 'Ada');
      expect(back.preferredLanguage, 'fa');
      expect(back.sex, 'female');
      expect(back.phone, '+15551212');
    });

    test('what A1 / A3 read is there at once, and the device copy survives a restart (the summary does not)', () async {
      ProfileSnapshotCache.putMe(me);
      ProfileSnapshotCache.putMemory(memory);
      ProfileSnapshotCache.putSummary('A short sentence about the user.');
      expect(ProfileSnapshotCache.me?.name, 'Ada');
      expect(ProfileSnapshotCache.memory?.granted, isTrue);
      expect(ProfileSnapshotCache.summary, isNotEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 50)); // the device write finishes
      ProfileSnapshotCache.reset(); // "the app restarted"
      expect(ProfileSnapshotCache.me, isNull);
      await ProfileSnapshotCache.restore();
      expect(ProfileSnapshotCache.me?.name, 'Ada');
      expect(ProfileSnapshotCache.me?.userId, 7);
      expect(ProfileSnapshotCache.memory?.granted, isTrue);
      expect(ProfileSnapshotCache.memory?.policyVersion, 'i6-v1');
      // health picture sentence: memory only, never written to the device
      expect(ProfileSnapshotCache.summary, isEmpty);
    });

    test('restore never overwrites something fresher already in memory', () async {
      ProfileSnapshotCache.putMe(me);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ProfileSnapshotCache.reset();
      ProfileSnapshotCache.putMe(me.copyWith(name: 'Newer'));
      await ProfileSnapshotCache.restore();
      expect(ProfileSnapshotCache.me?.name, 'Newer');
    });

    test('clear removes it from memory and from the device', () async {
      ProfileSnapshotCache.putMe(me);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await ProfileSnapshotCache.clear();
      expect(ProfileSnapshotCache.me, isNull);
      await ProfileSnapshotCache.restore();
      expect(ProfileSnapshotCache.me, isNull);
    });

    test('logout / invalid session clear it, and A1 seeds it from the /auth/me it already reads', () {
      expect(_read('lib/core/utils/user_profile_manager.dart').contains('ProfileSnapshotCache.clear()'), isTrue);
      final svc = _read('lib/core/auth/auth_profile_service.dart');
      expect(_at(svc, 'ProfileSnapshotCache.putMe(me)'), lessThan(_at(svc, 'UserProfileManager.saveProfile(profile)')));
      expect(_read('lib/main.dart').contains('ProfileSnapshotCache.restore()'), isTrue);
    });
  });

  group('profile page: no load time', () {
    test('the page paints from the cache, has no spinner state, and the language tile is a globe', () {
      final src = _read('lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart');
      expect(src.contains('_loading'), isFalse);
      expect(src.contains('MeProfileDto? _me = ProfileSnapshotCache.me;'), isTrue);
      expect(src.contains('String _canonicalSummary = ProfileSnapshotCache.summary;'), isTrue);
      expect(src.contains('icon: Icons.language_rounded'), isTrue);
      expect(src.contains('SediLanguageBadge('), isFalse);
      expect(src.contains('_load(force: false)'), isTrue);
    });

    test('the loader starts the three reads together (none waits for another)', () {
      final src = _read('lib/core/profile/profile_snapshot_loader.dart');
      final lastStart = [
        _at(src, 'final meF = profile.fetchMe('),
        _at(src, 'final summaryF = api.get<String>('),
        _at(src, 'final memoryF = memory.fetchStatus()'),
      ].reduce((a, b) => a > b ? a : b);
      expect(lastStart, lessThan(_at(src, 'await meF')));
      expect(lastStart, lessThan(_at(src, 'await summaryF')));
      expect(lastStart, lessThan(_at(src, 'await memoryF')));
    });

    test('A3 fills the profile in the background', () {
      final src = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
      expect(src.contains('ProfileSnapshotLoader.refresh(summaryParser: canonicalProfileSummaryText)'), isTrue);
    });

    testWidgets('the memory switch shows the known state at the first frame, without a spinner, while the read is pending',
        (tester) async {
      ProfileSnapshotCache.putMemory(const MemoryConsentStatus(
        granted: true,
        status: 'active',
        writeAllowed: true,
        readAllowed: true,
        forgetAllowed: true,
      ));
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Gate3ProfileMemoryControl(service: _NeverAnswers()))),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Switch), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('with nothing known yet the switch is still there, disabled, never faked and never a spinner',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Gate3ProfileMemoryControl(service: _NeverAnswers()))),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNull);
    });
  });

  group('"why?" options open at once', () {
    test('inbox: the sheet opens first; the ACK runs behind it and the reason is sent after the ACK', () {
      final src = _read('lib/features/notifications/presentation/pages/notification_inbox_page.dart');
      final start = _at(src, 'final acked = NotificationActionCoordinator.submit(');
      final sheet = _at(src, 'await showDislikeReasonSheet(context, _l10n)');
      final waitAck = _at(src, 'final ok = await acked;');
      final send = _at(src, 'await _service.sendDislikeReason(item.id, picked)');
      expect(start, lessThan(sheet));
      expect(sheet, lessThan(waitAck));
      expect(waitAck, lessThan(send));
      // the sheet is NOT behind the server ACK or the list refresh any more
      expect(src.contains('_askDislikeReason'), isFalse);
      expect(_at(src, 'if (actionId == \'dislike\') {'), lessThan(_at(src, 'await NotificationActionCoordinator.submit(')));
    });

    test('tray: the question starts BEFORE the pending write, and the plugin starts while the saved text is read', () {
      final src = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(_at(src, 'promptShown = _showReasonPrompt('), lessThan(_at(src, 'await PendingNotificationActions.enqueue(')));
      expect(_at(src, 'promptShown = _showPlanReasonPrompt('), lessThan(_at(src, 'await PendingNotificationActions.enqueue(')));
      expect(_at(src, 'final originalF = TrayNotificationSnapshotStore.get('), lessThan(_at(src, 'await plugin.initialize(')));
      // contracts that already existed
      expect(src.contains("action == 'dislike'"), isTrue);
      expect(src.contains('PendingDislikeReasons.add(id)'), isTrue);
    });
  });

  group('A1 -> A3 and the first frame', () {
    test('A3 never waits for the push-token round trip; the logo motion is unchanged', () {
      final src = _read('lib/features/intro/presentation/pages/intro_page.dart');
      expect(src.contains('unawaited(tryRegisterStoredTokenAfterLogin())'), isTrue);
      expect(src.contains('await tryRegisterStoredTokenAfterLogin()'), isFalse);
      expect(src.contains('kIntroDuration = Duration(milliseconds: 3000)'), isTrue);
    });

    test('the wordmark and the fonts are made ready during the logo, once', () {
      final intro = _read('lib/features/intro/presentation/pages/intro_page.dart');
      expect(intro.contains('SediWarmup.run(context)'), isTrue);
      final warm = _read('lib/core/ui/sedi_warmup.dart');
      expect(warm.contains('precacheImage(const AssetImage(SediHologramOrb.logoAsset), context)'), isTrue);
      expect(SediWarmup.weights.length, 5);
      expect(() => SediWarmup.warmFonts('fa'), returnsNormally);
      expect(() => SediWarmup.warmFonts('ar'), returnsNormally);
      expect(() => SediWarmup.warmFonts('en'), returnsNormally);
    });

    test("the chat's opener request starts before the stored profile is read", () {
      final src = _read('lib/features/chat/state/chat_controller.dart');
      expect(_at(src, 'final openFuture = initialMessage == null'), lessThan(_at(src, 'await UserProfileManager.loadProfile()')));
      expect(_at(src, 'await UserProfileManager.loadProfile()'), lessThan(_at(src, 'await _restoreCurrentDayTranscript();')));
    });
  });
}
