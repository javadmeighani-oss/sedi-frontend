// R-107 am.3 (Javad 2026-11-21): the links of a doctor introduction are blue underlined lines OUTSIDE the chat bubble and open the
// original site. Model / DTO / widget contract (the backend sends `links`; this app says `supports_links`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/dto/chat/chat_send_request.dart';
import 'package:sedi_app/data/dto/chat/chat_send_response.dart';
import 'package:sedi_app/data/models/chat_link.dart';
import 'package:sedi_app/data/models/chat_message.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';

const _pazireshUrl = 'https://www.paziresh24.com/dr/alef/';
const _drdrUrl = 'https://drdr.ir/doctors/be';

Map<String, dynamic> _link(String label, String url, [String kind = 'provider']) => {'label': label, 'url': url, 'kind': kind};

void main() {
  group('ChatLink', () {
    test('only a safe https URL with a label is accepted', () {
      expect(ChatLink.fromJson(_link('دکتر الف — پذیرش۲۴', _pazireshUrl))?.url, _pazireshUrl);
      for (final bad in <String>[
        'http://www.paziresh24.com/dr/x',
        'javascript:alert(1)',
        'data:text/html,hi',
        'file:///etc/passwd',
        'intent://x#Intent;end',
        'https://user:pass@evil.example/x',
        'https://nodot/x',
        'https://a.ir/x y',
        '',
      ]) {
        expect(ChatLink.fromJson(_link('x', bad)), isNull, reason: bad);
      }
      expect(ChatLink.fromJson(_link('', _pazireshUrl)), isNull);
      expect(ChatLink.fromJson('not a map'), isNull);
    });

    test('the list is cleaned: unsafe skipped, duplicates dropped, at most five', () {
      final raw = [
        _link('الف', _pazireshUrl),
        _link('ب', _drdrUrl),
        _link('الف دوباره', _pazireshUrl),
        _link('ناامن', 'http://x.ir/a'),
        for (var i = 0; i < 9; i++) _link('د$i', 'https://www.paziresh24.com/dr/$i'),
      ];
      final out = ChatLink.listFromJson(raw);
      expect(out.length, 5);
      expect(out.map((l) => l.label).take(2), ['الف', 'ب']);
      expect(ChatLink.listFromJson(null), isEmpty);
      expect(ChatLink.listFromJson('x'), isEmpty);
    });

    test('uri is the https Uri that may be opened', () {
      expect(const ChatLink(label: 'a', url: _pazireshUrl).uri, Uri.parse(_pazireshUrl));
      expect(const ChatLink(label: 'a', url: 'http://x.ir').uri, isNull);
    });
  });

  group('request / response / message', () {
    test('the app says it can show links', () {
      expect(const ChatSendRequest(message: 'سلام').toJson()['supports_links'], true);
    });

    test('the response carries the links and an old response has none', () {
      final res = ChatSendResponse.fromJson({
        'message': 'چند مورد پیدا کردم',
        'language': 'fa',
        'links': [_link('دکتر الف — پذیرش۲۴', _pazireshUrl)],
      });
      expect(res.links.single.label, 'دکتر الف — پذیرش۲۴');
      expect(ChatSendResponse.fromJson({'message': 'x', 'language': 'fa'}).links, isEmpty);
    });

    test('a message keeps its links through copyWith and can receive them', () {
      final base = ChatMessage.assistant(text: 'متن', links: const [ChatLink(label: 'a', url: _pazireshUrl)]);
      expect(base.copyWith(text: 'متن بیشتر').links.length, 1);
      expect(ChatMessage.assistant(text: 'x').copyWith(links: base.links).links.length, 1);
      expect(ChatMessage.assistant(text: 'x').links, isEmpty);
    });
  });

  group('MessageBubble', () {
    late List<Uri> opened;
    late Future<bool> Function(Uri) original;

    setUp(() {
      opened = <Uri>[];
      original = MessageBubble.linkOpener;
      MessageBubble.linkOpener = (uri) async {
        opened.add(uri);
        return true;
      };
    });
    tearDown(() => MessageBubble.linkOpener = original);

    Widget host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

    const links = [
      ChatLink(label: 'دکتر الف — پذیرش۲۴', url: _pazireshUrl),
      ChatLink(label: 'دکتر ب — دکتر دکتر', url: _drdrUrl),
    ];

    testWidgets('each link is a blue underlined line BELOW the message text, and a tap opens the original site', (tester) async {
      await tester.pumpWidget(host(const MessageBubble(message: 'چند مورد پیدا کردم:', isSedi: true, links: links)));
      final label = find.text('دکتر الف — پذیرش۲۴');
      expect(label, findsOneWidget);
      final style = tester.widget<Text>(label).style!;
      expect(style.color, MessageBubble.linkColor);
      expect(style.decoration, TextDecoration.underline);
      // outside the bubble: it sits under the message text
      expect(tester.getTopLeft(label).dy, greaterThan(tester.getBottomLeft(find.text('چند مورد پیدا کردم:')).dy));
      // a 44 dp touch target
      expect(tester.getSize(find.byKey(const ValueKey('chat-link-$_pazireshUrl'))).height, greaterThanOrEqualTo(44));

      await tester.tap(find.byKey(const ValueKey('chat-link-$_drdrUrl')));
      await tester.pump();
      expect(opened, [Uri.parse(_drdrUrl)]);
    });

    testWidgets('a phone that cannot open the link shows the address instead of failing silently', (tester) async {
      MessageBubble.linkOpener = (uri) async => false;
      await tester.pumpWidget(host(const MessageBubble(message: 'متن', isSedi: true, links: links)));
      await tester.tap(find.byKey(const ValueKey('chat-link-$_pazireshUrl')));
      await tester.pump();
      expect(find.text(_pazireshUrl), findsOneWidget);
    });

    testWidgets('a message without links shows none, and the user bubble never shows links', (tester) async {
      await tester.pumpWidget(host(const MessageBubble(message: 'سلام', isSedi: true)));
      expect(find.byType(InkWell), findsNothing);
      await tester.pumpWidget(host(const MessageBubble(message: 'سلام', isSedi: false, links: links)));
      expect(find.text('دکتر الف — پذیرش۲۴'), findsNothing);
    });
  });
}
