import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/memory/memory_attachment.dart';

/// R-074 step 4: the app shows the backend's plain-words analysis of a read document before the user confirms it.
void main() {
  test('the analysis text is parsed from the attachment payload', () {
    final a = MemoryAttachment.tryParse({
      'id': 5,
      'kind': 'document',
      'status': 'ready',
      'summary': 'آزمایش خون',
      'findings': {'document_type': 'lab_result'},
      'analysis': {'text': '۳ نتیجه خوانده شد', 'flagged': [], 'trends': []},
    });
    expect(a, isNotNull);
    expect(a!.analysisText, '۳ نتیجه خوانده شد');
  });

  test('a payload without analysis keeps working (older backend, audio, failed read)', () {
    final a = MemoryAttachment.tryParse({'id': 6, 'kind': 'audio', 'status': 'ready'});
    expect(a!.analysisText, isNull);
    final b = MemoryAttachment.tryParse({'id': 7, 'kind': 'document', 'status': 'ready', 'analysis': 'oops'});
    expect(b!.analysisText, isNull);
  });
}
