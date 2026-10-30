import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';

String _read(String path) => File(path).readAsStringSync();

/// P9 (Javad 2026-10-28): when the app is opened again on the same day, Sedi opens with a recap of today's earlier
/// chats; those chats sit behind one card the user can expand to read and continue from.
void main() {
  test('the controller collapses the restored day only when Sedi opened with a recap', () {
    final c = _read('lib/features/chat/state/chat_controller.dart');
    expect(c.contains('int restoredTodayCount = 0;'), isTrue);
    expect(c.contains('bool earlierTodayCollapsed = false;'), isTrue);
    expect(c.contains('restoredTodayCount = restored.length;'), isTrue);
    expect(c.contains('earlierTodayCollapsed = restoredTodayCount > 0;'), isTrue);
    // the flag is set inside the branch that adds the opener text, never unconditionally
    final i = c.indexOf('earlierTodayCollapsed = restoredTodayCount > 0;');
    expect(c.lastIndexOf('_addSediMessage(text, maxReveal: openerMaxReveal);', i) > c.lastIndexOf('if (text.isNotEmpty)', i), isTrue);
  });

  test('the chat window hides the earlier chats behind one expandable card', () {
    final page = _read('lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart');
    expect(page.contains('_EarlierTodayCard('), isTrue);
    expect(page.contains('_earlierTodayExpanded = !_earlierTodayExpanded'), isTrue);
    expect(page.contains('if (hideEarlier && i < _controller.restoredTodayCount) continue;'), isTrue);
    expect(page.contains('minHeight: 48'), isTrue); // touch target
  });

  test('the card label is localized in fa/en/ar', () {
    for (final lang in ['fa', 'en', 'ar']) {
      final l = Gate3Localization(lang);
      expect(l.earlierToday(1), isNotEmpty, reason: lang);
      expect(l.earlierToday(5).contains('5'), isTrue, reason: lang);
      expect(l.earlierTodayHide, isNotEmpty, reason: lang);
    }
    expect(Gate3Localization('fa').earlierToday(3), 'گفتگوهای قبلی امروز · 3 پیام');
  });
}
