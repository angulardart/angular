/// To create a Pipe, you must implement this interface.
///
/// Angular invokes the `transform` method with the value of a binding as the
/// first argument, and any parameters as the second argument in list form.
///
/// ## Syntax
///
/// `value | pipeName[:arg0[:arg1...]]`
///
/// ## Example
///
/// The `RepeatPipe` below repeats the value as many times as indicated by the
/// first argument:
///
/// ```dart
/// import 'package:angular/core.dart' show Pipe, PipeTransform;
///
/// @Pipe('repeat')
/// class RepeatPipe implements PipeTransform {
///   transform(dynamic value, int times) => '$value' * times;
/// }
/// ```
///
/// Invoking `{{ 'ok' | repeat:3 }}` in a template produces `okokok`.
abstract class PipeTransform {
  // Note: Dart does not support varargs,
  // so we can't type the `transform` method...
  // dynamic transform(dynamic value, List<dynamic> ...args): any;
}
