/// Utilities and metadata annotations for static analysis purposes.
@experimental
library angular.meta;

// This import ensures that this library is not used in the VM.
//
// ignore: unused_import
import 'dart:html';

import 'package:meta/meta.dart';

/// Wraps a typed [callback] with a single parameter of type [A].
///
/// This function returns an _untyped_ callback with a single parameter
/// of type `dynamic`, which in turn dynamically is casted/checked to
/// [A] before invoking [callback].
///
/// Common usage is when creating a callback to pass to a `@Component`
/// that is expecting generic type parameters, but is missing them due
/// to missing support in Angulardart:
/// ```dart
/// typedef ItemRenderer<T> = String Function(T);
///
/// abstract class Dog {
///   String get name;
/// }
///
/// @Component(
///   selector: 'my-component',
///   directives: [ItemListComponent],
/// )
/// class MyComponent {
///   final itemRenderer = castCallback1((Dog dog) => dog.name);
/// }
///
/// class ItemListComponent<T> {
///   @Input()
///   ItemRenderer<T> itemRenderer;
/// }
/// ```
///
/// **NOTE**: This method is _only_ intended as a workaround for the lack-of
/// reified generics for components and directives. Do **not** use as a general
/// purpose workaround: https://github.com/dart-lang/angular/issues/68
T Function(dynamic) castCallback1ForDirective<T, A>(
  T Function(A) callback,
) {
  return (element) => callback(element as A);
}

/// Wraps a typed [callback] with two parameters of types [A] and [B].
///
/// See [castCallback2ForDirective] for details.
///
/// **NOTE**: This method is _only_ intended as a workaround for the lack-of
/// reified generics for components and directives. Do **not** use as a general
/// purpose workaround: https://github.com/dart-lang/angular/issues/68
T Function(dynamic, dynamic) castCallback2ForDirective<T, A, B>(
  T Function(A, B) callback,
) {
  return (a, b) => callback(a as A, b as B);
}
