// R-120 am.4 (Javad 2026-11-28, phone test): while Sedi was typing a doctor introduction, the whole list was typed inside ONE bubble and
// only split into the doctors' bubbles when the typing ended. From the first moment now: the opening line is typed in its bubble, each
// doctor's card appears whole (number, name, place, phone and link together) in its own bubble, one after another, then the closing text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/data/models/chat_link.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sedi_app/features/chat/state/chat_controller.dart';
import 'package:sedi_app/features/chat/state/natural_reveal.dart';

const _head = 'با بررسی سایت‌های معتبر، این پزشکان تأییدشده را برایت پیدا کردم:';
const _close = 'تماس بگیر و وقت ویزیتت را با من هماهنگ کن و مرا در جریان قرار بده.';

String _url(int i) => 'https://www.paziresh24.com/dr/doc-$i/';

final _doctors = [
  for (var i = 1; i <= 5; i++)
    ChatLink(
      label: 'دکتر شماره$i — قلب — پذیرش۲۴',
      url: _url(i),
      title: 'دکتر شماره$i — متخصص قلب',
      location: 'تهرانپارس، خیابان $i',
      linkText: 'صفحه‌ی پزشک در پذیرش۲۴',
      index: i,
      phone: i == 2 ? '' : '021-7787757$i',
    ),
];

// the backend text: the opening, the «•» lines (one with an indented second line), a blank line, the closing
final _message = [
  _head,
  for (var i = 1; i <= 5; i++) '• دکتر شماره$i — متخصص قلب، تهرانپارس',
  '  نزدیک‌ترین به محله‌ات',
  '',
  _close,
].join('\n');

bool _startsDoctor(String line) => _doctors.any((d) => d.startsDoctorLine(line));

void main() {
  test('each doctor line is ONE chunk and the chunks give the text back', () {
    final chunks = NaturalReveal.tokensKeepingItems(_message, _startsDoctor);
    expect(chunks.join(), _message);
    final doctorChunks = chunks.where(_startsDoctor).toList();
    expect(doctorChunks.length, 5);
    expect(doctorChunks.last.contains('نزدیک‌ترین به محله‌ات'), isTrue); // the indented second line stays with its doctor
    expect(chunks.first.startsWith('با'), isTrue);
    expect(chunks.where((c) => c.contains('•')).length, 5); // no doctor line is split into words
  });

  test('a doctor line is recognised by the doctor it belongs to only', () {
    final d = _doctors.first;
    expect(d.doctorName, 'دکتر شماره1');
    expect(d.startsDoctorLine('• دکتر شماره1 — متخصص قلب'), isTrue);
    expect(d.startsDoctorLine('• دکتر دیگری — قلب'), isFalse);
    expect(d.startsDoctorLine('دکتر شماره1 بدون علامت'), isFalse);
    expect(const ChatLink(label: 'x', url: 'https://a.ir/b').startsDoctorLine('• x'), isFalse); // not a provider card
  });

  test('text without doctors keeps the plain word-by-word reveal', () {
    const text = 'سلام، امروز حالت چطور است؟';
    expect(NaturalReveal.tokensKeepingItems(text, _startsDoctor), NaturalReveal.tokens(text));
  });

  testWidgets('during the reveal no doctor is ever typed inside the opening bubble; cards arrive one by one', (tester) async {
    final controller = ChatController();
    controller.revealSediMessageForTest(_message, links: _doctors);
    final counts = <int>[];
    var guard = 0;
    while (true) {
      await tester.pump(const Duration(milliseconds: 40));
      final revealed = controller.messages.where((m) => m.localId.startsWith('sedi-reveal')).toList();
      if (revealed.isEmpty) {
        if (++guard > 2000) break;
        continue;
      }
      final m = revealed.last;
      // every «•» doctor line already in the text has its card, so the bubble never shows it as typed text
      for (final d in _doctors) {
        final typed = m.text.split('\n').any(d.startsDoctorLine);
        if (typed) expect(m.links.contains(d), isTrue, reason: 'card of ${d.doctorName} missing while its line is shown');
      }
      if (counts.isEmpty || counts.last != m.links.length) counts.add(m.links.length);
      if (!controller.isSpeaking || ++guard > 2000) break;
    }
    expect(controller.messages.last.text, _message);
    expect(controller.messages.last.links.length, 5);
    expect(counts, [0, 1, 2, 3, 4, 5]); // the opening first, then the doctors one after another

    // a moment in the middle, drawn: the opening bubble + two cards, no «•» text, no closing bubble yet
    final partial = '${[_head, '• دکتر شماره1 — متخصص قلب، تهرانپارس', '• دکتر شماره2 — متخصص قلب، تهرانپارس'].join('\n')}\n';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: MessageBubble(message: partial, isSedi: true, links: _doctors.take(2).toList()))),
    ));
    expect(find.textContaining('• دکتر شماره'), findsNothing);
    expect(find.text(_head), findsOneWidget);
    expect(find.byKey(ValueKey('chat-doctor-${_url(1)}')), findsOneWidget);
    expect(find.byKey(ValueKey('chat-doctor-${_url(2)}')), findsOneWidget);
    expect(find.byKey(ValueKey('chat-doctor-${_url(3)}')), findsNothing);
    expect(find.textContaining('مرا در جریان'), findsNothing);
  });
}
