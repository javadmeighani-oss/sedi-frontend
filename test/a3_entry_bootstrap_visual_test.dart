import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/locale/sedi_locale_controller.dart';
import 'package:sedi_app/features/chat/state/chat_controller.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('A3 first-frame visual language follows SediLocaleController', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );

    expect(
      page.contains(
        'final presentationLang = SediLocaleController.instance.languageCode;',
      ),
      isTrue,
    );
    expect(page.contains('lang: presentationLang'), isTrue);
    expect(page.contains('lang: _controller.currentLanguage'), isFalse);

    expect(ChatController().currentLanguage, 'en');
    expect(SediLocaleController.instance.languageCode, isNotEmpty);
  });

  test('initializing empty A3 surface is transparent and hides empty hint', () {
    final page = _read(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    );

    expect(page.contains('ConversationState.initializing'), isTrue);
    expect(page.contains('emptyConversationHint'), isTrue);

    final initIdx = page.indexOf('ConversationState.initializing');
    final hintIdx = page.indexOf('l10n.emptyConversationHint');
    expect(initIdx, greaterThan(-1));
    expect(hintIdx, greaterThan(initIdx));

    final initializingBlock = page.substring(initIdx, hintIdx);
    expect(initializingBlock.contains('emptyConversationHint'), isFalse);
    expect(initializingBlock.contains('Color(0x00000000)'), isTrue);
    expect(initializingBlock.contains('Colors.red'), isFalse);
    expect(initializingBlock.contains('dangerRed'), isFalse);
    expect(page.contains('Colors.red'), isFalse);
    expect(page.contains('AppTheme.dangerRed'), isFalse);

    expect(
      Gate3Localization('en').emptyConversationHint,
      'Your conversation will appear here.',
    );
  });
}
