import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../link.dart';
import '../types.dart';
import 'dependencies.dart';
import 'tokens.dart';

/// Support for reading and parsing constant `Provider`s into data structures.
class ProviderReader {
  final DependencyReader _dependencyReader;
  final TokenReader _tokenReader;

  const ProviderReader(
      {DependencyReader dependencyReader: const DependencyReader(),
      TokenReader tokenReader: const TokenReader()})
      : _dependencyReader = dependencyReader,
        _tokenReader = tokenReader;

  /// Returns whether an object represents a `Provider`.
  @protected
  bool isProvider(DartObject o) => $Provider.isAssignableFromType(o.type);

  /// Returns whether an object represents a [Type].
  @protected
  bool isType(DartObject o) => o.toTypeValue() != null;

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
      final typeName = getTypeName(o.type);
      throw new FormatException('Expected Provider, got "$typeName".');
    }
    return _parseProvider(o);
  }

  ProviderElement _parseProvider(DartObject o) {
    final reader = new ConstantReader(o);
    final token = _tokenReader.parseTokenObject(
      reader.read('token').objectValue,
    );
    final useClass = reader.read('useClass');
    if (!useClass.isNull) {
      return _parseUseClass(token, o, useClass.typeValue.element);
    }
    final useFactory = reader.read('useFactory');
    if (!useFactory.isNull) {
      return _parseUseFactory(token, reader);
    }
    // const Provider(<token>, useValue: constExpression)
    final useValue = reader.read('useValue');
    if (useValue == null || useValue.isNull) {
      // const Provider(<token>, useValue: null)
      //
      // This pattern is used to "disable" a service, for example:
      //  const Provider(TimingService, useValue: null)
      //
      // Teams that inject `TimingService` @Optional() will stop using it.
      return _parseUseValue(token, o, null);
    }
    if (!useValue.isString || useValue.stringValue != '__noValueProvided__') {
      return _parseUseValue(token, o, useValue.objectValue);
    }
    final useExisting = reader.read('useExisting');
    if (!useExisting.isNull) {
      return _parseUseExisting(token, o, useExisting.objectValue);
    }
    // Base case: const Provider(Foo) with no fields set.
    if (token is TypeTokenElement) {
      return _parseUseClass(token, o, reader.read('token').typeValue.element);
    }
    throw new UnsupportedError('Could not parse provider: $o.');
  }

  // const Provider(<token>, useClass: Foo)
  ProviderElement _parseUseClass(
    TokenElement token,
    DartObject provider,
    ClassElement clazz,
  ) {
    // TODO(matanl): Validate that clazz has @Injectable() when flag is set.
    return new UseClassProviderElement(
      token,
      linkTypeOf(typeArgumentOf(provider)),
      linkTypeOf(clazz.type),
      dependencies: _dependencyReader.parseDependencies(clazz),
    );
  }

  // const Provider(<token>, useExisting: <other>)
  ProviderElement _parseUseExisting(
    TokenElement token,
    DartObject provider,
    DartObject object,
  ) {
    return new UseExistingProviderElement(
      token,
      linkTypeOf(typeArgumentOf(provider)),
      _tokenReader.parseTokenObject(object),
    );
  }

  // const Provider(<token>, useFactory: createFoo)
  ProviderElement _parseUseFactory(
    TokenElement token,
    ConstantReader provider,
  ) {
    final factoryElement = provider.read('useFactory').objectValue.type.element;
    final manualDeps = provider.read('deps');
    // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
    return new UseFactoryProviderElement(
      token,
      linkTypeOf(typeArgumentOf(provider.objectValue)),
      urlOf(factoryElement),
      dependencies: manualDeps.isList
          ? _dependencyReader.parseDependenciesList(
              factoryElement, manualDeps.listValue)
          : _dependencyReader.parseDependencies(factoryElement),
    );
  }

  ProviderElement _parseUseValue(
    TokenElement token,
    DartObject provider,
    DartObject useValue,
  ) {
    // TODO(matanl): For corner-cases that can't be revived, display error.
    return new UseValueProviderElement._(
      token,
      linkTypeOf(typeArgumentOf(provider)),
      useValue,
    );
  }

  /// Returns a provider element representing a single type.
  ProviderElement _parseType(DartObject o) {
    final reader = new ConstantReader(o);
    final clazz = reader.typeValue.element as ClassElement;
    final token = linkTypeOf(clazz.type);
    return new UseClassProviderElement(
      new TypeTokenElement(token),
      linkTypeOf(typeArgumentOf(o)),
      token,
      dependencies: _dependencyReader.parseDependencies(clazz),
    );
  }
}

