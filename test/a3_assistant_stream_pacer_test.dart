import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedi_app/features/chat/state/assistant_stream_pacer.dart';

void main() {
  test('UI reveal delay is 30% of the previous frame-yield speed', () {
    expect(AssistantStreamPacer.speedFactor, closeTo(0.30, 0.001));
    expect(AssistantStreamPacer.previousYield, const Duration(milliseconds: 16));
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
    expect(AssistantStreamPacer.revealDelay.inMilliseconds, 53);
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

  test('second paint cannot bypass cadence after the queue drains', () async {
    final seen = <String>[];
    final pacer = AssistantStreamPacer();
    pacer.enqueue('a', seen.add);
    await pacer.whenIdle;
    expect(seen, ['a']);
    expect(pacer.isIdle, isTrue);

    pacer.enqueue('b', seen.add);
    expect(seen, ['a']);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(seen, ['a']);
    await pacer.whenIdle;
    expect(seen, ['a', 'b']);
    expect(pacer.isIdle, isTrue);
  });

  test('cancel drops remaining chunks and whenIdle completes', () async {
    final seen = <String>[];
    final pacer = AssistantStreamPacer();
    pacer.enqueue('a', seen.add);
    pacer.enqueue('b', seen.add);
    pacer.enqueue('c', seen.add);
    expect(seen, ['a']);
    pacer.cancel();
    await pacer.whenIdle;
    expect(seen, ['a']);
    expect(pacer.isIdle, isTrue);
    pacer.enqueue('d', seen.add);
    expect(seen, ['a']);
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
