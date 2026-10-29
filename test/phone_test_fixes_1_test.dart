import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/state/assistant_stream_pacer.dart';
import 'package:sedi_app/features/chat/state/natural_reveal.dart';
import 'package:sedi_app/features/devices/presentation/devices_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

/// Phone test 1 (Javad 2026-10-29): profile spacing, Lifestyle on one screen, formal gadgets text, the paperclip on the
/// left and mic / send on the right, and Sedi's text streamed slowly and naturally.
void main() {
  test('composer: paperclip physically left, mic / send physically right, in every language', () {
    final c = _read('lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart');
    expect(RegExp(r'Directionality\(\s*textDirection: TextDirection\.ltr,\s*child: Row\(').allMatches(c).length, 2);
    final attach = c.indexOf('_buildAttachButton(),');
    final primary = c.indexOf('_buildPrimaryAction(hasText),');
    expect(attach, lessThan(primary)); // left to right: attach ... primary
    expect(c.contains('textDirection: textDirection'), isTrue); // the typed text keeps its own direction
  });

  test('Sedi text is revealed word by word and the tokens join back to the original text', () {
    const text = 'سلام جواد جان! امروز چطوری؟ دلم می‌خواست یه احوالی ازت بپرسم.';
    final tokens = NaturalReveal.tokens(text);
    expect(tokens.length, 11);
    expect(tokens.join(), text);
    expect(NaturalReveal.tokens(''), isEmpty);
    expect(NaturalReveal.tokens('one'), ['one']);
  });

  test('the pauses are slow and natural: a sentence end waits longer than a comma, a comma longer than a word', () {
    final word = NaturalReveal.gapFor('word ');
    final comma = NaturalReveal.gapFor('word, ');
    final end = NaturalReveal.gapFor('word. ');
    final fa = NaturalReveal.gapFor('چطوری؟ ');
    expect(word.inMilliseconds, inInclusiveRange(120, 260)); // about five words a second
    expect(comma, greaterThan(word));
    expect(end, greaterThan(comma));
    expect(fa, greaterThan(comma));
    // a very long answer is revealed faster, never slower
    expect(NaturalReveal.gapFor('word ', total: 200), lessThan(word));
    expect(NaturalReveal.gapFor('word ', total: 100), lessThan(word));
  });

  test('the pacer honours a per-chunk gap and keeps its default cadence', () async {
    final seen = <String>[];
    final pacer = AssistantStreamPacer();
    pacer.enqueue('a ', seen.add, gap: const Duration(milliseconds: 5));
    pacer.enqueue('b ', seen.add, gap: const Duration(milliseconds: 5));
    pacer.enqueue('c', seen.add);
    expect(seen, ['a ']);
    await pacer.whenIdle;
    expect(seen, ['a ', 'b ', 'c']);
    expect(AssistantStreamPacer.revealDelay.inMilliseconds, 53);
  });

  test('the controller reveals EVERY Sedi message this way (stream chunks and one-piece answers)', () {
    final c = _read('lib/features/chat/state/chat_controller.dart');
    expect(c.contains('NaturalReveal.tokens(delta)'), isTrue);
    expect(c.contains('NaturalReveal.tokens(text)'), isTrue);
    expect(c.contains('_finishRevealNow()'), isTrue);
    expect(c.contains('pacer.whenIdle.then'), isTrue);
  });

  test('profile: the number and the pencil have room between them', () {
    final p = _read('lib/features/gate3_interactive/presentation/pages/gate3_profile_page.dart');
    expect(p.contains('padding: const EdgeInsets.symmetric(horizontal: 12)'), isTrue);
    expect(p.contains('textAlign: TextAlign.center'), isTrue);
  });

  test('lifestyle hub never scrolls', () {
    final p = _read('lib/features/lifestyle/presentation/pages/lifestyle_page.dart');
    expect(p.contains('return ListView('), isFalse);
    expect(p.contains('Everything fits ONE screen'), isTrue);
  });

  test('gadgets: one formal sentence, no mention of which gadget is being built', () {
    expect(DevicesL10n('fa').specialBody, 'به‌زودی گجت‌های تخصصی صدی برای مراقبت پیوسته‌ی شما در همین بخش متصل خواهند شد.');
    for (final lang in ['fa', 'ar', 'en']) {
      final body = DevicesL10n(lang).specialBody;
      expect(body.trim(), isNotEmpty);
      expect(body.contains('سدی'), isFalse);
    }
    expect(DevicesL10n('fa').specialBody.contains('ضربان'), isFalse);
    expect(DevicesL10n('en').specialBody.toLowerCase().contains('heart'), isFalse);
  });
}
