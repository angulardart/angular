import 'package:angular/angular.dart';

/// A bridge between a control and a native element.
///
/// A `ControlValueAccessor` abstracts the operations of writing a new value to a
/// DOM element representing an input control.
///
/// Please see [DefaultValueAccessor] for more information.
abstract class ControlValueAccessor<T> {
  /// Write a new value to the element.
  void writeValue(T obj);

  /// Set the function to be called when the control receives a change event.
  void registerOnChange(ChangeFunction<T> f);

  /// Set the function to be called when the control receives a touch event.
  void registerOnTouched(TouchFunction f);

  /// This function is called when the control status changes to or
  /// from "DISABLED".
  ///
  /// Depending on the value, it will enable or disable the
  /// appropriate DOM element.
  void onDisabledChanged(bool isDisabled);
}

/// Used to provide a [ControlValueAccessor] for form controls.
///
/// See [DefaultValueAccessor] for how to implement one.
const ngValueAccessor = MultiToken<ControlValueAccessor>(
  'NgValueAccessor',
);

/// Type of the function to be called when the control receives a change event.
typedef dynamic ChangeFunction<T>(T value, {String rawValue});

/// Type of the function to be called when the control receives a touch event.
typedef dynamic TouchFunction();

/// A mixin to add touch support to a [ControlValueAccessor].
///
/// **NOTE**: This will add a [HostListener] on the `blur` event.
class TouchHandler {
  // TODO(alorenzen): Make this private.
  TouchFunction onTouched = () {};

  @HostListener('blur')
  void touchHandler() {
    onTouched();
  }

  /// Set the function to be called when the control receives a touch event.
  void registerOnTouched(TouchFunction fn) {
    onTouched = fn;
  }
}

/// A mixin to add change handler registration to a [ControlValueAccessor].
///
/// **NOTE**: It is expected that all subclasses will implement their own
/// [HostListener] to actually call the [onChange] callback..
class ChangeHandler<T> {
  ChangeFunction<T> onChange = (T _, {String rawValue}) {};

  /// Set the function to be called when the control receives a change event.
  void registerOnChange(ChangeFunction<T> fn) {
    onChange = fn;
  }
}
