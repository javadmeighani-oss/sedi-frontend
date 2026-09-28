import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/presentation/widgets/message_bubble.dart';

String _read(String path) => File(path).readAsStringSync();

Finder _decoratedUserBubble() {
  return find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  );
}

Finder _editHitTarget(Finder icon) {
  return find.ancestor(
    of: icon,
    matching: find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 44 && w.height == 44,
    ),
  );
}

Finder _userGroupAlign(Finder bubble) {
  return find.descendant(
    of: bubble,
    matching: find.byWidgetPredicate(
      (w) => w is Align && w.alignment == Alignment.centerRight,
    ),
  );
}

Future<void> _pumpUser({
  required WidgetTester tester,
  required String message,
  required TextDirection localeDirection,
  double width = 400,
  VoidCallback? onEdit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: localeDirection,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MessageBubble(
                message: message,
                isSedi: false,
                onEdit: onEdit ?? () {},
                editLabel: 'Edit',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

bool _isPhysicalRight(Rect host, Rect bubble) {
  return bubble.center.dx > host.center.dx &&
      (host.right - bubble.right) < (bubble.left - host.left);
}

void main() {
  test('edit icon is outside the decorated user bubble in source', () {
    final bubble = _read(
      'lib/features/chat/presentation/widgets/message_bubble.dart',
    );
    expect(bubble.contains('Icons.edit_outlined'), isTrue);
    expect(bubble.contains('Tooltip('), isTrue);
    expect(bubble.contains("editLabel ?? 'Edit'"), isTrue);
    expect(bubble.contains('widget.onEdit'), isTrue);
    expect(bubble.contains('physical-right'), isTrue);
    expect(bubble.contains('physical bottom-left'), isTrue);
    expect(bubble.contains('Alignment.centerRight'), isTrue);
    expect(bubble.contains('Alignment.centerLeft'), isTrue);
    expect(bubble.contains('AlignmentDirectional.centerEnd'), isFalse);
    expect(bubble.contains('resolveTextDirection'), isTrue);
    expect(bubble.contains('textDirection: textDirection'), isTrue);
    expect(bubble.contains('TextAlign.right'), isTrue);
    expect(bubble.contains('TextAlign.left'), isTrue);
    expect(bubble.contains('Read more'), isTrue);
    expect(bubble.contains('Read less'), isTrue);
    expect(bubble.contains('Tap to retry'), isTrue);
    expect(bubble.contains('clamp(0.0, 300.0)'), isTrue);
    expect(bubble.contains('available - actionW'), isFalse);
    expect(bubble.contains('left: -8'), isFalse);
    expect(bubble.contains('bottom: -6'), isFalse);
    expect(bubble.contains('SizedBox(height: 4)'), isTrue);

    final bubbleBlock = RegExp(
      r'decoration: BoxDecoration\([\s\S]*?child: body,',
    ).firstMatch(bubble)?.group(0);
    expect(bubbleBlock, isNotNull);
    expect(bubbleBlock!.contains('Icons.edit_outlined'), isFalse);
    expect(bubble.contains('width: 44'), isTrue);
    expect(bubble.contains('height: 44'), isTrue);
    expect(bubble.contains('size: 16'), isTrue);
    expect(bubble.contains('child: editAction'), isFalse);

    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );
    expect(page.contains('_scrollToBottom'), isTrue);
    expect(page.contains('Gate3ReturnToLatestButton'), isTrue);
    expect(page.contains('Gate3Composer'), isTrue);
    expect(page.contains('ScrollController'), isTrue);

    final composer = _read(
      'lib/features/gate3_interactive/presentation/widgets/gate3_composer.dart',
    );
    expect(composer.contains('onSendText'), isTrue);
    final chat = _read('lib/features/chat/state/chat_controller.dart');
    expect(chat.contains('class ChatController'), isTrue);
  });

  testWidgets('user edit icon is outside bubble; assistant has none',
      (tester) async {
    var taps = 0;
    const long =
        'This user message is long enough to collapse because it exceeds one hundred and twenty characters easily and must stay collapsed.';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(
                message: 'Short user text',
                isSedi: false,
                onEdit: () => taps++,
                editLabel: 'Edit',
              ),
              MessageBubble(
                message: long,
                isSedi: false,
                onEdit: () {},
                editLabel: 'Edit',
              ),
              const MessageBubble(
                message: 'Assistant reply',
                isSedi: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    expect(find.text('Edit'), findsNothing);
    expect(find.text('ویرایش'), findsNothing);
    expect(find.byType(Tooltip), findsWidgets);
    expect(find.text('Read more'), findsOneWidget);
    expect(find.text('Read less'), findsNothing);
    expect(
      find.descendant(
        of: _decoratedUserBubble().first,
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pump();
    expect(taps, 1);

    final shortIcon = find.byIcon(Icons.edit_outlined).first;
    final editHit = _editHitTarget(shortIcon);
    expect(editHit, findsOneWidget);
    expect(tester.getSize(editHit), const Size(44, 44));
    expect(tester.getSize(shortIcon), const Size(16, 16));

    final hitRect = tester.getRect(editHit);
    final bubbleRect = tester.getRect(_decoratedUserBubble().first);
    expect(hitRect.top, greaterThanOrEqualTo(bubbleRect.bottom));
    expect(hitRect.top - bubbleRect.bottom, inInclusiveRange(2, 8));
    expect(hitRect.left, closeTo(bubbleRect.left, 1.0));
    expect(hitRect.center.dx, lessThan(bubbleRect.center.dx));
    expect(hitRect.overlaps(bubbleRect), isFalse);

    final assistant = find.ancestor(
      of: find.text('Assistant reply'),
      matching: find.byType(MessageBubble),
    );
    expect(
      find.descendant(
        of: assistant,
        matching: find.byIcon(Icons.edit_outlined),
      ),
      findsNothing,
    );
  });

  testWidgets('LTR and RTL keep the user bubble on the physical right',
      (tester) async {
    Future<void> pumpDir(TextDirection dir, String message) {
      return _pumpUser(
        tester: tester,
        message: message,
        localeDirection: dir,
      );
    }

    await pumpDir(TextDirection.ltr, 'Hello');
    await tester.pump();
    final ltrHost = tester.getRect(find.byType(MessageBubble));
    final ltrAlign = tester.widget<Align>(_userGroupAlign(find.byType(MessageBubble)));
    expect(ltrAlign.alignment, Alignment.centerRight);
    final ltrDec = tester.getRect(_decoratedUserBubble());
    expect(_isPhysicalRight(ltrHost, ltrDec), isTrue);
    expect(ltrDec.right, greaterThan(ltrDec.left));
    final ltrText = tester.widget<Text>(find.text('Hello'));
    expect(ltrText.textDirection, TextDirection.ltr);
    expect(ltrText.textAlign, TextAlign.left);
    final ltrHit = tester.getRect(
      _editHitTarget(find.byIcon(Icons.edit_outlined)),
    );
    expect(ltrHit.top, greaterThanOrEqualTo(ltrDec.bottom));
    expect(ltrHit.left, closeTo(ltrDec.left, 1.0));
    expect(ltrHit.overlaps(ltrDec), isFalse);

    await pumpDir(TextDirection.rtl, 'Hello');
    await tester.pump();
    final rtlHost = tester.getRect(find.byType(MessageBubble));
    final rtlAlign = tester.widget<Align>(_userGroupAlign(find.byType(MessageBubble)));
    expect(rtlAlign.alignment, Alignment.centerRight);
    final rtlDec = tester.getRect(_decoratedUserBubble());
    expect(_isPhysicalRight(rtlHost, rtlDec), isTrue);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    final rtlHit = tester.getRect(
      _editHitTarget(find.byIcon(Icons.edit_outlined)),
    );
    expect(rtlHit.top, greaterThanOrEqualTo(rtlDec.bottom));
    expect(rtlHit.left, closeTo(rtlDec.left, 1.0));
    expect(rtlHit.overlaps(rtlDec), isFalse);
  });

  testWidgets('Persian user text is RTL/right-aligned; edit stays bottom-left',
      (tester) async {
    expect(MessageBubble.resolveTextDirection('سلام ۱۲۳'), TextDirection.rtl);
    expect(MessageBubble.resolveTextDirection('مرحبا 45'), TextDirection.rtl);
    expect(MessageBubble.resolveTextDirection('Hello ۱۲۳'), TextDirection.ltr);
    expect(
      MessageBubble.resolveTextDirection('سلام hello 42'),
      TextDirection.rtl,
    );
    expect(
      MessageBubble.resolveTextDirection('Hello سلام 42'),
      TextDirection.ltr,
    );

    await _pumpUser(
      tester: tester,
      message: 'سلام ۱۲۳',
      localeDirection: TextDirection.ltr,
    );
    await tester.pump();

    final userText = tester.widget<Text>(find.text('سلام ۱۲۳'));
    expect(userText.textDirection, TextDirection.rtl);
    expect(userText.textAlign, TextAlign.right);

    final faAlign = tester.widget<Align>(_userGroupAlign(find.byType(MessageBubble)));
    expect(faAlign.alignment, Alignment.centerRight);
    final hit = tester.getRect(
      _editHitTarget(find.byIcon(Icons.edit_outlined)),
    );
    final host = tester.getRect(find.byType(MessageBubble));
    final dec = tester.getRect(_decoratedUserBubble());
    expect(_isPhysicalRight(host, dec), isTrue);
    expect(hit.top, greaterThanOrEqualTo(dec.bottom));
    expect(hit.left, closeTo(dec.left, 1.0));
    expect(hit.overlaps(dec), isFalse);
  });

  testWidgets('FA locale keeps Persian bubble physical-right with RTL text',
      (tester) async {
    await _pumpUser(
      tester: tester,
      message: 'سلام دنیا',
      localeDirection: TextDirection.rtl,
    );
    await tester.pump();

    final userText = tester.widget<Text>(find.text('سلام دنیا'));
    expect(userText.textDirection, TextDirection.rtl);
    expect(userText.textAlign, TextAlign.right);
    final align = tester.widget<Align>(_userGroupAlign(find.byType(MessageBubble)));
    expect(align.alignment, Alignment.centerRight);
    final host = tester.getRect(find.byType(MessageBubble));
    final dec = tester.getRect(_decoratedUserBubble());
    expect(_isPhysicalRight(host, dec), isTrue);
    final hit = tester.getRect(
      _editHitTarget(find.byIcon(Icons.edit_outlined)),
    );
    expect(hit.top, greaterThanOrEqualTo(dec.bottom));
    expect(hit.left, closeTo(dec.left, 1.0));
    expect(hit.overlaps(dec), isFalse);
  });

  testWidgets('mixed Persian/Latin/numbers stay bidi-safe in the user bubble',
      (tester) async {
    const mixed = 'سلام hello 42';
    await _pumpUser(
      tester: tester,
      message: mixed,
      localeDirection: TextDirection.rtl,
    );
    await tester.pump();
    final userText = tester.widget<Text>(find.text(mixed));
    expect(userText.textDirection, TextDirection.rtl);
    expect(userText.textAlign, TextAlign.right);
    final host = tester.getRect(find.byType(MessageBubble));
    expect(
      _isPhysicalRight(host, tester.getRect(_decoratedUserBubble())),
      isTrue,
    );
  });

  testWidgets('edit does not reduce the approved user bubble max width',
      (tester) async {
    const long =
        'This user message is long enough to collapse because it exceeds one hundred and twenty characters easily and must stay collapsed.';
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          child: Column(
            children: [
              MessageBubble(
                message: long,
                isSedi: false,
                onEdit: _noop,
                editLabel: 'Edit',
              ),
              MessageBubble(
                message: long,
                isSedi: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final withEdit = tester.getSize(_decoratedUserBubble().at(0));
    final withoutEdit = tester.getSize(_decoratedUserBubble().at(1));
    expect(withEdit.width, closeTo(withoutEdit.width, 1.0));
    expect(withEdit.width, lessThanOrEqualTo(300));
    expect(withoutEdit.width, lessThanOrEqualTo(300));
  });
}

void _noop() {}
