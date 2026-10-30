import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/network/api_response.dart';
import 'package:sedi_app/data/dto/chat/chat_send_response.dart';
import 'package:sedi_app/features/chat/state/a3_session_prefetch.dart';
import 'package:sedi_app/features/chat/state/chat_return_policy.dart';
import 'package:sedi_app/features/chat/state/natural_reveal.dart';

String _read(String path) => File(path).readAsStringSync();

/// Javad 2026-10-30: coming back to the app (a new day starts clean, the same day collapses into a summary), Sedi's
/// opener revealed in about three seconds, and A1 asking for that opener while the logo moves.
void main() {
  final noon = DateTime(2026, 10, 30, 12, 0);

  group('ChatReturnPolicy', () {
    test('a short trip away changes nothing', () {
      final a = ChatReturnPolicy.decide(
        now: noon,
        pausedAt: noon.subtract(const Duration(seconds: 90)),
        threadDay: ChatReturnPolicy.dayKey(noon),
        hasUserMessages: true,
      );
      expect(a, ChatReturnAction.none);
    });

    test('away for 2 minutes or more on the same day: the day collapses into a summary', () {
      final a = ChatReturnPolicy.decide(
        now: noon,
        pausedAt: noon.subtract(const Duration(minutes: 2)),
        threadDay: ChatReturnPolicy.dayKey(noon),
        hasUserMessages: true,
      );
      expect(a, ChatReturnAction.sameDaySummary);
    });

    test('nothing was said yet today: nothing to summarise', () {
      final a = ChatReturnPolicy.decide(
        now: noon,
        pausedAt: noon.subtract(const Duration(hours: 1)),
        threadDay: ChatReturnPolicy.dayKey(noon),
        hasUserMessages: false,
      );
      expect(a, ChatReturnAction.none);
    });

    test('back on a NEW day: a clean start with one welcome, whatever was said yesterday', () {
      final yesterday = DateTime(2026, 10, 29, 22, 30);
      for (final said in [true, false]) {
        final a = ChatReturnPolicy.decide(
          now: noon,
          pausedAt: DateTime(2026, 10, 29, 23, 0),
          threadDay: ChatReturnPolicy.dayKey(yesterday),
          hasUserMessages: said,
        );
        expect(a, ChatReturnAction.freshDay, reason: 'said=$said');
      }
    });

    test('a busy chat (thinking, recording, starting) is never disturbed', () {
      final a = ChatReturnPolicy.decide(
        now: noon,
        pausedAt: noon.subtract(const Duration(hours: 5)),
        threadDay: '2026-10-01',
        hasUserMessages: true,
        busy: true,
      );
      expect(a, ChatReturnAction.none);
    });

    test('never paused / unknown: nothing', () {
      expect(
        ChatReturnPolicy.decide(now: noon, pausedAt: null, threadDay: '2026-10-29', hasUserMessages: true),
        ChatReturnAction.none,
      );
    });

    test('dayKey is the device calendar day, zero padded', () {
      expect(ChatReturnPolicy.dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
    });
  });

  group('opener reveal is capped', () {
    final words = [for (var i = 0; i < 30; i++) 'word$i${i % 7 == 6 ? '.' : ''} '];

    int total(List<Duration> g) => g.fold<int>(0, (a, d) => a + d.inMilliseconds);

    test('without a cap the long text takes its natural time (several seconds)', () {
      expect(total(NaturalReveal.gapsFor(words)), greaterThan(3500));
    });

    test('with a 3 s cap the whole reveal fits, in the same rhythm', () {
      final gaps = NaturalReveal.gapsFor(words, maxTotal: const Duration(seconds: 3));
      expect(total(gaps), lessThanOrEqualTo(3100));
      final natural = NaturalReveal.gapsFor(words);
      // the pause after a sentence is still the longest
      final longest = gaps.indexOf(gaps.reduce((a, b) => a > b ? a : b));
      expect(natural[longest], natural.reduce((a, b) => a > b ? a : b));
    });

    test('a short text is not slowed down or sped up by the cap', () {
      final short = ['Hi ', 'there '];
      expect(NaturalReveal.gapsFor(short, maxTotal: const Duration(seconds: 3)), NaturalReveal.gapsFor(short));
    });
  });

  group('A3SessionPrefetch', () {
    setUp(A3SessionPrefetch.reset);

    test('nothing started: nothing to take', () {
      expect(A3SessionPrefetch.take(), isNull);
    });

    test('one request is started once and handed over exactly once', () async {
      var calls = 0;
      Future<ApiResponse<ChatSendResponse>?> opener(String lang) async {
        calls++;
        return null;
      }

      A3SessionPrefetch.start(language: 'fa', opener: opener);
      A3SessionPrefetch.start(language: 'fa', opener: opener); // a second start is ignored
      expect(calls, 1);
      expect(A3SessionPrefetch.take(), isNotNull);
      expect(A3SessionPrefetch.take(), isNull);
    });

    test('a request that is too old is not "the opener of this visit"', () {
      final started = DateTime(2026, 10, 30, 12);
      A3SessionPrefetch.start(language: 'en', now: started, opener: (_) async => null);
      expect(A3SessionPrefetch.take(now: started.add(A3SessionPrefetch.maxAge + const Duration(seconds: 1))), isNull);

      A3SessionPrefetch.start(language: 'en', now: started, opener: (_) async => null);
      expect(A3SessionPrefetch.take(now: started.add(const Duration(seconds: 30))), isNotNull);
    });
  });

  group('wiring (source contracts)', () {
    test('A1 starts the opener request as soon as the session is valid', () {
      final intro = _read('lib/features/intro/presentation/pages/intro_page.dart');
      expect(intro.contains('A3SessionPrefetch.start('), isTrue);
      expect(intro.indexOf('A3SessionPrefetch.start('), lessThan(intro.indexOf('_awaitIntroThenRoute();')));
      expect(intro.contains('s.isAuthenticated'), isTrue);
    });

    test('the chat takes the prefetched request instead of asking twice', () {
      final c = _read('lib/features/chat/state/chat_controller.dart');
      expect(c.contains('A3SessionPrefetch.take() ?? _openSessionSoft()'), isTrue);
      expect(c.contains('maxReveal: openerMaxReveal'), isTrue);
      expect(c.contains('static const Duration openerMaxReveal = Duration(seconds: 3);'), isTrue);
    });

    test('coming back to the app runs the return handling', () {
      final page = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
      expect(page.contains('_controller.handleReturn(pausedAt: away)'), isTrue);
      expect(page.contains('_pausedAt ??= DateTime.now()'), isTrue);
      final c = _read('lib/features/chat/state/chat_controller.dart');
      expect(c.contains('Future<void> handleReturn({required DateTime? pausedAt})'), isTrue);
      // a new day clears the thread; the same day collapses it behind the card
      expect(c.contains('messages.clear();'), isTrue);
      expect(c.contains('earlierTodayCollapsed = restoredTodayCount > 0;'), isTrue);
    });
  });
}
