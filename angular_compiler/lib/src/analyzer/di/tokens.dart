import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/cli.dart';

import '../link.dart';
import '../types.dart';

/// Support for reading and parsing a "token" for dependency injection.
///
/// In AngularDart this is either an `OpaqueToken` or a `Type`.
class TokenReader {
  /// The set of `typedef`s that are allowed to be used as tokens.
  final Set<TypeLink> allowedTypeDefs;

  const TokenReader({this.allowedTypeDefs = const <TypeLink>{}});

  /// Throws an error if [dartType] is a function-type not in [allowed].
  static void assertNotFunctionType(
    DartType dartType, {
    @required Element on,
    @required Set<TypeLink> allowed,
  }) {
    assert(on != null);
    assert(allowed != null);
    if (dartType is FunctionType) {
      final toLink = linkTypeOf(dartType);
      if (!allowed.contains(toLink)) {
        final name = toLink.symbol;
        final error = 'Unsupported token for injection: $name.\n\n'
            'In previous versions of AngularDart it was valid to inject '
            'based on a typedef or function type directly. However, in Dart '
            '2.x+ typedefs and function types are canonicalized, and not '
            'unique enough, making it easy to misuse.\n\n'
            'Consider using an OpaqueToken with a description instead:\n'
            '  typedef $name = Function(...);\n'
            '  const ${name}Token = OpaqueToken<$name>(\'uniqueName\');';
        BuildError.throwForElement(on, error);
      }
    }
  }

  /// Returns [object] parsed into a [TokenElement].
  ///
  /// Only a [DartType] or `OpaqueToken` are currently supported.
  TokenElement parseTokenObject(DartObject object, [ParameterElement element]) {
    final constant = ConstantReader(object);
    if (constant.isNull) {
      final errorMsg = 'Annotation on element has errors and was unresolvable.';
      if (element != null) {
        BuildError.throwForElement(element, errorMsg);
      }
      throw FormatException(errorMsg);
    }
    if (constant.isType) {
      final typeValue = constant.typeValue;
      // TODO: assertNotFunctionType.
      return TypeTokenElement(linkTypeOf(typeValue));
    }
    if (constant.instanceOf($OpaqueToken)) {
      return _parseOpaqueToken(constant, element);
    }
    final error =
        'Not a valid token for injection: $object. In previous versions of '
        'AngularDart it was valid to try and inject by other token types '
        'expressable in Dart. However, compile-time injection now only '
        'supports either "Type", "OpaqueToken", "MultiToken" or a class '
        'extending "OpaqueToken" or "MultiToken".\n\n'
        'However: ${object.type} was passed, which is not supported';
    if (element != null) {
      BuildError.throwForElement(element, error);
    }
    throw BuildError(error);
  }

  /// Returns [constant] parsed into an [OpaqueTokenElement].
  OpaqueTokenElement _parseOpaqueToken(ConstantReader constant, [Element on]) {
    final value = constant.objectValue;
    final valueType = value.type;
    List<DartType> typeArgs;
    if (!$OpaqueToken.isExactlyType(valueType) &&
        !$MultiToken.isExactlyType(valueType)) {
      final clazz = valueType.element;
      if (clazz is ClassElement) {
        typeArgs = clazz.supertype.typeArguments;
      }
    } else {
      typeArgs = valueType.typeArguments;
    }
    final uniqueName = constant.read('_uniqueName').stringValue;

    return OpaqueTokenElement(
      uniqueName,
      isMultiToken: constant.instanceOf($MultiToken),
      classUrl: linkToOpaqueToken(constant.objectValue.type),
      typeUrl: typeArgs.isNotEmpty ? linkTypeOf(typeArgs.first) : null,
    );
  }

