import 'dart:async';

/// Lets a Lifestyle page hand a USER message to the canonical chat (P8: "set up my plan" from the plan page).
/// The chat page listens and sends it through its own controller, so the transcript, history, memory and the plan
/// composer behave exactly as if the user had typed it. Distinct from [Gate3AssistantStarterBus], which only inserts
/// an assistant line and never sends anything.
class Gate3UserMessageBus {
  Gate3UserMessageBus._();
  static final Gate3UserMessageBus instance = Gate3UserMessageBus._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void publish(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _controller.isClosed) return;
    _controller.add(trimmed);
  }
}
