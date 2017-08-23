import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
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

  /// Parses a static object representing a list of providers.
  List<ProviderElement> parseModule(DartObject o) {
    if (!isModule(o)) {
      throw new FormatException('Expceted Module, got "${o.type.name}".');
    }
    return _parseModule(o).toList();
  }

  Iterable<ProviderElement> _parseModule(DartObject o) sync* {
    if (isList(o)) {
      yield* o.toListValue().map(_parseModule).expand((i) => i);
    } else if (isProvider(o) || isType(o)) {
      yield parseProvider(o);
    } else {
      throw new FormatException('Expected Provider, got "${o.type.name}".');
    }
  }

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
    final token = _tokenReader.parseTokenObject(o.getField('token'));
    final useClass = reader.read('useClass');
    if (!useClass.isNull) {
      return _parseUseClass(token, useClass.typeValue.element);
    }
    final useFactory = reader.read('useFactory');
    if (!useFactory.isNull) {
      return _parseUseFactory(token, reader);
    }
    // const Provider(<token>, useValue: constExpression)
    final useValue = reader.read('useValue');
    if (!useValue.isString || useValue.stringValue != '__noValueProvided__') {
      return _parseUseValue(token, useValue.objectValue);
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
    return new UseClassProviderElement(
      token,
      urlOf(clazz),
      dependencies: _dependencyReader.parseDependencies(clazz),
    );
  }

  // const Provider(<token>, useFactory: createFoo)
  ProviderElement _parseUseFactory(
    TokenElement token,
    ConstantReader provider,
  ) {
    final factoryElement = provider.read('useFactory').objectValue.type.element;
    final manualDeps = provider.read('dependencies');
    // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
    return new UseFactoryProviderElement(
      token,
      urlOf(factoryElement),
      dependencies: manualDeps.isList
          ? _dependencyReader.parseDependenciesList(
              factoryElement, manualDeps.listValue)
          : _dependencyReader.parseDependencies(factoryElement),
    );
  }

  ProviderElement _parseUseValue(TokenElement token, DartObject useValue) {
    // TODO(matanl): For corner-cases that can't be revived, display error.
    return new UseValueProviderElement._(
      token,
      _reviveInvocationsOf(useValue),
    );
  }

  Object _reviveInvocationsOf(DartObject o) {
    final reader = new ConstantReader(o);
    // TODO: "isPrimitive" @ https://github.com/dart-lang/source_gen/issues/256.
    if (reader.isBool ||
        reader.isString ||
        reader.isDouble ||
        reader.isInt ||
        reader.isNull ||
        reader.isSymbol) {
      return reader.literalValue;
    }
    if (reader.isList) {
      return reader.listValue.map(_reviveInvocationsOf).toList();
    }
    if (reader.isMap) {
      return mapMap(reader.mapValue,
          key: (k, _) => _reviveInvocationsOf(k),
          value: (_, v) => _reviveInvocationsOf(v));
    }
    return reader.revive();
  }

  /// Returns a provider element representing a single type.
  ProviderElement _parseType(DartObject o) {
    final reader = new ConstantReader(o);
    final clazz = reader.typeValue.element as ClassElement;
    final token = urlOf(clazz);
    return new UseClassProviderElement(
      new TypeTokenElement(token),
      token,
      dependencies: _dependencyReader.parseDependencies(clazz),
    );
  }
}

/// A statically parsed `Provider`.
abstract class ProviderElement {
  /// Canonical URL of the source location and element name being referenced.
  final TokenElement token;

  const ProviderElement._(this.token);

  @override
  bool operator ==(Object o) => o is ProviderElement && o.token == token;

  @mustCallSuper
  @override
  int get hashCode => token.hashCode;
}

/// A statically parsed `Provider` that describes a new class instance.
class UseClassProviderElement extends ProviderElement {
  /// A reference to the class type to create.
  final Uri useClass;

  /// Arguments that are dependencies to the class.
  final DependencyInvocation<ConstructorElement> dependencies;

  @visibleForTesting
  const UseClassProviderElement(
    TokenElement e,
    this.useClass, {
    @required this.dependencies,
  })
      : super._(e);

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

/// A statically parsed `Provider` that describes a function invocation.
class UseFactoryProviderElement extends ProviderElement {
  /// A reference to the static function to invoke.
  final Uri useFactory;

  /// Arguments that are dependencies to the factory.
  final DependencyInvocation<FunctionElement> dependencies;

  @visibleForTesting
  const UseFactoryProviderElement(
    TokenElement e,
    this.useFactory, {
    @required this.dependencies,
  })
      : super._(e);

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
  final Object useValue;

  // Not visible for testing because its impractical to create one.
  const UseValueProviderElement._(
    TokenElement e,
    this.useValue,
  )
      : super._(e);
}
