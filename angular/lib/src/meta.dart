// **DO NOT CHANGE**. The analyzer looks for this _specific name_.
library angular.meta;

/// Used to annotate a class, field, or method that is public for template use.
///
/// An annotated element may be referenced in the _same_ Dart library, or in
/// any Dart source file whose filename ends in `.template.dart`. Tools, such as
/// the analyzer can provide feedback if the annotated element is used anywhere
/// else.
///
/// This annotation is intended to be used to identify what elements of a class
/// or library are only public (not private) because they represent state that
/// will be referenced in the template HTML of an AngularDart component. For
/// example:
///
/// ```dart
/// // my_component.dart
/// import 'package:angular/angular.dart';
///
/// @Component(
///   selector: 'my-comp',
///   template: 'Hello {{fullName}}!',
/// )
/// class MyComponent {
///   @Input()
///   String firstName;
///
///   @Input()
///   String lastName;
///
///   @visibleForTemplate
///   String get fullName => '$firstName $lastName';
/// }
/// ```
///
/// ... `fullName` is a computed field that only exists for use in a `template`
/// and is not intended to be part of the public API of the component. Another
/// library attempting to access `fullName` would trigger a diagnostic:
///
/// ```dart
/// // other_lib.dart
/// import 'my_component.dart';
///
/// void example(MyComponent comp) {
///   // LINT
///   print(comp.fullName);
/// }
/// ```
const visibleForTemplate = _VisibleForTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}
