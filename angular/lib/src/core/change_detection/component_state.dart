/// Mixin representing an component or directive with observable state change.
///
/// !Status: EXPERIMENTAL. APIs are not mature yet.
///
/// Used to efficiently communicate state changes to AppView.
class ComponentState {
  ComponentStateCallback _stateChangeCallback;

  /// Schedules a microtask to notify listeners of state change.
  ///
  /// Usage:
  ///
  ///     @Input()
  ///     set title(String newValue) {
  ///       setState(() => _title = newValue);
  ///     }
  void setState(void fn()) {
    fn();
    deliverStateChanges();
  }

  /// Callback for state changes used by Angular AppView.
  ///
  /// This is private to framework. To observe changes outside AppView,
  /// please use stateChanges stream.
  set stateChangeCallback(ComponentStateCallback callback) {
    _stateChangeCallback = callback;
  }

  /// Synchronously delivers changes to all subscribers.
  ///
  /// Users may override to process aggregate state changes.
  void deliverStateChanges() {
    if (_stateChangeCallback != null) {
      _stateChangeCallback();
    }
  }
}

typedef void ComponentStateCallback();
