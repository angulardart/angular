import 'package:analyzer/dart/constant/value.dart';
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
    final reader = new ConstantReader(o);
    final token = _parseToken(reader.read('token'));
    final useClass = reader.read('useClass');
    // const Provider(<token>, useClass: Foo)
    if (!useClass.isNull) {
      // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
      return new UseClassProviderElement(
        token,
        urlOf(useClass.typeValue.element),
      );
    }
    // Base case: const Provider(Foo) with no fields set.
    if (token is TypeTokenElement) {
      // TODO(matanl): Validate that Foo has @Injectable() when flag is set.
      return new UseClassProviderElement(token, token.url);
    }
    throw new UnimplementedError('Not yet implemented for "$o".');
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
    final token = urlOf(reader.typeValue.element);
    return new UseClassProviderElement(new TypeTokenElement(token), token);
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

  @visibleForTesting
  const UseClassProviderElement(TokenElement e, this.useClass) : super._(e);
}