  /// Returns [type] as a [TypeLink] to the corresponding class definition.
  ///
  /// Runs a number of validations to ensure that the class is defined properly
  /// and in a way that the AngularDart compilers are able to use for code
  /// generation.
  TypeLink linkToOpaqueToken(DartType type) {
    if (!$OpaqueToken.isAssignableFromType(type)) {
      BuildError.throwForElement(type.element, 'Must implement OpaqueToken.');
    }
    if ($OpaqueToken.isExactlyType(type) || $MultiToken.isExactlyType(type)) {
      return linkTypeOf(type);
    }
    final clazz = type.element as ClassElement;
    if (clazz.interfaces.isNotEmpty || clazz.mixins.isNotEmpty) {
      BuildError.throwForElement(
        type.element,
        'A sub-type of OpaqueToken cannot implement or mixin any interfaces.',
      );
    }
    if (clazz.isPrivate || clazz.isAbstract) {
      BuildError.throwForElement(
        type.element,
        'Must not be abstract or a private (i.e. prefixed with `_`) class.',
      );
    }
    if (clazz.constructors.length != 1 ||
        clazz.unnamedConstructor == null ||
        !clazz.unnamedConstructor.isConst ||
        clazz.unnamedConstructor.parameters.isNotEmpty ||
        clazz.typeParameters.isNotEmpty) {
      BuildError.throwForElement(
        type.element,
        ''
        'A sub-type of OpaqueToken must have a single unnamed const '
        'constructor with no parameters or type parameters. For example, '
        'consider writing instead:\n'
        '  class ${clazz.name} extends ${clazz.supertype.name} {\n'
        '    const ${clazz.name}();\n'
        '  }\n\n'
        'We may loosten these restrictions in the future. See: '
        'https://github.com/dart-lang/angular/issues/899',
      );
    }
    if (!$OpaqueToken.isExactlyType(clazz.supertype) &&
        !$MultiToken.isExactlyType(clazz.supertype)) {
      BuildError.throwForElement(
        type.element,
        ''
        'A sub-type of OpaqueToken must directly extend OpaqueToken or '
        'MultiToken, and cannot extend another class that in turn extends '
        'OpaqueToken or MultiToken.\n\n'
        'We may loosten these restrictions in the future. See: '
        'https://github.com/dart-lang/angular/issues/899',
      );
    }
    return linkTypeOf(type);
  }

  /// Returns [element] parsed into a [TokenElement].
  ///
  /// Uses the type definition, unless `@Inject` is specified.
  TokenElement parseTokenParameter(ParameterElement element) {
    final DartObject constTypeOrToken =
        $Inject.firstAnnotationOfExact(element)?.getField('token') ??
            $OpaqueToken.firstAnnotationOf(element);
    return constTypeOrToken != null
        ? parseTokenObject(constTypeOrToken, element)
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
      TypeTokenElement(linkTypeOf(type));
}

/// A statically parsed token used as an identifier for injection.
///
/// See [TypeTokenElement] and [OpaqueTokenElement].
abstract class TokenElement {}

/// A statically parsed `Type` used as an identifier for injection.
class TypeTokenElement implements TokenElement {
  /// References the type `dynamic`.
  static const TypeTokenElement $dynamic = TypeTokenElement(TypeLink.$dynamic);

  /// Canonical URL of the source location and class name being referenced.
  final TypeLink link;

  const TypeTokenElement(this.link);

  @override
  bool operator ==(Object o) => o is TypeTokenElement && link == o.link;

  @override
  int get hashCode => link.hashCode;

  /// Whether this is a considered the type `dynamic`.
  bool get isDynamic => link.isDynamic;

  @override
  String toString() => 'TypeTokenElement {$link}';
}

/// A statically parsed `OpaqueToken` used as an identifier for injection.
class OpaqueTokenElement implements TokenElement {
  static final _dynamic = Uri.parse('dart:core#dynamic');

  /// Canonical name of an `OpaqueToken`.
  final String identifier;

  /// Whether this represents a `MultiToken` class.
  final bool isMultiToken;

  /// What the type of the class of the token is.
  ///
  /// This could be a built-in, like `OpaqueToken` or `MultiToken`, _or_ a user
  /// created class that _extends_ either built-in token type.
  final TypeLink classUrl;

  /// What the type argument of the token is, or `null` if it is `dynamic`.
  final TypeLink typeUrl;

  @visibleForTesting
  const OpaqueTokenElement(
    this.identifier, {
    @required this.classUrl,
    this.typeUrl,
    @required this.isMultiToken,
  });

  @override
  bool operator ==(Object o) {
    if (o is OpaqueTokenElement) {
      return identifier == o.identifier &&
              classUrl == o.classUrl &&
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
    return identifier.hashCode ^
        classUrl.hashCode ^
        isMultiToken.hashCode ^
        typeUrl.hashCode;
  }

  @override
  String toString() {
    return '${classUrl.symbol} {$identifier:${typeUrl ?? _dynamic}}';
  }
}
