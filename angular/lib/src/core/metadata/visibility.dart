import '../metadata.dart';

/// Options for configuring whether a directive class can be injected.
///
/// See [Directive.visibility] for details including the default behavior.
enum Visibility {
  /// The directive can only be injected "locally"; i.e. not by children.
  ///
  /// For example, the following code will fail at runtime:
  /// ```dart
  /// @Component(
  ///   selector: 'parent',
  ///   directives: const [Child],
  ///   template: '<child></child>',
  ///
  ///   // The default, but here explicitly for clarity.
  ///   visibility: Visibility.local,
  /// )
  /// class Parent {}
  ///
  /// @Component(
  ///   selector: 'child',
  ///   template: '',
  /// )
  /// class Child {
  ///   // Will throw runtime error: "No provider found for Parent".
  ///   Child(Parent parent);
  /// }
  /// ```
  ///
  /// However, it is possible to provide another interface to children:
  /// ```dart
  /// // An interface that will be provided by the Parent class.
  /// abstract class Example {}
  ///
  /// @Component(
  ///   selector: 'parent',
  ///   directives: const [Child],
  ///   providers: const [
  ///     const ExistingProvider(Example, useExisting: Parent),
  ///   ],
  ///   template: '<child></child>',
  /// )
  /// ```
  /// class Parent implements Example {}
  ///
  /// @Component(
  ///   selector: 'child',
  ///   template: '',
  /// )
  /// class Child {
  ///   // Fine!
  ///   Child(Example example);
  /// }
  /// ```
  ///
  /// **NOTE**: We intend to allow other forms of dependency injection (such as
  /// `FactoryProvider` to also access "local" components and directives, but
  /// this does not yet work: https://github.com/dart-lang/angular/issues/716.
  local,

  /// The directive can be injected anywhere in the sub tree.
  ///
  /// ```dart
  /// @Component(
  ///   selector: 'parent',
  ///   directives: const [Child],
  ///   template: '<child></child>',
  ///   visibility: Visibility.all,
  /// )
  /// class Parent {}
  ///
  /// @Component(
  ///   selector: 'child',
  ///   template: '',
  /// )
  /// class Child {
  ///   Child(Parent parent);
  /// }
  /// ```
  ///
  /// **NOTE**: This has a small code-size and runtime cost, so if this feature
  /// is not used it is recommended to stay with the default [Visibility.local].
  all,
}
