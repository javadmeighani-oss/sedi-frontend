import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/memory/memory_attachment.dart';
import 'package:sedi_app/core/memory/memory_overview.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_localization.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/gate3_memory_l10n.dart';
import 'package:sedi_app/features/gate3_interactive/presentation/widgets/gate3_attachment_flow.dart';

void main() {
  test('attachment metadata parses; bad payloads do not crash', () {
    final a = MemoryAttachment.tryParse({
      'id': 7,
      'kind': 'document',
      'status': 'ready',
      'summary': 'x',
      'findings': {
        'findings': [
          {'name': 'FBS', 'value': '118', 'unit': 'mg/dL'}
        ]
      },
      'confirmed': false,
    });
    expect(a, isNotNull);
    expect(a!.id, 7);
    expect(a.isAudio, isFalse);
    expect(a.findings!['findings'], isA<List>());
    expect(MemoryAttachment.tryParse(null), isNull);
    expect(MemoryAttachment.tryParse({'id': 'nope'}), isNull);
    expect(
      MemoryAttachment.tryParse({'id': 1, 'kind': 'audio', 'status': 'ready'})!
          .isAudio,
      isTrue,
    );
  });

  test('memory overview parses facts and timeline and tolerates garbage', () {
    final o = MemoryOverview.tryParse({
      'consent': true,
      'summary': 's',
      'facts': [
        {'id': 1, 'key': 'health_concerns', 'value': 'diabetes', 'editable': true},
        {'id': 'bad'},
      ],
      'timeline': [
        {'id': 3, 'kind': 'loss', 'title': 't', 'occurred_at': '2026-10-24T10:00:00'},
        'junk',
      ],
    });
    expect(o, isNotNull);
    expect(o!.facts.length, 1);
    expect(o.facts.first.editable, isTrue);
    expect(o.timeline.single.dateLabel, '2026-10-24');
    expect(MemoryOverview.tryParse('x'), isNull);
  });

  test('mime types are derived from the file name', () {
    expect(Gate3AttachmentFlow.mimeForName('a.PDF'), 'application/pdf');
    expect(Gate3AttachmentFlow.mimeForName('a.png'), 'image/png');
    expect(Gate3AttachmentFlow.mimeForName('/tmp/voice.m4a'), 'audio/mp4');
    expect(Gate3AttachmentFlow.mimeForName('scaled_1.jpg'), 'image/jpeg');
  });

  test('memory and attachment strings exist in fa/en/ar and keep the brand spelling', () {
    for (final lang in ['fa', 'en', 'ar']) {
      final l10n = Gate3Localization(lang);
      expect(l10n.memoryOpen, isNotEmpty);
      expect(l10n.attachRemember, isNotEmpty);
      expect(l10n.memoryFactLabel('health_concerns'), isNotEmpty);
      expect(l10n.memoryPageIntro.contains('سدی') || l10n.memoryPageIntro.contains('سدي'), isFalse);
    }
    expect(Gate3Localization('fa').attachTalkMessage('خلاصه'), contains('خلاصه'));
  });
}
