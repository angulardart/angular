import 'package:meta/meta.dart';

/// Declares a typed directive or defines type argument of type [T].
///
/// Example uses include:
///   * Single concrete type argument:
///     * `Typed<Foo<String>>()`.
///   * Multiple, nested concrete type arguments:
///     * `Typed<Bar<String, List<int>>>()`.
///   * Generic type parameter type argument:
///     * `Typed<Baz>.of([#T])`
///   * Mixed, nested type arguments:
///     * `Typed<Qux>.of([String, Typed<List>.of([#T])`
///
/// See documentation of each constructor for more details.
@optionalTypeArgs
class Typed<T extends Object> {
  /// An optional reference for targeting specific instances within a template.
  ///
  /// This field is only valid when this is the root instance of a directive
  /// type (i.e. not a nested type argument).
  ///
  /// By default, this types all directives of [T]'s raw type. However, if this
  /// field is non-null, only those whose host elements have a matching
  /// reference name are typed.
  ///
  /// A [Typed] declaration that specifies this field takes precedence over one
  /// that doesn't when the host element has a matching reference.
  ///
  /// ```
  /// @Component(
  ///   ...
  ///   template: '''
  ///     <!-- Defaults to GenericComponent<String> -->
  ///     <generic></generic>
  ///     <!-- The reference marks this as GenericComponent<int> -->
  ///     <generic #indexed></generic>
  ///   ''',
  ///   directives: [
  ///     GenericComponent,
  ///   ],
  ///   directiveTypes: [
  ///     // Applies to <generic> by default.
  ///     Typed<GenericComponent<String>>(),
  ///     // Applies to <generic #indexed> only.
  ///     Typed<GenericComponent<int>>(on: 'indexed'),
  ///   ],
  /// )
  /// class ExampleComponent {}
  /// ```
  ///
  /// This field must be distinct between two [Typed] declarations for the same
  /// directive of [T]'s raw type in the same view.
  final String? on;

  /// The generic type arguments of [T], if not fully specified by [T] itself.
  ///
  /// Each element must be one of the following types:
  ///   * [Type]:   for types (e.g. `String`)
  ///   * [Typed]:  for a parameterized type (e.g. `Typed<List<int>>()`)
  ///   * [Symbol]: for a type parameter on the host component (e.g. `#T`)
  ///
  /// In general this field is only needed if the type is parameterized by a
  /// type parameter of host component. Otherwise the type can be fully
  /// specified by [T] itself.
  final List<Object>? typeArguments;

  /// A shorthand constructor for a type with concrete type arguments.
  ///
  /// This is the simplest way to define generic type arguments. Note that as
  /// long as all of the type arguments are concrete, nested type parameters can
  /// be specified indefinitely, directly within [T].
  ///
  /// ```
  /// @Component(...)
  /// class GenericComponent<A, B> {}
  ///
  /// @Component(
  ///   ...
  ///   directives: [
  ///     GenericComponent,
  ///   ],
  ///   directiveTypes: [
  ///     Typed<GenericComponent<String, List<int>>>(),
  ///   ],
  /// )
  /// class ExampleComponent {}
  /// ```
  ///
  /// See [on] for details about this optional parameter.
  const Typed({
    this.on,
  }) :
        // This actually needs to be null, the compiler checks if typeArguments
        // is non-null to determine which constructor was used.
        typeArguments = null;

  /// A constructor for a type with any type parameters as type arguments.
  ///
  /// This should be used when you wish to flow a type parameter from the host
  /// component to a child directive.
  ///
  /// The following example demonstrates how `ParentComponent`'s type parameter
  /// `B` can be flowed as a type argument to `ChildComponent`'s type parameter
  /// `A`.
  ///
  /// ```
  /// @Component(...)
  /// class ChildComponent<A> {}
  ///
  /// @Component(
  ///   ...
  ///   directives: [
  ///     ChildComponent,
  ///   ],
  ///   directiveTypes: [
  ///     Typed<ChildComponent>.of([#B]),
  ///   ],
  /// )
  /// class ParentComponent<B> {}
  /// ```
  ///
  /// Now if the directive type `Typed<ParentComponent<String>>()` is defined,
  /// the type argument will flow through and create a `ChildComponent<String>`
  /// as well.
  ///
  /// See the [typeArguments] and [on] fields for details about these
  /// parameters.
  const Typed.of(
    List<Object> typeArguments, {
    this.on,
  }) :
        // We prevent passing in a non-null value (because this constructor
        // requires an actual List). The compiler checks this field and whether
        // it is null (or not) to determine which constructor was used.
        // ignore: prefer_initializing_formals
        typeArguments = typeArguments;
}
