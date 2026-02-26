import 'dart:async';

class InboxRefreshBus {
  InboxRefreshBus._();
  static final InboxRefreshBus instance = InboxRefreshBus._();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  Timer? _debounce;

  Stream<void> get stream => _controller.stream;

  void triggerDebounced({Duration delay = const Duration(milliseconds: 450)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      if (!_controller.isClosed) {
        _controller.add(null);
      }
    });
  }

  void dispose() {
    _debounce?.cancel();
    _controller.close();
  }
}
