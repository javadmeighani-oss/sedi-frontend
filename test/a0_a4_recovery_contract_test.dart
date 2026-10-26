import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/theme/sedi_palette.dart';
import 'package:sedi_app/core/utils/brand_name.dart';
import 'package:sedi_app/data/dto/auth/otp_request.dart';
import 'package:sedi_app/data/dto/auth/otp_verify.dart';
import 'package:sedi_app/features/auth_otp/presentation/a2_otp_error_mapper.dart';
import 'package:sedi_app/features/auth_otp/presentation/otp_login_localization.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/gate3_interactive/models/gate3_interaction_state.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_brain_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_hologram_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/a3_destination_surface.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('A2 OTP DTOs send LOGIN and REGISTRATION purpose', () {
    expect(
      const OtpRequestDto(
        phone: '+15551234567',
        purpose: OtpPurpose.login,
      ).toJson(),
      {'phone': '+15551234567', 'purpose': 'LOGIN'},
    );
    expect(
      const OtpVerifyDto(
        phone: '+15551234567',
        code: '123456',
        purpose: OtpPurpose.registration,
      ).toJson(),
      {'phone': '+15551234567', 'code': '123456', 'purpose': 'REGISTRATION'},
    );
  });

  test('A2 account mismatch codes map to localized account actions', () {
    const en = OtpLoginLocalization('en');
    expect(
      A2OtpErrorMapper.mapVerify(l10n: en, code: 'ACCOUNT_NOT_FOUND'),
      contains('Create an account'),
    );
    expect(
      A2OtpErrorMapper.mapRequest(l10n: en, code: 'ACCOUNT_EXISTS'),
      contains('Have account'),
    );
  });

  test(
      'A3 source keeps the light pistachio shell, four domains, and hidden subject selector',
      () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    final row = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_main_icon_row.dart',
    );

    expect(page.contains('backgroundColor: SediPalette.sagePage'), isTrue);
    expect(page.contains('Offstage('), isTrue);
    expect(page.contains('Gate3SubjectSelector'), isTrue);
    expect(row.contains('profileTitle'), isTrue);
    expect(row.contains('lifestyle'), isTrue);
    expect(row.contains('gadgets'), isTrue);
    expect(row.contains('notifications'), isTrue);
    expect(row.contains('healthCare'), isFalse);
  });

  testWidgets('A3 hologram always renders the Latin wordmark in RTL locale',
      (tester) async {
    expect(sediOrbBrandLatin, 'Sedi.');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: SediBrainOrb(state: Gate3InteractionState.speaking, lang: 'fa'),
      ),
    );
    expect(find.byKey(SediHologramOrb.logoKey), findsOneWidget);
    expect(find.text('صدی'), findsNothing);
    expect(SediHorizontalResonanceVisualizer.phaseSpeed, 0.85);
    expect(SediHorizontalResonanceVisualizer.amplitudeScale, 0.80);
    final idle = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.idle);
    final listening = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.listening);
    final thinking = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.thinking);
    final speaking = SediHorizontalResonanceVisualizer.targetEnergy(
        Gate3InteractionState.speaking);
    expect(idle < listening && listening < thinking && thinking < speaking,
        isTrue);
  });

  test('A3 orb presence integrates resonance; lifestyle uses starter bus', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(page.contains('SediOrbPresence'), isTrue);
    expect(page.contains('Gate3ComposerDraftBus'), isTrue);
    expect(page.contains('Gate3AssistantStarterBus'), isTrue);
    final lifestyle = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_page.dart',
    );
    expect(lifestyle.contains('popUntil'), isTrue);
    expect(lifestyle.contains('Gate3AssistantStarterBus'), isTrue);
    expect(lifestyle.contains('Gate3InteractivePage(initialDraft:'), isFalse);
    expect(SediHorizontalResonanceVisualizer.phaseSpeed, 0.85);
  });

  test('ChatController speaking lifecycle is SSE-delta only', () {
    final src = _read('lib/features/chat/state/chat_controller.dart');
    expect(src.contains('bool isSpeaking = false'), isTrue);
    // Whitespace-insensitive: dart format may re-indent these blocks.
    final flat = src.replaceAll(RegExp(r'\s+'), ' ');
    expect(flat.contains('isThinking = true; isSpeaking = false;'), isTrue);
    expect(flat.contains('isSpeaking = true; messages.add'), isTrue);
    expect(src.contains('isSpeaking = false'), isTrue);
    expect(src.contains('initialize({String? initialMessage'), isTrue);
    expect(src.contains('onDelta:'), isTrue);
    expect(src.contains('messages[idx].text + delta'), isTrue);
  });

  test('user edit replaces the original message (D-093), not a new one', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    final bubble = _read(
      'lib/features/chat/presentation/widgets/message_bubble.dart',
    );
    final controller = _read('lib/features/chat/state/chat_controller.dart');
    expect(page.contains('_beginEditUserMessage'), isTrue);
    expect(page.contains('_editingLocalId'), isTrue);
    expect(page.contains('replaceUserMessage'), isTrue);
    expect(controller.contains('replaceUserMessage'), isTrue);
    expect(page.contains('onEdit:'), isTrue);
    expect(bubble.contains('onEdit'), isTrue);
    expect(bubble.contains('Icons.edit_outlined'), isTrue);
    expect(Gate3Localization('fa').editMessage, 'ویرایش');
  });

  testWidgets('Gate3Composer has plus-only left action and required fonts',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Gate3Composer(
            placeholder: 'Talk to Sedi',
            lang: 'en',
            isRtl: false,
            isRecording: false,
            recordingTime: '00:00',
            onListeningChanged: (_) {},
            onSendText: (_) {},
            onStartRecording: () {},
            onStopRecordingAndSend: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontSize, 16.2);
    expect(field.decoration?.hintStyle?.fontSize, 12.8);
  });

  testWidgets('user bubble collapses long text but assistant stays full',
      (tester) async {
    const long = 'line one\nline two\nline three';
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            MessageBubble(message: long, isSedi: false),
            MessageBubble(message: long, isSedi: true),
          ],
        ),
      ),
    );

    expect(find.text('Read more'), findsOneWidget);
    await tester.tap(find.text('Read more'));
    await tester.pump();
    expect(find.text('Read less'), findsOneWidget);
  });

  test('profile logout and A4 badge authority are recovery contracts', () {
    expect(Gate3Localization('fa').logoutApp, 'خروج از برنامه');
    expect(Gate3Localization('en').logoutApp, 'Log out of app');
    final profile = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart',
    );
    expect(profile.contains('logoutSection'), isFalse);
    expect(profile.contains('TextDirection.ltr'), isTrue);
    expect(profile.contains('A3DestinationSurface.canvas'), isTrue);
    expect(A3DestinationSurface.canvas, SediPalette.sagePage);

    final notifications =
        _read('lib/services/notifications/notifications_service.dart');
    expect(notifications.contains("'/notifications/'"), isTrue);
    expect(notifications.contains('/notifications/unread'), isTrue);
    expect(notifications.contains('/notifications/inbox/hide'), isTrue);
    expect(notifications.contains('listInboxPage(unreadOnly: false'), isTrue);
    expect(notifications.contains('page.data?.unreadCount ?? 0'), isTrue);
  });
}
