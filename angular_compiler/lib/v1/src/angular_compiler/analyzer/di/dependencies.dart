import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v2/analyzer.dart';
import 'package:angular_compiler/v2/context.dart';

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

  const DependencyReader({TokenReader tokenReader = const TokenReader()})
      : _tokenReader = tokenReader;

  /// Returns the constructor on a given `class` [element] to use for injection.
  ///
  /// This is determined via a heuristic, but in the future might be manually
  /// configured with an annotation. Returns `null` if no constructor that can
  /// be used is found (i.e. is public).
  @protected
  ConstructorElement? findConstructor(ClassElement element) {
    // Highest priority is the unnamed (default constructor) if not abstract.
    if (element.unnamedConstructor != null && !element.isAbstract) {
      return element.unnamedConstructor;
    }
    // Otherwise, find the first public constructor.
    // If the class is abstract, find the first public factory constructor.
    return element.constructors.firstWhereOrNull(
        (e) => e.isPublic && !element.isAbstract || e.isFactory);
  }

  /// Returns parsed dependencies for the provided [element].
  ///
  /// Throws [ArgumentError] if not a `ClassElement` or `ExecutableElement`.
  DependencyInvocation<E> parseDependencies<E extends Element>(
    Element? element,
  ) {
    if (element is ClassElement) {
      return _parseClassDependencies(element) as DependencyInvocation<E>;
    }
    if (element is ExecutableElement) {
      return _parseFunctionDependencies(element) as DependencyInvocation<E>;
    }
    throw BuildError.forElement(
      element!,
      'Only classes or functions are valid as a dependency.',
    );
  }

  /// Returns parsed dependencies for the provided [element].
  ///
  /// Instead of looking at the parameters, [dependencies] is used.
  DependencyInvocation<ExecutableElement> parseDependenciesList(
    ExecutableElement element,
    List<DartObject> dependencies,
  ) {
    final positional = <DependencyElement>[];
    for (final object in dependencies) {
      var tokenObject = object;
      final reader = ConstantReader(object);
      var metadata = const <DartObject>[];
      if (reader.isList) {
        tokenObject = reader.listValue.first;
        metadata = reader.listValue.sublist(1);
      }
      bool hasMeta(TypeChecker checker) =>
          metadata.any((m) => checker.isExactlyType(m.type!));
      final isOptional = hasMeta($Optional);
      positional.add(
        DependencyElement(
          _tokenReader.parseTokenObject(tokenObject),
          host: hasMeta($Host),
          optional: isOptional,
          self: hasMeta($Self),
          skipSelf: hasMeta($SkipSelf),
        ),
      );
    }
    return DependencyInvocation(element, positional);
  }

  DependencyInvocation<E> _parseDependencies<E extends Element>(
    E bound,
    List<ParameterElement> parameters,
  ) {
    final positional = <DependencyElement>[];
    for (final parameter in parameters) {
      final isRequired = $Optional.firstAnnotationOfExact(parameter) == null;
      final hasInjectToken = $Inject.firstAnnotationOfExact(parameter) != null;
      final hasOpaqueToken = $OpaqueToken.firstAnnotationOf(parameter) != null;
      bool isRequiredButNotInjectable() =>
          parameter.isOptionalPositional &&
          isRequired &&
          !(hasInjectToken || hasOpaqueToken);
      if (!parameter.isOptionalNamed && !isRequiredButNotInjectable()) {
        final token = _tokenReader.parseTokenParameter(parameter);
        _checkForOptionalAndNullable(
          parameter,
          parameter.type,
          isOptional: !isRequired,
        );
        positional.add(
          DependencyElement(
            token,
            type: hasInjectToken || hasOpaqueToken
                ? _tokenReader.parseTokenType(parameter)
                : null,
            host: $Host.firstAnnotationOfExact(parameter) != null,
            optional: !isRequired,
            self: $Self.firstAnnotationOfExact(parameter) != null,
            skipSelf: $SkipSelf.firstAnnotationOfExact(parameter) != null,
          ),
        );
      }
    }
    return DependencyInvocation(bound, positional);
  }

  // There is no common Element sub-type that has a <Element>.type field for
  // both `ParameterElement` and `ExecutableElement`, so instead we take the
  // element and type separately.
  //
  // TODO(b/170313184): Refactor into a common library.
  static void _checkForOptionalAndNullable(
    Element element,
    DartType type, {
    required bool isOptional,
  }) {
    if (!CompileContext.current.emitNullSafeCode) {
      // Do not run this check for libraries not opted-in to null safety.
      return;
    }
    if (type.isExplicitlyNonNullable) {
      // Must *NOT* be @Optional()
      if (isOptional) {
        throw BuildError.forElement(
          element,
          messages.optionalDependenciesNullable,
        );
      }
    } else if (type.isExplicitlyNullable) {
      // Must *BE* @Optional()
      if (!isOptional) {
        throw BuildError.forElement(
          element,
          messages.optionalDependenciesNullable,
        );
      }
    }
  }

  DependencyInvocation<ConstructorElement> _parseClassDependencies(
    ClassElement element,
  ) {
    final constructor = findConstructor(element);
    if (constructor == null) {
      throw BuildError.forElement(
          element, 'Could not find a valid constructor');
    }
    return _parseDependencies(constructor, constructor.parameters);
  }

  DependencyInvocation<ExecutableElement> _parseFunctionDependencies(
    ExecutableElement element,
  ) =>
      _parseDependencies(element, element.parameters);
}

/// Statically analyzed arguments needed to invoke a constructor or function.
class DependencyInvocation<E extends Element?> {
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
      const ListEquality<Object>().equals(positional, o.positional) &&
      const MapEquality<Object, Object>().equals(named, o.named);

  @override
  int get hashCode =>
      urlOf(bound).hashCode ^
      const ListEquality<Object>().hash(positional) ^
      const MapEquality<Object, Object>().hash(named);

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
  final TypeTokenElement? type;

  @visibleForTesting
  const DependencyElement(
    this.token, {
    this.type,
    this.host = false,
    this.optional = false,
    this.self = false,
    this.skipSelf = false,
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
