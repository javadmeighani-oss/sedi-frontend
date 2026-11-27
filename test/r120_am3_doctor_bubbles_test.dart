// R-120 am.3 (Javad 2026-11-27): five doctors = five bubbles. Each bubble carries the doctor's number, name and specialty, place, the phone his
// site publishes (tap = dial), an optional note and RIGHT UNDER them his link - all together. The opening and the closing keep their own bubbles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/models/chat_link.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';

const _head = 'با بررسی سایت‌های معتبر، این پزشکان تأییدشده را برایت پیدا کردم:';
const _close = 'تماس بگیر و مرا در جریان قرار بده.';

String _url(int i) => 'https://www.paziresh24.com/dr/doc-$i/';

void main() {
  late List<Uri> opened;
  late Future<bool> Function(Uri uri) original;
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

  final doctors = [
    for (var i = 1; i <= 5; i++)
      ChatLink(
        label: 'دکتر $i — قلب — پذیرش۲۴',
        url: _url(i),
        title: 'دکتر شماره$i — متخصص قلب',
        location: 'تهرانپارس، خیابان $i',
        linkText: 'صفحه‌ی پزشک در پذیرش۲۴',
        index: i,
        phone: i == 3 ? '' : '021-7787757$i',
      ),
  ];
  final message = '$_head\n${[for (var i = 1; i <= 5; i++) '• دکتر شماره$i — متخصص قلب، تهران'].join('\n')}\n\n$_close';

  test('the number and the phone are read; the phone becomes a dialable tel: URI', () {
    final link = ChatLink.fromJson({'label': 'x', 'url': _url(1), 'title': 't', 'index': 2, 'phone': '۰۲۱-۷۷۸۷۷۵۷۸'})!;
    expect(link.index, 2);
    expect(link.phoneUri, Uri(scheme: 'tel', path: '02177877578'));
    expect(const ChatLink(label: 'x', url: 'https://a.ir/b', phone: '12').phoneUri, isNull);
  });

  testWidgets('five doctors are five separate bubbles, each numbered with its phone and its link under it', (tester) async {
    await tester.pumpWidget(host(MessageBubble(message: message, isSedi: true, links: doctors)));
    final y = (Finder f) => tester.getTopLeft(f).dy;
    final cards = [for (var i = 1; i <= 5; i++) find.byKey(ValueKey('chat-doctor-${_url(i)}'))];
    for (final card in cards) {
      expect(card, findsOneWidget);
    }
    // every doctor sits in a DIFFERENT glass panel
    final panels = {
      for (final card in cards) tester.element(find.ancestor(of: card, matching: find.byType(DecoratedBox)).first).hashCode,
    };
    expect(panels.length, 5);
    // order: opening < 1 < 2 < … < 5 < closing; inside each: number+name < phone < link
    expect(y(find.text(_head)) < y(cards.first), isTrue);
    for (var i = 0; i < 4; i++) {
      expect(y(cards[i]) < y(cards[i + 1]), isTrue);
    }
    expect(y(cards.last) < y(find.text(_close)), isTrue);
    final number1 = find.textContaining('دکتر شماره1 — متخصص قلب');
    expect(tester.widget<Text>(number1).data!.startsWith(RegExp(r'^[1۱]\. ')), isTrue);
    final phone1 = find.byKey(ValueKey('chat-phone-${_url(1)}'));
    final link1 = find.byKey(ValueKey('chat-link-${_url(1)}'));
    expect(y(number1) < y(phone1) && y(phone1) < y(link1), isTrue);
    expect(find.byKey(ValueKey('chat-phone-${_url(3)}')), findsNothing); // no published phone: no phone line
    expect(find.textContaining('• دکتر شماره'), findsNothing); // the plain list is not repeated

    await tester.tap(phone1);
    await tester.pump();
    expect(opened.last, Uri(scheme: 'tel', path: '02177877571'));
    await tester.tap(link1);
    await tester.pump();
    expect(opened.last, Uri.parse(_url(1)));
  });

  testWidgets('a reply without doctor links stays one bubble', (tester) async {
    await tester.pumpWidget(host(const MessageBubble(message: 'سلام', isSedi: true)));
    expect(find.byType(DecoratedBox), findsWidgets);
    expect(find.textContaining('سلام'), findsOneWidget);
  });
}
