import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../types.dart';

/// Support for reading and parsing constant `Provider`s into data structures.
class ProviderReader {
  const ProviderReader();

  /// Returns whether an object represents a constant [List].
  @protected
  bool isList(DartObject o) => o.toListValue() != null;

  /// Returns whether an object represents a `Provider`.
  @protected
  bool isProvider(DartObject o) => $Provider.isAssignableFromType(o.type);

  /// Returns whether an object represents a [Type].
  @protected
  bool isType(DartObject o) => o.toTypeValue() != null;

  /// Returns whether an object is abstractly a "module" of providers.
  ///
  /// In AngularDart, this is currently represented as a `List<Object>` where
  /// the elements of the list can be other `List<Object>`, a `Provider`, or a
  /// `Type`.
  ///
  /// Validation may not be performed on the underlying elements.
  @protected
  bool isModule(DartObject o) => isList(o);

  /// Parses a static object representing a `Provider`.
  ProviderElement parseProvider(DartObject o) {
    if (o == null) {
      throw new ArgumentError.notNull();
    }
    if (isType(o)) {
      // Represents "Foo", which is supported short-hand for "Provider(Foo)".
      // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
      return _parseType(o);
    }
    if (!isProvider(o)) {
      throw new FormatException('Expected Provider, got "${o.type.name}".');
    }
    return _parseProvider(o);
  }

  ProviderElement _parseProvider(DartObject o) {
    final reader = new ConstantReader(o);
    final token = _parseToken(reader.read('token'));
    final useClass = reader.read('useClass');
    if (!useClass.isNull) {
      return _parseUseClass(token, useClass.typeValue.element);
    }
    final useFactory = reader.read('useFactory');
    if (!useFactory.isNull) {
      return _parseUseFactory(token, o);
    }
    // const Provider(<token>, useValue: constExpression)
    final useValue = reader.read('useValue');
    if (!useValue.isString || useValue.stringValue != '__noValueProvided__') {
      return _parseUseValue(token, useValue);
    }
    // Base case: const Provider(Foo) with no fields set.
    if (token is TypeTokenElement) {
      return _parseUseClass(token, reader.read('token').typeValue.element);
    }
    throw new UnsupportedError('Could not parse provider: $o.');
  }

  // const Provider(<token>, useClass: Foo)
  ProviderElement _parseUseClass(
    TokenElement token,
    ClassElement clazz,
  ) {
    // TODO(matanl): Validate that clazz has @Injectable() when flag is set.
    final constructor = clazz.unnamedConstructor ??
        clazz.constructors.firstWhere(
          (c) => c.isPublic,
          orElse: () =>
              clazz.constructors.isNotEmpty ? clazz.constructors.first : null,
        );
    // TODO(matanl): Validate constructor and warn when appropriate.
    return new UseClassProviderElement(
      token,
      urlOf(clazz),
      constructor: constructor.name,
      dependencies: _parseDependencies(constructor.parameters),
    );
  }

  // const Provider(<token>, useFactory: createFoo)
  ProviderElement _parseUseFactory(TokenElement token, DartObject o) {
    // TODO(matanl): Remove workaround & use reader >= source_gen 0.7.0.
    final useFactoryWorkaround = o.getField('useFactory');
    // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
    return new UseFactoryProviderElement(
      token,
      urlOf(useFactoryWorkaround.type.element),
      dependencies: _parseDependencies(
        (useFactoryWorkaround.type.element as FunctionElement).parameters,
      ),
    );
  }

  ProviderElement _parseUseValue(TokenElement token, ConstantReader useValue) {
    // TODO(matanl): For corner-cases that can't be revived, display error.
    return new UseValueProviderElement(token, useValue.revive());
  }

