import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../types.dart';
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
  DependencyInvocation<E> parseDependencies<E extends Element>(
    Element element,
  ) {
    if (element is ClassElement) {
      return _parseClassDependencies(element) as DependencyInvocation<E>;
    }
    if (element is FunctionElement) {
      return _parseFunctionDependencies(element) as DependencyInvocation<E>;
    }
    throw new ArgumentError('Invalid element: $element.');
  }

  /// Returns parsed dependencies for the provided [element].
  ///
  /// Instead of looking at the parameters, [dependencies] is used.
  DependencyInvocation<FunctionElement> parseDependenciesList(
    FunctionElement element,
    List<DartObject> dependencies,
  ) {
    final positional = <DependencyElement>[];
    for (final object in dependencies) {
      DartObject tokenObject = object;
      final reader = new ConstantReader(object);
      List<DartObject> metadata = const [];
      if (reader.isList) {
        tokenObject = reader.listValue.first;
        metadata = reader.listValue.sublist(1);
      }
      bool hasMeta(TypeChecker checker) =>
          metadata.any((m) => checker.isExactlyType(m.type));
      positional.add(
        new DependencyElement(
          _tokenReader.parseTokenObject(tokenObject),
          host: hasMeta($Host),
          optional: hasMeta($Optional),
          self: hasMeta($Self),
          skipSelf: hasMeta($SkipSelf),
        ),
      );
    }
    return new DependencyInvocation(element, positional);
  }

  DependencyInvocation<E> _parseDependencies<E extends Element>(
    E bound,
    List<ParameterElement> parameters,
  ) {
    final positional = <DependencyElement>[];
    for (final parameter in parameters) {
      // ParameterKind.POSITIONAL is "optional positional".
      bool isNamed() => parameter.parameterKind == ParameterKind.NAMED;
      bool isOptionalAndNotInjectable() =>
          parameter.parameterKind == ParameterKind.POSITIONAL &&
          $Optional.firstAnnotationOfExact(parameter) == null &&
          $Inject.firstAnnotationOf(parameter) == null;
      if (!isNamed() && !isOptionalAndNotInjectable()) {
        final token = _tokenReader.parseTokenParameter(parameter);
        bool usesInject() => $Inject.firstAnnotationOfExact(parameter) != null;
        positional.add(
          new DependencyElement(
            token,
            type: usesInject() ? _tokenReader.parseTokenType(parameter) : null,
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

  DependencyInvocation<ConstructorElement> _parseClassDependencies(
    ClassElement element,
  ) {
    final constructor = findConstructor(element);
    if (constructor == null) {
      // TODO(matanl): Log an exception instead of throwing.
      throw new StateError('Could not find a valid constructor for $element.');
    }
    return _parseDependencies(constructor, constructor.parameters);
  }

  DependencyInvocation<FunctionElement> _parseFunctionDependencies(
    FunctionElement element,
  ) =>
      _parseDependencies(element, element.parameters);
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
      urlOf(bound) == urlOf(o.bound) &&
      const ListEquality().equals(positional, o.positional) &&
      const MapEquality().equals(named, o.named);

  @override
  int get hashCode =>
      urlOf(bound).hashCode ^
      const ListEquality().hash(positional) ^
      const MapEquality().hash(named);

  @override
  String toString() =>
      'DependencyInvocation ' +
      {
        'bound': '${urlOf(bound)}',
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

  /// Type of this dependency.
  ///
  /// If `null` a [token] that is [TypeTokenElement] takes precedence.
  final TypeTokenElement type;

  @visibleForTesting
  const DependencyElement(
    this.token, {
    this.type,
    this.host: false,
    this.optional: false,
    this.self: false,
    this.skipSelf: false,
  });

  @override
  bool operator ==(Object o) =>
      o is DependencyElement &&
      token == o.token &&
      type == o.type &&
      host == o.host &&
      optional == o.optional &&
      self == o.self &&
      skipSelf == o.skipSelf;

  @override
  int get hashCode =>
      token.hashCode ^
      type.hashCode ^
      host.hashCode ^
      optional.hashCode ^
      self.hashCode ^
      skipSelf.hashCode;

  @override
  String toString() =>
      'DependencyElement ' +
      {
        'token': token,
        'type': type,
        'host': host,
        'optional': optional,
        'self': self,
        'skipSelf': skipSelf,
      }.toString();
}
