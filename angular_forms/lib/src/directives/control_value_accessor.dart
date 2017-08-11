import 'package:angular/angular.dart' show OpaqueToken;

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
}

/// Used to provide a [ControlValueAccessor] for form controls.
///
/// See [DefaultValueAccessor] for how to implement one.
const OpaqueToken NG_VALUE_ACCESSOR = const OpaqueToken('NgValueAccessor');

/// Type of the function to be called when the control receives a change event.
typedef dynamic ChangeFunction<T>(T value, {String rawValue});

/// Type of the function to be called when the control receives a touch event.
typedef dynamic TouchFunction();
