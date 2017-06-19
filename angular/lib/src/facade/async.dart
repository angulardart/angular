import 'dart:async';

/// **DEPRECATED**: Use [StreamController] and [Stream] instead.
///
/// **BEFORE**:
/// ```
/// @Output()
/// final touch = new EventEmitter();
/// ```
///
/// **AFTER**:
/// ```
/// final _onTouch = new StreamController.broadcast();
///
/// @Output()
/// Stream get touch => _onTouch.stream;
/// ```
///
/// This avoids leaking details about how your [Stream] is implemented.
@Deprecated('Only expose a Stream for your component @Output')
class EventEmitter<T> extends Stream<T> {
  StreamController<T> _controller;

  /// Creates an instance of [EventEmitter], which depending on [isAsync],
  /// delivers events synchronously or asynchronously.
  EventEmitter([bool isAsync = true]) {
    _controller = new StreamController<T>.broadcast(sync: !isAsync);
  }

  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  void add(T value) {
    _controller.add(value);
  }

  void emit(T value) {
    _controller.add(value);
  }

  void addError(error) {
    _controller.addError(error);
  }

  void close() {
    _controller.close();
  }
}
