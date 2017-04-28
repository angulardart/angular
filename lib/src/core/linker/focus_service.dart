import 'dart:html';

import 'package:meta/meta.dart';

/// Singleton [FocusService].
///
/// If left unused, dart2js will tree shake this so we don't need to worry about
/// lazy initialization to improve start-up performance.
final focusService = new FocusService._();

/// Event handler for 'focus' and 'blur' event.
typedef void FocusEventHandler(Event event);

/// Service for registering 'focus' and 'blur' event listeners.
///
/// This reduces the number of DOM calls by replacing per component focus
/// event listeners with a document wide listener. Event targets register
/// callbacks to be invoked when they receive a focus event.
class FocusService {
  final Map<EventTarget, FocusEventHandler> _blurHandlers;
  final Map<EventTarget, FocusEventHandler> _focusHandlers;

  FocusService._()
      : _blurHandlers = <EventTarget, FocusEventHandler>{},
        _focusHandlers = <EventTarget, FocusEventHandler>{} {
    document.addEventListener('blur', _onBlur, true);
    document.addEventListener('focus', _onFocus, true);
  }

  @visibleForTesting
  Map<EventTarget, FocusEventHandler> get blurHandlers => _blurHandlers;

  @visibleForTesting
  Map<EventTarget, FocusEventHandler> get focusHandlers => _focusHandlers;

  void register(EventTarget target, FocusEventHandler focusHandler,
      FocusEventHandler blurHandler) {
    if (blurHandler != null) {
      _blurHandlers[target] = blurHandler;
    }
    if (focusHandler != null) {
      _focusHandlers[target] = focusHandler;
    }
  }

  void unregister(EventTarget target) {
    _blurHandlers.remove(target);
    _focusHandlers.remove(target);
  }

  void _onBlur(Event event) {
    var handler = _blurHandlers[event.target];
    if (handler != null) {
      handler(event);
    }
  }

  void _onFocus(Event event) {
    var handler = _focusHandlers[event.target];
    if (handler != null) {
      handler(event);
    }
  }
}
