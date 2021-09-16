import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angular_compiler/v2/context.dart';
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
      {DependencyReader dependencyReader = const DependencyReader(),
      TokenReader tokenReader = const TokenReader()})
      : _dependencyReader = dependencyReader,
        _tokenReader = tokenReader;

  /// Returns whether an object represents a `Provider`.
  @protected
  bool isProvider(DartObject o) => $Provider.isAssignableFromType(o.type!);

  /// Returns whether an object represents a [Type].
  @protected
  bool isType(DartObject o) => o.toTypeValue() != null;

  /// Parses a static object representing a `Provider`.
  ProviderElement parseProvider(DartObject o) {
    if (isType(o)) {
      // Represents "Foo", which is legacy short-hand for "ClassProvider(Foo)".
      return _parseTypeAsImplicitClassProvider(o);
    }
    if (!isProvider(o)) {
      final typeName = getTypeName(o.type!);
      throw FormatException('Expected Provider, got "$typeName".');
    }
    return _parseProvider(o);
  }

  ProviderElement _parseProvider(DartObject o) {
    final reader = ConstantReader(o);
    final value = reader.read('token');
    if (value.isNull) {
      throw NullTokenException(o);
    }
    final token = _tokenReader.parseTokenObject(value.objectValue);
    final useClass = reader.read('useClass');
    if (!useClass.isNull) {
      return _parseUseClass(
        token,
        o,
        useClass.typeValue.element as ClassElement,
      );
    }
    final useFactory = reader.read('useFactory');
    if (!useFactory.isNull) {
      return _parseUseFactory(token, reader);
    }
    // const Provider(<token>, useValue: constExpression)
    final useValue = reader.read('useValue');
    if (useValue.isNull) {
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
      // Ensure this isn't a FactoryProvider with a null function:
      // https://github.com/angulardart/angular/issues/1500
      if (!$Provider.isExactlyType(o.type!)) {
        throw NullFactoryException(o);
      }
      return _parseUseClass(
        token,
        o,
        reader.read('token').typeValue.element as ClassElement,
      );
    }
    throw UnsupportedProviderException(o, 'Could not parse provider');
  }

  TypeLink _actualProviderType(
    DartType providerClass,
    DartType providerType,
    TokenElement token,
  ) {
    // Only the "new" Provider sub-types support type inference:
    // i.e. ValueProvider<T>.forToken(OpaqueToken<T>)
    //
    // Provider(Object token) does not have any type inference support, so
    // using OpaqueToken.type instead of Provider.type would be invalid and
    // a breaking change.
    if (!$Provider.isExactlyType(providerClass) &&
        token is OpaqueTokenElement) {
      // Recover from https://github.com/dart-lang/sdk/issues/32290.
      return token.typeUrl ?? TypeLink.$dynamic;
    }
    // We can't use the type from `token` if it's a `TypeTokenElement` because
    // there's currently no correlation between the token and the provider type:
    // http://b/145819936.
    return linkTypeOf(providerType);
  }

  // const Provider(<token>, useClass: Foo)
  ProviderElement _parseUseClass(
    TokenElement token,
    DartObject provider,
    ClassElement clazz,
  ) {
    return UseClassProviderElement(
      token,
      _actualProviderType(provider.type!, typeArgumentOf(provider), token),
      linkTypeOf(clazz.thisType),
      dependencies: _dependencyReader.parseDependencies(clazz),
    );
  }

  // const Provider(<token>, useExisting: <other>)
  ProviderElement _parseUseExisting(
    TokenElement token,
    DartObject provider,
    DartObject object,
  ) {
    return UseExistingProviderElement(
      token,
      _actualProviderType(provider.type!, typeArgumentOf(provider), token),
      _tokenReader.parseTokenObject(object),
    );
  }

  // const Provider(<token>, useFactory: createFoo)
  ProviderElement _parseUseFactory(
    TokenElement token,
    ConstantReader provider,
  ) {
    final objectValue = provider.read('useFactory').objectValue;
    final factoryElement = objectValue.toFunctionValue();
    if (factoryElement == null) {
      throw InvalidFactoryException(objectValue);
    }
    final manualDeps = provider.read('deps');
    return UseFactoryProviderElement(
      token,
      _actualProviderType(
        provider.objectValue.type!,
        typeArgumentOf(provider.objectValue),
        token,
      ),
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
    DartObject? useValue,
  ) {
    return UseValueProviderElement._(
      token,
      _actualProviderType(provider.type!, typeArgumentOf(provider), token),
      useValue,
    );
  }

  /// Returns a provider element representing a single type.
  ProviderElement _parseTypeAsImplicitClassProvider(DartObject o) {
    final reader = ConstantReader(o);
    final element = reader.typeValue.element;
    if (element is ClassElement) {
      final token = linkTypeOf(element.thisType);
      return UseClassProviderElement(
        TypeTokenElement(token),
        linkTypeOf(typeArgumentOf(o)),
        token,
        dependencies: _dependencyReader.parseDependencies(element),
      );
    }
    throw BuildError.forElement(element!, 'Not a class element');
  }
}

/// A statically parsed `Provider`.
abstract class ProviderElement {
  /// Canonical URL of the source location and element name being referenced.
  final TokenElement token;

  /// The `T` type of `Provider<T>`.
  final TypeLink? providerType;

  const ProviderElement._(
    this.token,
    this.providerType,
  );

  @override
  bool operator ==(Object o) => o is ProviderElement && o.token == token;

  /// Whether this represents a multi-binding.
  bool get isMulti {
    final token = this.token;
    return token is OpaqueTokenElement && token.isMultiToken;
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
    TypeLink? providerType,
    this.useClass, {
    required this.dependencies,
  }) : super._(e, providerType);

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
    this.redirect,
  ) : super._(e, providerType);

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
  final DependencyInvocation<ExecutableElement> dependencies;

  @visibleForTesting
  const UseFactoryProviderElement(
    TokenElement e,
    TypeLink? providerType,
    this.useFactory, {
    required this.dependencies,
  }) : super._(
          e,
          providerType,
        );

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
  final DartObject? useValue;

  // Not visible for testing because its impractical to create one.
  const UseValueProviderElement._(
    TokenElement e,
    TypeLink providerType,
    this.useValue,
  ) : super._(
          e,
          providerType,
        );
}

/// Thrown when a value of `null` is read for a provider token.
class NullTokenException implements Exception {
  /// Constant whose `.token` property was resolved to `null`.
  final DartObject constant;

  const NullTokenException(this.constant);
}

/// Thrown when a value of `null` is read for `FactoryProvider`.
class NullFactoryException implements Exception {
  /// Constant whose `useFactory` property was resolved to `null`.
  final DartObject constant;

  const NullFactoryException(this.constant);
}

/// Thrown when a non-factory value is attached to a `FactoryProvider`.
class InvalidFactoryException implements Exception {
  /// Constant whose `useFactory` was not a factory function.
  final DartObject constant;

  const InvalidFactoryException(this.constant);
}

class UnsupportedProviderException implements Exception {
  final DartObject constant;
  final String message;

  const UnsupportedProviderException(this.constant, this.message);
}
