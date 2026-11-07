import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/copy/sedi_copy.dart';

/// Phone test 2026-11-07: the «not done» question grew in place but its third button read «حالم خوب نی…» (Android shortens an
/// action title when three share the row) and the wording was colloquial. Labels are now short enough for three buttons, in the
/// educated voice (R-057) with half-spaces (R-064).
void main() {
  test('the three reason buttons are short enough not to be cut (<= 11 characters in fa/ar, <= 14 in en)', () {
    for (final code in ['no_time', 'dont_like', 'default']) {
      expect(SediCopy.t('inbox.planReasonLabel.$code', 'fa').length, lessThanOrEqualTo(11), reason: 'fa $code');
      expect(SediCopy.t('inbox.planReasonLabel.$code', 'ar').length, lessThanOrEqualTo(11), reason: 'ar $code');
      expect(SediCopy.t('inbox.planReasonLabel.$code', 'en').length, lessThanOrEqualTo(14), reason: 'en $code');
    }
  });

  test('the question and its hint are in the educated voice with correct half-spaces', () {
    final title = SediCopy.t('inbox.planNotDoneTitle', 'fa');
    final hint = SediCopy.t('inbox.planNotDoneHint', 'fa');
    expect(title, 'اشکالی ندارد. چه شد؟');
    expect(hint.contains('راحت\u200cتر'), isTrue);
    expect(hint.contains('می\u200cکنم'), isTrue);
    expect(hint.contains('رو '), isFalse);
    expect(hint.contains('میکنه'), isFalse);
  });
}
