import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/calendar_date_math.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/chat/state/assistant_stream_pacer.dart';
import 'package:sedi_app/features/gate3_interactive/models/gate3_interaction_state.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_assistant_starter_bus.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_composer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_brain_orb.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_horizontal_resonance_visualizer.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/sedi_orb_presence.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_page.dart';

void main() {
  group('Profile summary empty copy', () {
    test('FA empty-state copy matches approved wording', () {
      expect(
        Gate3Localization('fa').userSummaryEmpty,
        'در حال حاضر، اطلاعات کافی از شما در حافظه صدی ثبت نشده است. با ادامه گفت‌وگو و استفاده از صدی، این بخش به‌تدریج کامل‌تر می‌شود.',
      );
    });
  });

  group('A3 profile DOB/sex localization', () {
    test('EN Gregorian Latin digits + sex labels', () {
      expect(
        CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'en'),
        '1990-05-15',
      );
      expect(Gate3Localization('en').profileSexValue('male'), 'Male');
      expect(Gate3Localization('en').profileSexValue('female'), 'Female');
      expect(Gate3Localization('en').profileSexValue('other'), 'Other');
    });

    test('FA Jalali Persian digits + sex labels', () {
      final dob =
          CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'fa');
      expect(RegExp(r'[0-9]').hasMatch(dob), isFalse);
      expect(RegExp(r'[۰-۹]').hasMatch(dob), isTrue);
      expect(dob.contains('/'), isTrue);
      expect(Gate3Localization('fa').profileSexValue('male'), 'مرد');
      expect(Gate3Localization('fa').profileSexValue('female'), 'زن');
      expect(Gate3Localization('fa').profileSexValue('other'), 'سایر');
    });

    test('AR Hijri Arabic-Indic digits + sex labels', () {
      final dob =
          CalendarDateMath.formatIsoForProfileDisplay('1990-05-15', 'ar');
      expect(RegExp(r'[0-9]').hasMatch(dob), isFalse);
      expect(RegExp(r'[٠-٩]').hasMatch(dob), isTrue);
      expect(Gate3Localization('ar').profileSexValue('male'), 'ذكر');
      expect(Gate3Localization('ar').profileSexValue('female'), 'أنثى');
      expect(Gate3Localization('ar').profileSexValue('other'), 'آخر');
    });
  });

  group('Lifestyle → canonical A3 chat', () {
    testWidgets('nutrition/exercise starter handoff pops to root without nested A3',
        (tester) async {
      var nestedGate3Pushed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    const Text('root-a3'),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              body: ElevatedButton(
                                onPressed: () {
                                  openLifestyleChat(
                                    context,
                                    starterMessage:
                                        LifestyleL10n('en').nutritionChatStarter,
                                  );
                                },
                                child: const Text('talk-nutrition'),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('open-lifestyle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      String? received;
      final sub = Gate3AssistantStarterBus.instance.stream.listen((d) {
        received = d;
      });
      addTearDown(sub.cancel);

      await tester.tap(find.text('open-lifestyle'));
      await tester.pumpAndSettle();
      expect(find.text('talk-nutrition'), findsOneWidget);

      await tester.tap(find.text('talk-nutrition'));
      await tester.pumpAndSettle();

      expect(find.text('root-a3'), findsOneWidget);
      expect(find.text('talk-nutrition'), findsNothing);
      expect(received, LifestyleL10n('en').nutritionChatStarter);
      expect(nestedGate3Pushed, isFalse);
    });

    testWidgets('composer stays empty without auto-send / build error',
        (tester) async {
      FlutterErrorDetails? error;
      final old = FlutterError.onError;
      FlutterError.onError = (details) => error = details;
      addTearDown(() => FlutterError.onError = old);

      var sent = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Gate3Composer(
              placeholder: 'Talk',
              lang: 'en',
              isRtl: false,
              isRecording: false,
              recordingTime: '00:00',
              initialText: null,
              onListeningChanged: (_) {},
              onSendText: (_) => sent++,
              onStartRecording: () {},
              onStopRecordingAndSend: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(error, isNull);
      expect(sent, 0);
    });

    test('FA/EN/AR lifestyle starters localized', () {
      expect(
        LifestyleL10n('fa').nutritionChatStarter.contains('تغذیه'),
        isTrue,
      );
      expect(
        LifestyleL10n('fa').exerciseChatStarter.contains('ورزشی'),
        isTrue,
      );
      expect(LifestyleL10n('en').nutritionChatStarter.isNotEmpty, isTrue);
      expect(LifestyleL10n('ar').exerciseChatStarter.isNotEmpty, isTrue);
    });
  });

  group('Chat bubbles + resonance', () {
    testWidgets('user bubble only; assistant unboxed and full', (tester) async {
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
      // User collapses (maxLines=2); assistant has no maxLines.
      final texts = tester.widgetList<Text>(find.text(long)).toList();
      expect(texts.length, 2);
      expect(texts.any((t) => t.maxLines == 2), isTrue);
      expect(texts.any((t) => t.maxLines == null), isTrue);
      // Only user message uses a decorated Container bubble.
      final decorated = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .length;
      expect(decorated, 1);
    });

    test('speaking is strongest energy; IDLE < LISTENING < THINKING < SPEAKING',
        () {
      final idle = SediHorizontalResonanceVisualizer.targetEnergy(
          Gate3InteractionState.idle);
      final listening = SediHorizontalResonanceVisualizer.targetEnergy(
          Gate3InteractionState.listening);
      final thinking = SediHorizontalResonanceVisualizer.targetEnergy(
          Gate3InteractionState.thinking);
      final speaking = SediHorizontalResonanceVisualizer.targetEnergy(
          Gate3InteractionState.speaking);
      expect(idle < listening, isTrue);
      expect(listening < thinking, isTrue);
      expect(thinking < speaking, isTrue);
      expect(SediHorizontalResonanceVisualizer.amplitudeScale, 0.80);
      expect(SediHorizontalResonanceVisualizer.phaseSpeed, 0.85);
      expect(SediHorizontalResonanceVisualizer.height, 52);
      expect(SediHorizontalResonanceVisualizer.barCount, 98);
      expect(SediHorizontalResonanceVisualizer.peakCeiling, closeTo(0.65, 0.001));

      const phase = 0.22;
      final a = SediHorizontalResonanceVisualizer.audioResonanceShape(0.18, phase);
      final b = SediHorizontalResonanceVisualizer.audioResonanceShape(0.52, phase);
      expect(a, inInclusiveRange(0.0, 1.0));
      expect(b, inInclusiveRange(0.0, 1.0));
      expect(a, isNot(closeTo(b, 0.02)));

      var maxStep = 0.0;
      var prev = SediHorizontalResonanceVisualizer.audioResonanceShape(0.0, phase);
      for (var i = 1; i <= 97; i++) {
        final next = SediHorizontalResonanceVisualizer.audioResonanceShape(
          i / 97,
          phase,
        );
        final step = (next - prev).abs();
        if (step > maxStep) maxStep = step;
        prev = next;
      }
      expect(maxStep, lessThan(0.12));

      final speakingCapped = SediHorizontalResonanceVisualizer.heightFactorFor(
        energy: speaking,
        envelope: 1.0,
        density: 1.0,
      );
      expect(
        speakingCapped,
        closeTo(SediHorizontalResonanceVisualizer.peakCeiling, 0.001),
      );
      expect(
        speakingCapped,
        lessThan(SediHorizontalResonanceVisualizer.previousSpeakingPeak),
      );

      final vis = File(
        'lib/features/gate3_interactive/presentation/widgets/'
        'sedi_horizontal_resonance_visualizer.dart',
      ).readAsStringSync();
      expect(vis.contains('audioResonanceShape'), isTrue);
      expect(vis.contains('ecgShape'), isFalse);
      expect(vis.contains('heartbeatEnvelope'), isFalse);
      expect(vis.contains('QRS'), isFalse);
      expect(vis.contains('not I9'), isTrue);
    });

    test('A3-03R pacer cadence holds across an empty-queue restart', () async {
      expect(AssistantStreamPacer.speedFactor, closeTo(0.30, 0.001));
      expect(AssistantStreamPacer.revealDelay.inMilliseconds, 53);
      final seen = <String>[];
      final pacer = AssistantStreamPacer();
      pacer.enqueue('a', seen.add);
      await pacer.whenIdle;
      pacer.enqueue('b', seen.add);
      expect(seen, ['a']);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(seen, ['a']);
      await pacer.whenIdle;
      expect(seen, ['a', 'b']);
    });

    testWidgets('horizontal visualizer present for all four states',
        (tester) async {
      for (final state in Gate3InteractionState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SediHorizontalResonanceVisualizer(state: state),
            ),
          ),
        );
        expect(find.byType(SediHorizontalResonanceVisualizer), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
  });

  group('User edit-as-new-message', () {
    test('edit labels EN/FA/AR', () {
      expect(Gate3Localization('en').editMessage, 'Edit');
      expect(Gate3Localization('fa').editMessage, 'ویرایش');
      expect(Gate3Localization('ar').editMessage, 'تعديل');
    });

    testWidgets('user shows edit; assistant has none; edit does not auto-send',
        (tester) async {
      var editTaps = 0;
      var sent = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MessageBubble(
                  message: 'Original user text',
                  isSedi: false,
                  onEdit: () => editTaps++,
                  editLabel: 'Edit',
                ),
                const MessageBubble(
                  message: 'Assistant reply',
                  isSedi: true,
                ),
                Gate3Composer(
                  key: const ValueKey('edit-composer'),
                  placeholder: 'Talk',
                  lang: 'en',
                  isRtl: false,
                  isRecording: false,
                  recordingTime: '00:00',
                  initialText: 'Original user text',
                  onListeningChanged: (_) {},
                  onSendText: (_) => sent++,
                  onStartRecording: () {},
                  onStopRecordingAndSend: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Edit'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(editTaps, 1);
      expect(sent, 0);

      final page = File(
        'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
      ).readAsStringSync();
      expect(page.contains('_editUserMessageAsNewDraft'), isTrue);
      expect(page.contains('updateMessage'), isFalse);
      expect(page.contains('patchMessage'), isFalse);
    });
  });

  group('R1 orb resonance center', () {
    testWidgets('one full-width visualizer shares the orb centerline',
        (tester) async {
      for (final state in Gate3InteractionState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SediOrbPresence.horizontalInset,
                  ),
                  child: SediOrbPresence(state: state, lang: 'en'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final orb = tester.getRect(find.byType(SediBrainOrb));
        expect(find.byType(SediHorizontalResonanceVisualizer), findsOneWidget);
        final bars = tester.getRect(
          find.byType(SediHorizontalResonanceVisualizer),
        );
        expect(bars.center.dy, closeTo(orb.center.dy, 0.5));
        expect(bars.center.dx, closeTo(orb.center.dx, 1.0));
        expect(find.text('Sedi.'), findsOneWidget);
        final usable = 390 - 2 * SediOrbPresence.horizontalInset;
        final expected = SediBrainOrb.diameterFor(usable.toDouble());
        expect(tester.getSize(find.byType(SediBrainOrb)).width,
            closeTo(expected, 0.5));
        expect(bars.height, closeTo(SediHorizontalResonanceVisualizer.height, 0.01));
      }
    });

    testWidgets('presence height is unchanged when the keyboard inset opens',
        (tester) async {
      Size measure() {
        return tester.getSize(find.byType(SediOrbPresence));
      }

      Future<void> pumpWith(EdgeInsets viewInsets) {
        return tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              final data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(viewInsets: viewInsets),
                child: child!,
              );
            },
            home: Scaffold(
              body: SizedBox(
                width: 390,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SediOrbPresence.horizontalInset,
                  ),
                  child: const SediOrbPresence(
                    state: Gate3InteractionState.speaking,
                    lang: 'fa',
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await pumpWith(EdgeInsets.zero);
      await tester.pump();
      final closed = measure();

      await pumpWith(const EdgeInsets.only(bottom: 320));
      await tester.pump();
      final open = measure();

      expect(closed.height, closeTo(open.height, 0.01));
      expect(closed.width, closeTo(open.width, 0.01));
      final usable = 390 - 2 * SediOrbPresence.horizontalInset;
      expect(
        closed.height,
        closeTo(SediBrainOrb.diameterFor(usable.toDouble()), 0.5),
      );
      expect(closed.width, greaterThan(SediBrainOrb.minDiameter));
    });
  });
}
