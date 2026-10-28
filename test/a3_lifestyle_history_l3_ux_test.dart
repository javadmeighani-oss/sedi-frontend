import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/lifestyle/presentation/lifestyle_l10n.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('L3 History is a white memory explorer without Talk to Sedi', () {
    final src = _read(
      'lib/features/lifestyle/presentation/pages/lifestyle_history_page.dart',
    );
    expect(src.contains('A3DestinationSurface.canvas'), isTrue);
    expect(src.contains('gate3PaleOliveBackground'), isFalse);
    expect(src.contains('A3DestinationCard'), isTrue);
    expect(src.contains('/memory/history'), isTrue);
    expect(src.contains('/memory/period-summary'), isTrue);
    expect(src.contains("'user_id'"), isFalse);
    expect(src.contains('daily'), isTrue);
    expect(src.contains('weekly'), isTrue);
    expect(src.contains('monthly'), isTrue);
    expect(src.contains('yearly'), isTrue);
    expect(src.contains('openLifestyleChat'), isFalse);
    expect(src.contains('lifestyle_page.dart'), isFalse);
    expect(src.contains('l10n.openChat'), isFalse);
    expect(src.contains('historyExplain'), isTrue);
    expect(src.contains("'group': 'daily'"), isTrue);
    expect(src.contains('currentGroupKey'), isTrue);
    expect(src.contains('DateTime.now()'), isFalse);
    expect(src.contains('_todayKey'), isFalse);
    expect(src.contains('archiveTemporarilyUnavailable'), isTrue);
    expect(src.contains('exactStoredTranscriptText'), isTrue);
    expect(src.contains('formatIsoForProfileDisplay'), isTrue);
    expect(src.contains('substring(0, 80)'), isFalse);
    expect(src.contains('recentConversations'), isFalse);
    expect(src.contains('MessageBubble'), isFalse);
    expect(src.contains('onEdit'), isFalse);
    expect(src.contains('Read more'), isFalse);
    expect(src.contains('I6'), isFalse);
    expect(src.contains('I7'), isFalse);

    final explainEn = LifestyleL10n('en').historyExplain.toLowerCase();
    expect(explainEn.contains('ask sedi'), isFalse);
    expect(explainEn.contains('in chat'), isFalse);
    expect(explainEn.contains('30 days'), isTrue);
    expect(LifestyleL10n('en').recentDays, isNotEmpty); // H1: recent days replace the in-place transcript list
    expect(explainEn.contains('retention'), isFalse);
    expect(LifestyleL10n('fa').historyExplain.contains('چت'), isFalse);
    expect(LifestyleL10n('ar').historyExplain.contains('الدردشة'), isFalse);
    expect(LifestyleL10n('en').conversationsLast30Days, isNotEmpty);
    expect(LifestyleL10n('fa').conversationsLast30Days, isNotEmpty);
    expect(LifestyleL10n('ar').conversationsLast30Days, isNotEmpty);
  });
}
