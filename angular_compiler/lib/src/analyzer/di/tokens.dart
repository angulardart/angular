import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../types.dart';

/// Support for reading and parsing a "token" for dependency injection.
///
/// In AngularDart this is either an `OpaqueToken` or a `Type`.
class TokenReader {
  const TokenReader();

  /// Returns [object] parsed into a [TokenElement].
  ///
  /// Only a [DartType] or `OpaqueToken` are currently supported.
  TokenElement parseTokenObject(DartObject object) {
    final constant = new ConstantReader(object);
    if (constant.isNull) {
      throw new FormatException('Expected token, but got "null".');
    }
    if (constant.isType) {
      return new TypeTokenElement(urlOf(constant.typeValue.element));
    }
    if (constant.instanceOf($OpaqueToken)) {
      return new OpaqueTokenElement(constant.read('_desc').stringValue);
    }
    throw new ArgumentError.value(
        object,
        'object',
        'Could not parse into a token for dependency injection. Only a `Type` '
        'or an `OpaqueToken` is supported, but ${object.type} was used.');
  }

  /// Returns [element] parsed into a [TokenElement].
  ///
  /// Uses the type definition, unless `@Inject` is specified.
  TokenElement parseTokenParameter(ParameterElement element) {
    final inject = $Inject.firstAnnotationOfExact(element);
    return inject != null
        ? parseTokenObject(inject.getField('token'))
        : new TypeTokenElement(urlOf(element.type.element));
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

  @override
  bool operator ==(Object o) => o is TypeTokenElement && url == o.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'TypeTokenElement {$url}';
}

/// A statically parsed `OpaqueToken` used as an identifier for injection.
class OpaqueTokenElement implements TokenElement {
  /// Canonical name of an `OpaqueToken`.
  final String identifier;

  @visibleForTesting
  const OpaqueTokenElement(this.identifier);

  @override
  bool operator ==(Object o) =>
      o is OpaqueTokenElement && identifier == o.identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() => 'OpaqueTokenElement {$identifier}';
}
