// R-120 am.2 (Javad 2026-11-26): a doctor introduction is ONE bubble - the opening line, then each doctor's name + specialty, his place, an
// optional «worth the trip» note, and RIGHT UNDER them the blue link to his page; then the rest of the reply. Older replies keep the links
// below the bubble; search links stay below too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/models/chat_link.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';

const _a = 'https://www.paziresh24.com/dr/a/';
const _b = 'https://www.paziresh24.com/dr/b/';
const _search = 'https://www.paziresh24.com/s/tehran/cardiovascular/';
const _head = 'با بررسی سایت‌های معتبر، این پزشکان تأییدشده را برایت پیدا کردم:';
const _message = '$_head\n• دکتر الف — متخصص قلب، تهران؛ آدرس: تهرانپارس\n   دلیل\n• دکتر ب — متخصص قلب، تهران\n\nتماس بگیر و مرا در جریان قرار بده.';

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

  const doctors = [
    ChatLink(label: 'دکتر الف — متخصص قلب — پذیرش۲۴', url: _a, title: 'دکتر الف — متخصص قلب', location: 'تهرانپارس، خیابان ۱۹۶', linkText: 'صفحه‌ی پزشک در پذیرش۲۴'),
    ChatLink(label: 'دکتر ب — متخصص قلب — پذیرش۲۴', url: _b, title: 'دکتر ب — متخصص قلب', location: 'شهرک غرب', note: 'از محله‌ات دورتر است، ولی ارزش ویزیت دارد.', linkText: 'صفحه‌ی پزشک در پذیرش۲۴'),
  ];

  test('the reply text is split around the doctor lines (which the list replaces)', () {
    final split = DoctorListSplit.of(_message, ['دکتر الف', 'دکتر ب']);
    expect(split.head, _head);
    expect(split.tail, 'تماس بگیر و مرا در جریان قرار بده.');
    expect(DoctorListSplit.of('فقط یک جمله', ['دکتر الف']).head, 'فقط یک جمله');
  });

  test('a doctor without a drawn link and other bulleted lines stay visible (Codex P2, PR 34)', () {
    const msg = '$_head\n• دکتر الف — قلب\n   دلیل\n• دکتر بی‌لینک — قلب، تهران\n\n• نکته‌ی مراقبتی\nپایان';
    final split = DoctorListSplit.of(msg, ['دکتر الف']);
    expect(split.head, _head);
    expect(split.tail, '• دکتر بی‌لینک — قلب، تهران\n\n• نکته‌ی مراقبتی\nپایان');
  });

  test('the doctor line, place, note and link text are read from the backend', () {
    final link = ChatLink.fromJson({'label': 'x', 'url': _a, 'kind': 'provider', 'title': 'دکتر الف — قلب', 'location': 'تهرانپارس', 'note': 'n', 'link_text': 'صفحه'})!;
    expect([link.title, link.location, link.note, link.linkText, link.inBubble], ['دکتر الف — قلب', 'تهرانپارس', 'n', 'صفحه', true]);
    expect(ChatLink.fromJson({'label': 'x', 'url': _a})!.inBubble, isFalse); // an older reply
  });

  testWidgets('each doctor sits INSIDE the bubble with his link right under him; the text keeps its opening and its close', (tester) async {
    await tester.pumpWidget(host(const MessageBubble(message: _message, isSedi: true, links: doctors)));
    expect(find.text(_head), findsOneWidget);
    expect(find.textContaining('• دکتر الف'), findsNothing); // the plain list is not shown twice
    final titleA = find.text('دکتر الف — متخصص قلب');
    final linkA = find.byKey(const ValueKey('chat-link-$_a'));
    final titleB = find.text('دکتر ب — متخصص قلب');
    expect(titleA, findsOneWidget);
    expect(find.text('تهرانپارس، خیابان ۱۹۶'), findsOneWidget);
    expect(find.text('از محله‌ات دورتر است، ولی ارزش ویزیت دارد.'), findsOneWidget);
    // order: opening line < doctor A < his link < doctor B < close
    final y = (Finder f) => tester.getTopLeft(f).dy;
    expect(y(find.text(_head)) < y(titleA) && y(titleA) < y(linkA) && y(linkA) < y(titleB), isTrue);
    expect(y(titleB) < y(find.text('تماس بگیر و مرا در جریان قرار بده.')), isTrue);
    final linkText = tester.widget<Text>(find.descendant(of: linkA, matching: find.text('صفحه‌ی پزشک در پذیرش۲۴')));
    expect(linkText.style!.color, MessageBubble.linkColor);
    expect(linkText.style!.decoration, TextDecoration.underline);
    expect(tester.getSize(linkA).height, greaterThanOrEqualTo(44));
    await tester.tap(linkA);
    await tester.pump();
    expect(opened, [Uri.parse(_a)]);
  });

  testWidgets('a search link still sits below the bubble, an older reply keeps its lines below', (tester) async {
    const mixed = [...doctors, ChatLink(label: 'جست‌وجو در پذیرش۲۴', url: _search, kind: 'search')];
    await tester.pumpWidget(host(const MessageBubble(message: _message, isSedi: true, links: mixed)));
    expect(tester.getTopLeft(find.text('جست‌وجو در پذیرش۲۴')).dy,
        greaterThan(tester.getTopLeft(find.text('تماس بگیر و مرا در جریان قرار بده.')).dy));
    const older = [ChatLink(label: 'دکتر الف — پذیرش۲۴', url: _a)];
    await tester.pumpWidget(host(const MessageBubble(message: _message, isSedi: true, links: older)));
    expect(find.textContaining('• دکتر الف'), findsOneWidget); // nothing to rebuild: the text stays as sent
    expect(find.text('دکتر الف — پذیرش۲۴'), findsOneWidget);
  });
}
