import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/history_response.dart';
import 'package:sedi_app/data/models/chat_message.dart';
import 'package:sedi_app/features/chat/state/chat_controller.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';
import 'package:sedi_app/features/lifestyle/presentation/pages/lifestyle_history_page.dart';

HistoryResponse _history({
  String? currentGroupKey,
  String timezone = 'Asia/Tehran',
  required List<HistoryGroupItem> items,
}) {
  return HistoryResponse(
    group: 'daily',
    timezone: timezone,
    currentGroupKey: currentGroupKey,
    items: items,
  );
}

HistoryGroupItem _day(
  String key,
  List<HistoryTurnItem> turns,
) =>
    HistoryGroupItem(key: key, turns: turns);

HistoryTurnItem _turn({
  required int id,
  required String createdAt,
  required String userMessage,
  String? sediResponse,
}) {
  return HistoryTurnItem(
    id: id,
    createdAt: createdAt,
    userMessage: userMessage,
    sediResponse: sediResponse,
  );
}

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('A3 current-day restore', () {
    final userPad = '  keep leading  \nkeep trailing  ';
    final sediPad = 'Sedi original\n\n  spaced  ';
    final created = '2026-09-25T08:01:02.000Z';
    final hist = _history(
      currentGroupKey: '2026-09-25',
      items: [
        _day('2026-09-24', [
          _turn(
            id: 1,
            createdAt: '2026-09-24T10:00:00.000Z',
            userMessage: 'yesterday user',
            sediResponse: 'yesterday sedi',
          ),
        ]),
        _day('2026-09-25', [
          _turn(
            id: 10,
            createdAt: created,
            userMessage: userPad,
            sediResponse: sediPad,
          ),
          _turn(
            id: 11,
            createdAt: '2026-09-25T09:00:00.000Z',
            userMessage: 'second user',
            sediResponse: 'second sedi',
          ),
        ]),
      ],
    );

    test('restores current-day group only, in backend order, original text', () {
      final messages = currentDayMessagesFromHistory(hist);
      expect(messages.length, 4);
      expect(messages.map((m) => m.localId).toList(), [
        'history-10-user',
        'history-10-sedi',
        'history-11-user',
        'history-11-sedi',
      ]);
      expect(messages[0].role, ChatRole.user);
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[2].role, ChatRole.user);
      expect(messages[3].role, ChatRole.assistant);
      expect(messages.every((m) => m.status == ChatMessageStatus.sent), isTrue);
      expect(messages[0].text, userPad);
      expect(messages[1].text, sediPad);
      expect(messages[0].text.contains('keep leading'), isTrue);
      expect(messages.any((m) => m.text.contains('yesterday')), isFalse);
      expect(messages[0].createdAt, DateTime.parse(created));
      expect(messages[1].createdAt, DateTime.parse(created));
    });

    test('missing currentGroupKey restores nothing', () {
      final none = currentDayMessagesFromHistory(
        _history(
          currentGroupKey: null,
          items: hist.items,
        ),
      );
      expect(none, isEmpty);
    });

    test('absent current-day group restores nothing', () {
      final none = currentDayMessagesFromHistory(
        _history(
          currentGroupKey: '2026-09-26',
          items: hist.items,
        ),
      );
      expect(none, isEmpty);
    });
  });

  group('History archive authority', () {
    test('currentGroupKey excludes current day and fail-closes when absent', () {
      final hist = _history(
        currentGroupKey: '2026-09-25',
        items: [
          _day('2026-09-24', []),
          _day('2026-09-25', []),
        ],
      );
      final days = archiveDaysFromHistory(hist);
      expect(days, isNotNull);
      expect(days!.map((g) => g.key), ['2026-09-24']);
      expect(archiveDaysFromHistory(_history(items: hist.items)), isNull);
    });

    test('raw transcript display keeps stored copy, trim is emptiness-only', () {
      const stored = '  original  \nline  ';
      expect(exactStoredTranscriptText(stored), stored);
      expect(exactStoredTranscriptText('   '), isNull);
      expect(exactStoredTranscriptText(null), isNull);
    });

    test('summary remains independent of raw archive fail-closed state', () {
      expect(LifestyleL10n('en').archiveTemporarilyUnavailable, isNotEmpty);
      expect(LifestyleL10n('fa').archiveTemporarilyUnavailable, isNotEmpty);
      expect(LifestyleL10n('ar').archiveTemporarilyUnavailable, isNotEmpty);
    });
  });

  group('A3 initialize contract', () {
    test('restore is JWT-only, fail-soft, after profile, before openers', () {
      final src = _read('lib/features/chat/state/chat_controller.dart');
      expect(src.contains("if (_initialized)"), isTrue);
      expect(
        src.indexOf('UserProfileManager.loadProfile()'),
        lessThan(src.indexOf('_restoreCurrentDayTranscript()')),
      );
      expect(
        src.indexOf('await _restoreCurrentDayTranscript();'),
        lessThan(src.indexOf('if (initialMessage != null)')),
      );
      // A1->A3 speed: the opener request is STARTED before history loads (no initial message only) ...
      expect(
        src.indexOf('initialMessage == null ? _openSessionSoft() : null'),
        lessThan(src.indexOf('await _restoreCurrentDayTranscript();')),
      );
      // ... but its text is added only after the restore finished, so the order of messages is unchanged.
      expect(
        src.indexOf('await _restoreCurrentDayTranscript();'),
        lessThan(src.indexOf('await openFuture!')),
      );
      expect(
        src.indexOf('if (initialMessage != null)'),
        lessThan(src.indexOf('await openFuture!')),
      );
      expect(src.contains("'/memory/history'"), isTrue);
      expect(src.contains("'group': 'daily'"), isTrue);
      expect(src.contains("'limit': '40'"), isTrue);
      expect(src.contains("'offset': '0'"), isTrue);
      expect(src.contains("'user_id'"), isFalse);
      expect(src.contains('user_id'), isFalse);
      expect(src.contains('currentDayMessagesFromHistory'), isTrue);
      expect(src.contains('messages.addAll(restored)'), isTrue);
      expect(src.contains('messages.clear()'), isFalse);
      expect(src.contains('_restoreCurrentDayTranscript'), isTrue);
      expect(src.contains('current-day history restore failed'), isTrue);
      final restoreBlock = src.substring(
        src.indexOf('Future<void> _restoreCurrentDayTranscript()'),
        src.indexOf('Future<void> sendUserMessage'),
      );
      expect(restoreBlock.contains('DateTime.now()'), isFalse);
      expect(restoreBlock.contains('YYYY'), isFalse);
      expect(src.contains('SharedPreferences'), isFalse);
      expect(src.contains('openSession'), isTrue);
    });
  });

  group('History page contract', () {
    test('no device-day fallback; exact raw display; summary chips stay', () {
      final src = _read(
        'lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart',
      );
      expect(src.contains('_todayKey'), isFalse);
      expect(src.contains('DateTime.now()'), isFalse);
      expect(src.contains('currentGroupKey'), isTrue);
      expect(src.contains('archiveTemporarilyUnavailable'), isTrue);
      expect(src.contains("substring("), isFalse);
      expect(src.contains('exactStoredTranscriptText'), isTrue);
      // pilot V1: no summaries card any more, only the day list and the calendar
      expect(src.contains("'/memory/period-summary'"), isFalse);
      expect(src.contains('_loadSummary()'), isFalse);
      expect(src.contains('_loadHistory()'), isTrue);
    });
  });
}
