import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../link.dart';
import '../types.dart';

/// Support for reading and parsing a "token" for dependency injection.
///
/// In AngularDart this is either an `OpaqueToken` or a `Type`.
class TokenReader {
  /// Whether to allow arbitrary `const/new` objects as tokens.
  final bool allowArbitraryTokens;

  /// Whether to allow [int] and [String] to be tokens.
  final bool allowLiteralTokens;

  const TokenReader({
    this.allowArbitraryTokens: true,
    this.allowLiteralTokens: true,
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
      return new TypeTokenElement(linkTypeOf(constant.typeValue));
    }
    if (constant.instanceOf($OpaqueToken)) {
      final value = constant.objectValue;
      return new OpaqueTokenElement(
        constant.read('_desc').stringValue,
        isMultiToken: constant.instanceOf($MultiToken),
        typeUrl: value.type.typeArguments.isNotEmpty
            ? linkTypeOf(value.type.typeArguments.first)
            : null,
      );
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
    return _parseType(element.type);
  }

  /// Returns the type parameter [element] as a [TokenElement].
  TypeTokenElement parseTokenTypeOf(DartType type) {
    return _parseType(type);
  }

  TypeTokenElement _parseType(DartType type) =>
      new TypeTokenElement(linkTypeOf(type));
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
  final TypeLink link;

  @visibleForTesting
  const TypeTokenElement(this.link);

  @override
  bool operator ==(Object o) => o is TypeTokenElement && link == o.link;

  @override
  int get hashCode => link.hashCode;

  /// Whether this is a considered the type `dynamic`.
  bool get isDynamic => link == TypeLink.$dynamic;

  @override
  String toString() => 'TypeTokenElement {$link}';
}

class _DynamicTypeElement extends TypeTokenElement {
  const _DynamicTypeElement() : super(null);

  @override
  TypeLink get link => TypeLink.$dynamic;

  @override
  bool get isDynamic => true;
}

/// A statically parsed `OpaqueToken` used as an identifier for injection.
class OpaqueTokenElement implements TokenElement {
  static final _dynamic = Uri.parse('dart:core#dynamic');

  /// Canonical name of an `OpaqueToken`.
  final String identifier;

  /// Whether this represents a `MultiToken` class.
  final bool isMultiToken;

  /// What the type of the token is, or `null` if it is `dynamic`.
  final TypeLink typeUrl;

  @visibleForTesting
  const OpaqueTokenElement(
    this.identifier, {
    this.typeUrl,
    @required this.isMultiToken,
  });

  @override
  bool operator ==(Object o) {
    if (o is OpaqueTokenElement) {
      return identifier == o.identifier &&
              isMultiToken == o.isMultiToken &&
              typeUrl == o.typeUrl ||
          _bothTypesDynamic(typeUrl, o.typeUrl);
    }
    return false;
  }

  static bool _bothTypesDynamic(TypeLink a, TypeLink b) =>
      (a == null || a == TypeLink.$dynamic) ==
      (b == null || b == TypeLink.$dynamic);

  @override
  int get hashCode {
    return identifier.hashCode ^ isMultiToken.hashCode ^ typeUrl.hashCode;
  }

  @override
  String toString() {
    return '${isMultiToken ? 'MultiToken' : 'OpaqueToken'} {$identifier:${typeUrl ?? _dynamic}';
  }
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
