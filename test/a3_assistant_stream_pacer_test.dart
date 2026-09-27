import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/state/assistant_stream_pacer.dart';

void main() {
  test('UI reveal delay is 60% of the previous frame-yield speed', () {
    expect(AssistantStreamPacer.speedFactor, closeTo(0.60, 0.001));
    expect(
      AssistantStreamPacer.revealDelay.inMicroseconds,
      (AssistantStreamPacer.previousYield.inMicroseconds /
              AssistantStreamPacer.speedFactor)
          .round(),
    );
    expect(
      AssistantStreamPacer.revealDelay.inMicroseconds,
      greaterThan(AssistantStreamPacer.previousYield.inMicroseconds),
    );
    expect(
      AssistantStreamPacer.revealDelay.inMilliseconds,
      greaterThanOrEqualTo(26),
    );
    expect(
      AssistantStreamPacer.revealDelay.inMilliseconds,
      lessThanOrEqualTo(28),
    );
  });

  test('chunks flush in order; first paint is immediate', () async {
    final seen = <String>[];
    final pacer = AssistantStreamPacer();
    pacer.enqueue('a', seen.add);
    pacer.enqueue('b', seen.add);
    pacer.enqueue('c', seen.add);
    expect(seen, ['a']);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(seen, ['a']);
    await pacer.whenIdle;
    expect(seen, ['a', 'b', 'c']);
    expect(pacer.isIdle, isTrue);
  });

  test('ChatController uses the UI pacer; stream client is unchanged', () {
    final controller = File(
      'lib/features/chat/state/chat_controller.dart',
    ).readAsStringSync();
    expect(controller.contains('AssistantStreamPacer'), isTrue);
    expect(controller.contains('pacer.enqueue'), isTrue);
    expect(controller.contains('await pacer.whenIdle'), isTrue);
    expect(controller.contains('/interact/chat/stream'), isFalse);

    final client = File(
      'lib/services/chat/chat_stream_client.dart',
    ).readAsStringSync();
    expect(client.contains('Duration.zero'), isTrue);
    expect(client.contains('AssistantStreamPacer'), isFalse);
  });
}
