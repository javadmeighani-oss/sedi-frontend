import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/core/navigation/app_gate_router.dart';
import 'package:sedi_app/features/intro/presentation/pages/intro_page.dart';

/// A1 -> A2/A3 speed contract: the logo motion is unchanged, the hand-over after it stops is short.
void main() {
  test('A1 logo motion stays as approved (3000 ms, same keyframes)', () {
    expect(IntroPage.kIntroDuration, const Duration(milliseconds: 3000));
    expect(IntroPage.kMotionKeyframes.length, 3);
  });

  test('splash to gate slide is 300 ms (was 600)', () {
    expect(AppGateRouter.kSplashToGateTransition,
        const Duration(milliseconds: 300));
    final src = File('lib/core/navigation/app_gate_router.dart').readAsStringSync();
    expect(src.contains('transitionDuration: kSplashToGateTransition'), isTrue);
    expect(src.contains('milliseconds: 600'), isFalse);
  });

  test('A3 start-up: subjects and chat initialize run together; first subject load never clears the chat',
      () {
    final src = File(
      'lib/features/gate3_interactive/presentation/pages/gate3_interactive_page.dart',
    ).readAsStringSync();
    // initialize is no longer chained behind the subject load
    expect(src.contains('loadAccessibleSubjects().then'), isFalse);
    expect(src.contains('loadAccessibleSubjects().whenComplete'), isTrue);
    expect(src.contains('_controller.initialize('), isTrue);
    // the first load is not a subject switch
    expect(src.contains('bool _initialSubjectLoad = true;'), isTrue);
    final handler = src.substring(
      src.indexOf('void _onSubjectChanged()'),
      src.indexOf('void didChangeAppLifecycleState') > 0
          ? src.indexOf('void didChangeAppLifecycleState')
          : src.length,
    );
    expect(
      handler.indexOf('if (_initialSubjectLoad)'),
      lessThan(handler.indexOf('_controller.messages.clear()')),
    );
  });
}
