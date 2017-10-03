import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../types.dart';

/// Support for reading and parsing a "token" for dependency injection.
///
/// In AngularDart this is either an `OpaqueToken` or a `Type`.
class TokenReader {
  /// Whether to allow arbitrary `const/new` objects as tokens.
  final bool allowArbitraryTokens;

  /// Whether to allow [int] and [String] to be tokens.
  final bool allowLiteralTokens;

  /// Whether to compute [TypeTokenElement.prefix].
  ///
  /// This is required currently by the `ReflectorEmitter`.
  final bool computePrefixForTypes;

  const TokenReader({
    this.allowArbitraryTokens: true,
    this.allowLiteralTokens: true,
    this.computePrefixForTypes: true,
  });

  /// Returns [object] parsed into a [TokenElement].
  ///
  /// Only a [DartType] or `OpaqueToken` are currently supported.
  TokenElement parseTokenObject(DartObject object, [ParameterElement element]) {
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
    if (allowLiteralTokens) {
      if (constant.isInt) {
        return new LiteralTokenElement('${constant.intValue}');
      }
      if (constant.isString) {
        return new LiteralTokenElement("r'${constant.stringValue}'");
      }
    }
    if (allowArbitraryTokens) {
      final revive = constant.revive();
      if (revive != null) {
        if (element != null) {
          // Hacky case for supporting @Inject(some_lib.someConstField).
          final expression = element
              .computeNode()
              .metadata
              .firstWhere((a) => a.name.name == 'Inject')
              .arguments
              .arguments
              .first
              .toSource();
          return new LiteralTokenElement('$expression');
        }
        return new LiteralTokenElement('const ${revive.source.fragment}()');
      }
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
        ? parseTokenObject(inject.getField('token'), element)
        : parseTokenType(element);
  }

  /// Returns the type of [element] as a [TokenElement].
  TypeTokenElement parseTokenType(ParameterElement element) {
    final prefix = computePrefixForTypes ? prefixOf(element) : null;
    return _parseType(element.type, prefix);
  }

  /// Returns the type parameter [element] as a [TokenElement].
  ///
  /// Does not support [TypeTokenElement.prefix], it will always be `null`.
  TypeTokenElement parseTokenTypeOf(DartType type) {
    return _parseType(type, null);
  }

  TypeTokenElement _parseType(
    DartType type, [
    String prefix,
  ]) =>
      new TypeTokenElement(
        urlOf(type.element, getTypeName(type)),
        generics: type is ParameterizedType
            ? type.typeParameters.map((p) => _parseType(p.type)).toList()
            : const [],
        prefix: prefix,
      );
}

/// A statically parsed token used as an identifier for injection.
///
/// See [TypeTokenElement] and [OpaqueTokenElement].
abstract class TokenElement {}

/// A statically parsed `Type` used as an identifier for injection.
class TypeTokenElement implements TokenElement {
  /// References the type `dynamic`.
  static const TypeTokenElement $dynamic = const _DynamicTypeElement();

  /// Canonical URL of the source location and class name being referenced.
  final Uri url;

  /// Optional; prefix used when importing this token.
  final String prefix;

  /// Generic type parameters, if any.
  final List<TypeTokenElement> generics;

  @visibleForTesting
  const TypeTokenElement(this.url, {this.generics: const [], this.prefix});

  @override
  bool operator ==(Object o) =>
      o is TypeTokenElement &&
      url == o.url &&
      prefix == o.prefix &&
      const ListEquality().equals(generics, o.generics);

  @override
  int get hashCode =>
      url.hashCode ^ prefix.hashCode ^ const ListEquality().hash(generics);

  /// Whether this is a considered the type `dynamic`.
  bool get isDynamic =>
      url.scheme == 'dart' && url.path == 'core' && url.fragment == 'dynamic';

  @override
  String toString() =>
      'TypeTokenElement {$url, prefix: $prefix, generic: $generics}';
}

class _DynamicTypeElement extends TypeTokenElement {
  const _DynamicTypeElement() : super(null);

  @override
  Uri get url => new Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');

  @override
  String get prefix => null;

  @override
  bool get isDynamic => true;
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

/// A statically parsed literal (such as a `String`).
///
/// This is considered soft-deprecated.
class LiteralTokenElement implements TokenElement {
  /// Literal token.
  final String literal;

  @visibleForTesting
  const LiteralTokenElement(this.literal);

  @override
  bool operator ==(Object o) =>
      o is LiteralTokenElement && literal == o.literal;

  @override
  int get hashCode => literal.hashCode;

  @override
  String toString() => literal;
}
