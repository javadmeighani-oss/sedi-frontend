import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/copy/sedi_copy.dart';
import 'package:sedi_app/data/dto/chat/chat_send_response.dart';
import 'package:sedi_app/data/models/notification_feedback.dart' show kFeedbackReasonValues;
import 'package:sedi_app/features/notifications/presentation/notification_inbox_l10n.dart';
import 'package:sedi_app/features/notifications/presentation/widgets/dislike_reason_sheet.dart';

String _read(String path) => File(path).readAsStringSync();

/// R-073 (2F, in-app package): the approved design - one-tap answers inside Sedi's own message box, the glass reason panel,
/// the label «فعلاً نه», and no second place that asks the same reason (the backend asks it in Sedi's first message).
void main() {
  group('followup_ask from the backend', () {
    Map<String, dynamic> body(Object? ask) => {'message': 'سلام', 'language': 'fa', 'followup_ask': ask};

    test('the labels are read in order from {id, label} options', () {
      final r = ChatSendResponse.fromJson(body({
        'kind': 'reason',
        'notification_id': 7,
        'options': [
          {'id': 'busy_now', 'label': 'درگیر بودم'},
          {'id': 'rest_time', 'label': 'وقت استراحتم بود'},
          {'id': 'other', 'label': 'دلیل دیگری دارم'},
        ],
      }));
      expect(r.followupAskLabels, ['درگیر بودم', 'وقت استراحتم بود', 'دلیل دیگری دارم']);
    });

    test('plain string options work, blanks are skipped', () {
      final r = ChatSendResponse.fromJson(body({
        'options': ['I did it', '  ', {'label': ''}, "I couldn't"],
      }));
      expect(r.followupAskLabels, ['I did it', "I couldn't"]);
    });

    test('a missing, null or malformed field means no answers and never throws', () {
      expect(ChatSendResponse.fromJson({'message': 'x', 'language': 'fa'}).followupAskLabels, isEmpty);
      expect(ChatSendResponse.fromJson(body(null)).followupAskLabels, isEmpty);
      expect(ChatSendResponse.fromJson(body('nonsense')).followupAskLabels, isEmpty);
      expect(ChatSendResponse.fromJson(body({'options': 'nope'})).followupAskLabels, isEmpty);
      expect(ChatSendResponse.fromJson(body({'kind': 'reason'})).followupAskLabels, isEmpty);
    });
  });

  group('the label and the wording (fa / ar / en)', () {
    test('the negative-feedback button is «فعلاً نه» / «ليس الآن» / "Not now" in the tray and the inbox', () {
      for (final key in ['tray.action.dislike', 'inbox.dislikeAction']) {
        expect(SediCopy.t(key, 'fa'), 'فعلاً نه');
        expect(SediCopy.t(key, 'ar'), 'ليس الآن');
        expect(SediCopy.t(key, 'en'), 'Not now');
      }
      expect(SediCopy.t('tray.action.dislike', 'fa').contains('نپسندیدن'), isFalse);
    });

    test('the question and the hint follow the label', () {
      expect(NotificationInboxL10n('fa').dislikeReasonTitle, 'چرا فعلاً نه؟');
      expect(NotificationInboxL10n('ar').dislikeReasonTitle, 'لماذا ليس الآن؟');
      expect(NotificationInboxL10n('en').dislikeReasonTitle, 'Why not now?');
      for (final lang in ['fa', 'ar', 'en']) {
        final l10n = NotificationInboxL10n(lang);
        expect(l10n.dislikeReasonHint.trim(), isNotEmpty, reason: lang);
        expect(l10n.dislikeReasonMore.trim(), isNotEmpty, reason: lang);
      }
    });

    test('every reason has a label in every language; the three «not now» answers come first', () {
      expect(kPrimaryReasons, ['busy_now', 'rest_time', 'not_in_mood']);
      for (final lang in ['fa', 'ar', 'en']) {
        for (final r in kFeedbackReasonValues) {
          expect(NotificationInboxL10n(lang).dislikeReasonLabel(r).trim(), isNotEmpty, reason: '$lang $r');
        }
      }
      expect(NotificationInboxL10n('fa').dislikeReasonLabel('busy_now'), 'الان درگیرم');
      expect(NotificationInboxL10n('fa').dislikeReasonLabel('rest_time'), 'وقت استراحتم است');
      expect(NotificationInboxL10n('fa').dislikeReasonLabel('not_in_mood'), 'حوصله ندارم');
    });
  });

  group('the grown tray notification (R-073)', () {
    test('the tray answers are short in every language (three equal buttons)', () {
      for (final lang in ['fa', 'ar', 'en']) {
        for (final r in ['busy_now', 'rest_time', 'not_in_mood']) {
          final label = SediCopy.t('tray.reason.$r', lang);
          expect(label.trim(), isNotEmpty, reason: '$lang $r');
          expect(label.length, lessThanOrEqualTo(12), reason: '$lang $r: $label');
        }
      }
      expect(SediCopy.t('tray.reason.rest_time', 'fa'), 'در استراحتم');
    });

    test('the tray uses the short answers and keeps the notification title as the first block', () {
      final src = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(src.contains("SediCopy.t('tray.reason.\$r', lang)"), isTrue);
      expect(src.contains('contentTitle: title'), isTrue); // the standard fallback keeps the notification title too
      expect(src.contains('static String promptHtml('), isTrue);
    });
  });

  group('the glass reason panel', () {
    testWidgets('a reason pill answers with one tap and is at least 44 dp high (52 dp for the large one)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ReasonPill(label: 'الان درگیرم', large: true, onTap: () => taps++),
                ReasonPill(label: 'نامفهوم بود', large: false, onTap: () => taps += 10),
              ],
            ),
          ),
        ),
      );
      final large = tester.getSize(find.widgetWithText(ReasonPill, 'الان درگیرم'));
      final small = tester.getSize(find.widgetWithText(ReasonPill, 'نامفهوم بود'));
      expect(large.height, greaterThanOrEqualTo(52));
      expect(small.height, greaterThanOrEqualTo(44));
      await tester.tap(find.text('الان درگیرم'));
      await tester.tap(find.text('نامفهوم بود'));
      expect(taps, 11);
    });

    test('the panel is liquid glass with the three answers first, then «another reason»', () {
      final src = _read('lib/features/notifications/presentation/widgets/dislike_reason_sheet.dart');
      expect(src.contains('SediGlass.blur('), isTrue);
      expect(src.contains('backgroundColor: Colors.transparent'), isTrue);
      expect(src.indexOf('for (final r in kPrimaryReasons)'), lessThan(src.indexOf('l10n.dislikeReasonMore')));
      expect(src.contains('ActionChip'), isFalse); // the old plain sheet is gone
    });
  });

  group('one-tap answers sit INSIDE Sedi\'s message box', () {
    test('the message bubble draws them in the same glass panel, behind a hairline, and a tap is an ordinary message', () {
      final src = _read('lib/features/chat/presentation/widgets/message_bubble.dart');
      expect(src.contains('final List<String> replies;'), isTrue);
      expect(src.contains('widget.isSedi && widget.replies.isNotEmpty && widget.onReply != null'), isTrue);
      expect(src.contains('class _QuickReplyChip'), isTrue);
      expect(src.contains('minHeight: 44'), isTrue);
      // inside the panel: the replies are part of `column`, which the Sedi panel wraps
      expect(src.indexOf('_QuickReplyChip(label: reply'), lessThan(src.indexOf('final body = widget.isSedi')));
    });

    test('the controller keeps them from the opener and clears them when the user speaks', () {
      final src = _read('lib/features/chat/state/chat_controller.dart');
      expect(src.contains('List<String> quickReplies = const <String>[];'), isTrue);
      expect(src.contains('quickReplies = List<String>.from(data.followupAskLabels);'), isTrue);
      expect(src.contains('quickReplies = List<String>.from(asks);'), isTrue);
      final send = src.indexOf('Future<void> sendUserMessage(');
      expect(src.indexOf('quickReplies = const <String>[];', send), greaterThan(send));
    });

    test('a later Sedi message never inherits the answers of the opener (presentation starters, new Sedi messages)', () {
      final src = _read('lib/features/chat/state/chat_controller.dart');
      final add = src.indexOf('void _addSediMessage(');
      expect(src.indexOf('quickReplies = const <String>[];', add), lessThan(src.indexOf('isThinking = false;', add)));
      final insert = src.indexOf('void insertPresentationAssistantMessage(');
      expect(src.indexOf('quickReplies = const <String>[];', insert), greaterThan(insert));
      expect(src.indexOf('quickReplies = const <String>[];', insert), lessThan(src.indexOf('messages.add(ChatMessage.assistant(text: trimmed));', insert)));
    });

    test('the page shows them on the last Sedi message only, after she has finished speaking, and sends the tapped label', () {
      final src = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
      expect(src.contains('msgIndex == _controller.messages.length - 1'), isTrue);
      expect(src.contains('!_controller.isSpeaking'), isTrue);
      expect(src.contains('onReply: showReplies ? (reply) => _controller.sendUserMessage(reply) : null'), isTrue);
    });
  });

  group('the reason is asked in ONE place', () {
    test('the chat page no longer opens a bottom sheet for a tray dislike, and the tray no longer stores one for it', () {
      final page = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
      expect(page.contains('_askPendingDislikeReason'), isFalse);
      expect(page.contains('showDislikeReasonSheet('), isFalse);
      expect(page.contains('PendingDislikeReasons'), isFalse);
      final bg = _read('lib/core/notifications/background_notification_action_handler.dart');
      expect(bg.contains('PendingDislikeReasons'), isFalse);
      expect(File('lib/core/notifications/pending_dislike_reasons.dart').existsSync(), isFalse);
    });

    test('the inbox still asks with the glass panel (the user is already in the notification list)', () {
      final inbox = _read('lib/features/notifications/presentation/pages/notification_inbox_page.dart');
      expect(inbox.contains('showDislikeReasonSheet('), isTrue);
    });
  });
}