/// A statically parsed `Provider`.
abstract class ProviderElement {
  /// Canonical URL of the source location and element name being referenced.
  final TokenElement token;

  /// The `T` type of `Provider<T>`.
  final TypeLink providerType;

  final bool _isExplictlyMulti;

  const ProviderElement._(
    this.token,
    this.providerType,
    this._isExplictlyMulti,
  );

  @override
  bool operator ==(Object o) => o is ProviderElement && o.token == token;

  /// Whether this represents a multi-binding.
  bool get isMulti {
    final token = this.token;
    if (token is OpaqueTokenElement && token.isMultiToken) {
      return true;
    }
    return _isExplictlyMulti;
  }

  @mustCallSuper
  @override
  int get hashCode => token.hashCode;
}

/// A statically parsed `Provider` that describes a new class instance.
class UseClassProviderElement extends ProviderElement {
  /// A reference to the class type to create.
  final TypeLink useClass;

  /// Arguments that are dependencies to the class.
  final DependencyInvocation<ConstructorElement> dependencies;

  @visibleForTesting
  const UseClassProviderElement(
    TokenElement e,
    TypeLink providerType,
    this.useClass, {
    @required this.dependencies,
    bool multi: false,
  }) : super._(e, providerType, multi);

  @override
  bool operator ==(Object o) =>
      o is UseClassProviderElement &&
      o.useClass == useClass &&
      o.dependencies == dependencies &&
      super == o;

  @override
  int get hashCode =>
      useClass.hashCode ^ dependencies.hashCode ^ super.hashCode;

  @override
  String toString() =>
      'UseClassProviderElement ' +
      {
        'token': '$token',
        'useClass': '$useClass',
        'dependencies': '$dependencies',
      }.toString();
}

/// A statically parsed `Provider` that redirects one token to another.
class UseExistingProviderElement extends ProviderElement {
  final TokenElement redirect;

  const UseExistingProviderElement(
    TokenElement e,
    TypeLink providerType,
    this.redirect, {
    bool multi: false,
  }) : super._(e, providerType, multi);

  @override
  bool operator ==(Object o) =>
      o is UseExistingProviderElement && o.redirect == redirect && super == o;

  @override
  int get hashCode => redirect.hashCode ^ super.hashCode;

  @override
  String toString() =>
      'UseFactoryProviderElement ' +
      {
        'token': '$token',
        'redirect': '$redirect',
      }.toString();
}

/// A statically parsed `Provider` that describes a function invocation.
class UseFactoryProviderElement extends ProviderElement {
  /// A reference to the static function to invoke.
  final Uri useFactory;

  /// Arguments that are dependencies to the factory.
  final DependencyInvocation<FunctionElement> dependencies;

  @visibleForTesting
  const UseFactoryProviderElement(
    TokenElement e,
    TypeLink providerType,
    this.useFactory, {
    @required this.dependencies,
    bool multi: false,
  }) : super._(e, providerType, multi);

  @override
  bool operator ==(Object o) =>
      o is UseFactoryProviderElement &&
      o.useFactory == useFactory &&
      o.dependencies == dependencies &&
      super == o;

  @override
  int get hashCode =>
      useFactory.hashCode ^ dependencies.hashCode ^ super.hashCode;

  @override
  String toString() =>
      'UseFactoryProviderElement ' +
      {
        'token': '$token',
        'useClass': '$useFactory',
        'dependencies': '$dependencies',
      }.toString();
}

/// A statically parsed `Provider` that describes a constant expression.
class UseValueProviderElement extends ProviderElement {
  /// A reference to the constant expression or literal to generate.
  final DartObject useValue;

  // Not visible for testing because its impractical to create one.
  const UseValueProviderElement._(
    TokenElement e,
    TypeLink providerType,
    this.useValue, {
    bool multi: false,
  }) : super._(e, providerType, multi);
}