  Dependencies _parseDependencies(List<ParameterElement> parameters) {
    final positional = <DependencyElement>[];
    for (final parameter in parameters) {
      if (parameter.parameterKind == ParameterKind.POSITIONAL) {
        final inject = $Inject.firstAnnotationOfExact(parameter);
        final token = inject != null
            ? _parseToken(new ConstantReader(inject).read('token'))
            : new TypeTokenElement(urlOf(parameter.type.element));
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
      // TODO(matanl): Add support for named arguments.
    }
    return new Dependencies(positional);
  }

  /// Returns a token element representing a constant field.
  TokenElement _parseToken(ConstantReader o) {
    if (o.isNull) {
      throw new FormatException('Expected token, but got "null".');
    }
    if (o.isType) {
      return new TypeTokenElement(urlOf(o.typeValue.element));
    }
    if (o.instanceOf($OpaqueToken)) {
      return new OpaqueTokenElement(o.read('_desc').stringValue);
    }
    // TODO(matanl): Improve to include information about the token.
    // Blocked on https://github.com/dart-lang/source_gen/issues/216.
    throw new UnsupportedError('Unsupported token value');
  }

  /// Returns a provider element representing a single type.
  ProviderElement _parseType(DartObject o) {
    final reader = new ConstantReader(o);
    final clazz = reader.typeValue.element as ClassElement;
    final constructor = clazz.constructors.first;
    final token = urlOf(clazz);
    return new UseClassProviderElement(
      new TypeTokenElement(token),
      token,
      constructor: constructor?.name,
      dependencies: _parseDependencies(constructor.parameters),
    );
  }
}

/// A statically parsed token used as an identifier for injection.
///
/// See [TypeTokenElement] and [OpaqueTokenElement].
abstract class TokenElement {}

/// A statically parsed `Type` used as an identifier for injection.
class TypeTokenElement implements TokenElement {
  /// Canonical URL of the source location and class name being referenced.
  final Uri url;

  @visibleForTesting
  const TypeTokenElement(this.url);
}

/// A statically parsed `OpaqueToken` used as an identifier for injection.
class OpaqueTokenElement implements TokenElement {
  /// Canonical name of an `OpaqueToken`.
  final String identifier;

  @visibleForTesting
  const OpaqueTokenElement(this.identifier);
}

/// Statically analyzed arguments needed to invoke a constructor or function.
class Dependencies {
  /// Positional arguments, in order analyzed.
  final List<DependencyElement> positional;

  /// Named arguments.
  final Map<String, DependencyElement> named;

  @visibleForTesting
  const Dependencies(this.positional, [this.named = const {}]);
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
}

/// A statically parsed `Provider`.
abstract class ProviderElement {
  /// Canonical URL of the source location and element name being referenced.
  final TokenElement token;

  const ProviderElement._(this.token);
}

/// A statically parsed `Provider` that describes a new class instance.
class UseClassProviderElement extends ProviderElement {
  /// A reference to the class type to create.
  final Uri useClass;

  /// Constructor name to invoke.
  ///
  /// If `null`, assumed to be the default constructor.
  final String constructor;

  /// Arguments that are dependencies to the class.
  final Dependencies dependencies;

  @visibleForTesting
  const UseClassProviderElement(
    TokenElement e,
    this.useClass, {
    @required this.constructor,
    @required this.dependencies,
  })
      : super._(e);
}

/// A statically parsed `Provider` that describes a function invocation.
class UseFactoryProviderElement extends ProviderElement {
  /// A reference to the static function to invoke.
  final Uri useFactory;

  /// Arguments that are dependencies to the factory.
  final Dependencies dependencies;

  @visibleForTesting
  const UseFactoryProviderElement(
    TokenElement e,
    this.useFactory, {
    @required this.dependencies,
  })
      : super._(e);
}

/// A statically parsed `Provider` that describes a constant expression.
class UseValueProviderElement extends ProviderElement {
  /// A reference to the constant expression to generate.
  final Revivable useValue;

  @visibleForTesting
  const UseValueProviderElement(TokenElement e, this.useValue) : super._(e);
}
