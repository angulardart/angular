import 'dart:async';

export 'dart:async' show Stream, StreamController, StreamSubscription;

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
