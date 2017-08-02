import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../common.dart';
import '../types.dart';
import 'package:source_gen/source_gen.dart';
import 'tokens.dart';

/// Support for reading and parsing a class or function's "dependencies".
///
/// For example, the following class and its constructor:
/// ```dart
/// class FooService {
///   FooService(BarService barService, [@Optional() @Inject(someToken) baz]);
/// }
/// ```
class DependencyReader {
  final TokenReader _tokenReader;

  const DependencyReader({TokenReader tokenReader: const TokenReader()})
      : _tokenReader = tokenReader;

  /// Returns the constructor on a given `class` [element] to use for injection.
  ///
  /// This is determined via a heuristic, but in the future might be manually
  /// configured with an annotation. Returns `null` if no constructor that can
  /// be used is found (i.e. is public).
  @protected
  ConstructorElement findConstructor(ClassElement element) {
    // Highest priority is the unnamed (default constructor) if not abstract.
    if (element.unnamedConstructor != null && !element.isAbstract) {
      return element.unnamedConstructor;
    }
    // Otherwise, find the first public constructor.
    // If the class is abstract, find the first public factory constructor.
    return element.constructors.firstWhere(
        (e) => e.isPublic && !element.isAbstract || e.isFactory,
        orElse: () => null);
  }

  /// Returns parsed dependencies for the provided [element].
  ///
  /// Throws [ArgumentError] if not a `ClassElement` or `FunctionElement`.
  DependencyInvocation parseDependencies(Element element) {
    if (element is ClassElement) {
      return _parseClassDependencies(element);
    }
    if (element is FunctionElement) {
      return _parseFunctionDependencies(element);
    }
    throw new ArgumentError('Invalid type: ${element.runtimeType}.');
  }

  /// Returns parsed dependencies for the provided [element].
  ///
  /// Instead of looking at the parameters, [dependencies] is used.
  DependencyInvocation parseDependenciesList(
    FunctionElement element,
    List<DartObject> dependencies,
  ) {
    final positional = <DependencyElement>[];
    for (final object in dependencies) {
      DartObject tokenObject = object;
      final reader = new ConstantReader(object);
      if (reader.isList) {
        tokenObject = reader.listValue.first;
      }
      positional.add(
        new DependencyElement(
          _tokenReader.parseTokenObject(tokenObject),
          // TODO: Support the metadata annotations when passed in a list.
          // i.e. [Foo, const Optional()].
        ),
      );
    }
    return new DependencyInvocation(element, positional);
  }

  DependencyInvocation _parseDependencies(
    Element bound,
    List<ParameterElement> parameters,
  ) {
    final positional = <DependencyElement>[];
    for (final parameter in parameters) {
      // ParameterKind.POSITIONAL is "optional positional".
      if (parameter.parameterKind != ParameterKind.NAMED) {
        final token = _tokenReader.parseTokenParameter(parameter);
        positional.add(
          new DependencyElement(
            token,
            host: $Host.firstAnnotationOfExact(parameter) != null,
            optional: $Optional.firstAnnotationOfExact(parameter) != null,
            self: $Self.firstAnnotationOfExact(parameter) != null,
            skipSelf: $SkipSelf.firstAnnotationOfExact(parameter) != null,
          ),
        );
      }
    }
    return new DependencyInvocation(bound, positional);
  }

  DependencyInvocation _parseClassDependencies(ClassElement element) {
    final constructor = findConstructor(element);
    if (constructor == null) {
      // TODO(matanl): Log an exception instead of throwing.
      throw new StateError('Could not find a valid constructor for $element.');
    }
    return _parseDependencies(constructor, constructor.parameters);
  }

  DependencyInvocation _parseFunctionDependencies(FunctionElement element) {
    return _parseDependencies(element, element.parameters);
  }
}

/// Statically analyzed arguments needed to invoke a constructor or function.
class DependencyInvocation<E extends Element> {
  /// Positional arguments, in order analyzed.
  final List<DependencyElement> positional;

  /// Named arguments.
  final Map<String, DependencyElement> named;

  /// What constructor or top-level/static function this invokes.
  final E bound;

  @visibleForTesting
  const DependencyInvocation(
    this.bound,
    this.positional, {
    this.named = const {},
  });

  @override
  bool operator ==(Object o) =>
      o is DependencyInvocation<E> &&
      bound == o.bound &&
      const ListEquality().equals(positional, o.positional) &&
      const MapEquality().equals(named, o.named);

  @override
  int get hashCode =>
      bound.hashCode ^
      const ListEquality().hash(positional) ^
      const MapEquality().hash(named);

  @override
  String toString() =>
      'DependencyInvocation ' +
      {
        'bound': urlOf(bound),
        'positional': '$positional',
        'named': '$named',
      }.toString();
}

/// Statically analyzed information necessary to satisfy a dependency.
class DependencyElement {
  /// Whether the dependency should be satisfied from the parent only.
  final bool host;

  /// Whether the dependency may be omitted (i.e. be `null`).
  final bool optional;

  /// Whether the dependency should be satisfied from itself only.
  final bool self;

  /// Whether the dependency should never be satisfied from itself.
  final bool skipSelf;

  /// Token to use to lookup the dependency.
  final TokenElement token;

  @visibleForTesting
  const DependencyElement(
    this.token, {
    this.host: false,
    this.optional: false,
    this.self: false,
    this.skipSelf: false,
  });

  @override
  bool operator ==(Object o) =>
      o is DependencyElement &&
      token == o.token &&
      host == o.host &&
      optional == o.optional &&
      self == o.self &&
      skipSelf == o.skipSelf;

  @override
  int get hashCode =>
      token.hashCode ^
      host.hashCode ^
      optional.hashCode ^
      self.hashCode ^
      skipSelf.hashCode;

  @override
  String toString() =>
      'DependencyElement ' +
      {
        'token': token,
        'host': host,
        'optional': optional,
        'self': self,
        'skipSelf': skipSelf,
      }.toString();
}
