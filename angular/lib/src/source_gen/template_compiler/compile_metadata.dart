import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/output/convert.dart';
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/core/di.dart';
import 'package:angular/src/core/di/decorators.dart';
import 'package:angular/src/core/metadata.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/cli.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:quiver/strings.dart' as strings;
import 'package:source_gen/source_gen.dart';

import 'dart_object_utils.dart' as dart_objects;

// TODO: Remove the following lines (for --no-implicit-casts).
// ignore_for_file: argument_type_not_assignable
// ignore_for_file: invalid_assignment

class CompileTypeMetadataVisitor
    extends SimpleElementVisitor<CompileTypeMetadata> {
  final LibraryReader _library;

  CompileTypeMetadataVisitor(this._library);

  @override
  CompileTypeMetadata visitClassElement(ClassElement element) {
    if (element.isPrivate) {
      throwFailure('Provided classes must be public: $element');
    }
    return _getCompileTypeMetadata(
      element,
      enforceClassCanBeCreated: true,
    );
  }

  @override
  CompileTypeMetadata visitFunctionElement(FunctionElement element) =>
      element.metadata.any((annotation) =>
              annotation_matcher.matchAnnotation(Directive, annotation))
          ? _getFunctionCompileTypeMetadata(element)
          : null;

  /// Finds the unnamed constructor if it is present.
  ///
  /// Otherwise, use the first encountered.
  ConstructorElement unnamedConstructor(ClassElement element) {
    ConstructorElement constructor;
    final constructors = element.constructors;
    if (constructors.isEmpty) {
      BuildError.throwForElement(element, 'No constructors found');
    }

    constructor = constructors.firstWhere(
        (constructor) => strings.isEmpty(constructor.name),
        orElse: () => constructors.first);

    if (constructor.isPrivate) {
      BuildError.throwForElement(element, 'No constructors found');
    }

    if (element.isAbstract && !constructor.isFactory) {
      logWarning(
          'Found a constructor for abstract class ${element.name} but it is '
          'not a "factory", and cannot be invoked');
      return null;
    }
    if (element.constructors.length > 1 &&
        strings.isNotEmpty(constructor.name)) {
      // No use in being a warning, as it's not something they need to fix
      // until we add a way to be able to "pick" the constructor to use.
      logNotice('Found ${element.constructors.length} constructors for class '
          '${element.name}; using constructor ${constructor.name}.');
    }
    return constructor;
  }

  CompileProviderMetadata createProviderMetadata(DartObject provider) {
    // If `provider` is a type literal, then treat it as a `useClass` provider
    // with the class literal itself as the token.
    if (provider.toTypeValue() != null) {
      var element = provider.toTypeValue().element;
      if (element is! ClassElement) {
        logWarning('Expected to find class in provider list, but instead '
            'found $provider');
        return null;
      }
      var metadata = visitClassElement(element as ClassElement);
      if (metadata == null) {
        // Was skipped.
        return null;
      }
      return new CompileProviderMetadata(
        token: new CompileTokenMetadata(identifier: metadata),
        useClass: metadata,
      );
    }
    CompileTypeMetadata providerTypeArgument;
    final typeArguments = provider.type?.typeArguments;
    if (typeArguments != null && typeArguments.isNotEmpty) {
      final genericType = typeArguments.first;
      if (!genericType.isDynamic) {
        providerTypeArgument = _getCompileTypeMetadata(
          genericType.element,
          genericTypes: genericType is ParameterizedType
              ? genericType.typeArguments
              : const [],
        );
      }
    }
    final token = dart_objects.getField(provider, 'token');

    // Workaround for analyzer bug.
    // https://github.com/dart-lang/angular/issues/917
    if (providerTypeArgument == null &&
        token?.type != null &&
        $OpaqueToken.isAssignableFromType(token.type) &&
        // Only apply "auto inference" to "new-type" Providers like
        // Value, Class, Existing, FactoryProvider.
        !$Provider.isExactlyType(provider.type) &&
        token.type.typeArguments.isNotEmpty) {
      // If we see a Provider<dynamic> (no generic type), but the token is a
      // typed OpaqueToken<T>, pretend that the Provider was actually inferred
      // as Provider<T>:
      // (Again, see https://github.com/dart-lang/angular/issues/917)
      final opaqueTokenGeneric = token.type.typeArguments.first;
      providerTypeArgument = _getCompileTypeMetadata(
        opaqueTokenGeneric.element,
        genericTypes: opaqueTokenGeneric is ParameterizedType
            ? opaqueTokenGeneric.typeArguments
            : const [],
      );
    }
    return new CompileProviderMetadata(
      token: _token(token),
      useClass: _getUseClass(provider, token),
      useExisting: _getUseExisting(provider),
      useFactory: _getUseFactory(provider),
      useValue: _getUseValue(provider),
      multi: $MultiToken.isAssignableFromType(token?.type) ||
          dart_objects.coerceBool(
            provider,
            'multi',
            defaultTo: false,
          ),
      typeArgument: providerTypeArgument,
    );
  }

  CompileTypeMetadata _getUseClass(DartObject provider, DartObject token) {
    var maybeUseClass = dart_objects.getField(provider, 'useClass');
    if (!dart_objects.isNull(maybeUseClass)) {
      var type = maybeUseClass.toTypeValue();
      if (type is InterfaceType) {
        return _getCompileTypeMetadata(
          type.element,
          enforceClassCanBeCreated: true,
        );
      } else {
        throwFailure(
            'Provider.useClass can only be used with a class, but found '
            '${type.element}');
      }
    } else if (_hasNoUseValue(provider) && _notAnythingElse(provider)) {
      final typeValue = token.toTypeValue();
      if (typeValue != null && !typeValue.isDartCoreNull) {
        return _getCompileTypeMetadata(
          typeValue.element,
          enforceClassCanBeCreated: true,
        );
      }
    }
    return null;
  }

  // Verifies this is not useExisting or useFactory.
  static bool _notAnythingElse(DartObject provider) =>
      dart_objects.isNull(dart_objects.getField(provider, 'useFactory')) &&
      dart_objects.isNull(dart_objects.getField(provider, 'useExisting'));

  CompileTokenMetadata _getUseExisting(DartObject provider) {
    var maybeUseExisting = dart_objects.getField(provider, 'useExisting');
    if (!dart_objects.isNull(maybeUseExisting)) {
      return _token(maybeUseExisting);
    }
    return null;
  }

  CompileFactoryMetadata _getUseFactory(DartObject provider) {
    var maybeUseFactory = dart_objects.getField(provider, 'useFactory');
    if (!dart_objects.isNull(maybeUseFactory)) {
      if (maybeUseFactory.type.element is FunctionTypedElement) {
        return _factoryForFunction(
          maybeUseFactory.type.element,
          dart_objects.coerceList(provider, 'deps', defaultTo: null),
        );
      } else {
        throwFailure('Provider.useFactory can only be used with a function, '
            'but found ${maybeUseFactory.type.element}');
      }
    }
    return null;
  }

  /// If [enforceClassCanBeCreated] is `true` will emit a warning (later an
  /// error) that there is invalid configuration. We don't need this for every
  /// piece of metadata.
  ///
  /// See https://github.com/dart-lang/angular/issues/906 for details.
  CompileTypeMetadata _getCompileTypeMetadata(
    ClassElement element, {
    bool enforceClassCanBeCreated: false,
    List<DartType> genericTypes: const [],
  }) =>
      new CompileTypeMetadata(
        moduleUrl: moduleUrl(element),
        name: element.name,
        diDeps: _getCompileDiDependencyMetadata(
          enforceClassCanBeCreated
              ? unnamedConstructor(element)?.parameters ?? []
              : [],
          element,
        ),
        genericTypes: genericTypes.map(fromDartType).toList(),
      );

  CompileTypeMetadata _getFunctionCompileTypeMetadata(
          FunctionElement element) =>
      new CompileTypeMetadata(
          moduleUrl: moduleUrl(element),
          name: element.name,
          diDeps: _getCompileDiDependencyMetadata(element.parameters, element));

  bool _hasNoUseValue(DartObject provider) {
    final useValue = dart_objects.getField(provider, 'useValue');
    final isNull = dart_objects.isNull(useValue);
    return !isNull && useValue.toStringValue() == noValueProvided;
  }

  o.Expression _getUseValue(DartObject provider) {
    // TODO(matanl): This is no longer strictly necessary; refactor out.
    // Will require a bit more extensive testing.
    if (_hasNoUseValue(provider)) {
      return null;
    }
    final useValue = dart_objects.getField(provider, 'useValue');
    try {
      return _useValueExpression(useValue);
    } on _PrivateConstructorException catch (e) {
      throwFailure('Could not link provider "${provider.getField('token')}" to '
          '"${e.constructorName}". You may have valid Dart code but the '
          'angular2 compiler has limited support for `useValue` that '
          'eventually uses a private constructor. As a workaround we '
          'recommend `useFactory`.');
    }
  }

  List<CompileDiDependencyMetadata> _getCompileDiDependencyMetadata(
      List<ParameterElement> parameters, Element element) {
    List<CompileDiDependencyMetadata> deps = [];
    for (final param in parameters) {
      if (param.parameterKind == ParameterKind.NAMED) {
        // No use being a warning, since this is not prohibited; just skip.
        continue;
      }
      deps.add(_createCompileDiDependencyMetadata(param));
    }
    return deps;
  }

  CompileDiDependencyMetadata _createCompileDiDependencyMetadata(
    ParameterElement p,
  ) {
    try {
      return new CompileDiDependencyMetadata(
        token: _getToken(p),
        isAttribute: _hasAnnotation(p, Attribute),
        isSelf: _hasAnnotation(p, Self),
        isHost: _hasAnnotation(p, Host),
        isSkipSelf: _hasAnnotation(p, SkipSelf),
        isOptional: _hasAnnotation(p, Optional) || _isPositional(p),
      );
    } on ArgumentError catch (_) {
      // Handle cases where something is annotated with @Injectable() but does
      // not have something annotated properly. It's likely this is either
      // dead code or is not actually used via DI. We can ignore for now.
      logWarning(''
          'Could not resolve token for $p on ${p.enclosingElement} in '
          '${p.library.identifier}');
      return new CompileDiDependencyMetadata();
    }
  }

  CompileTokenMetadata _getToken(
          ParameterElement p) =>
      _hasAnnotation(p, Attribute)
          ? _tokenForAttribute(p)
          : _hasAnnotation(p, Inject)
              ? _tokenForInject(p)
              : $OpaqueToken.hasAnnotationOf(p)
                  ? _tokenForOpaqueToken(p)
                  : _tokenForType(p.type);

  CompileTokenMetadata _tokenForAttribute(ParameterElement p) =>
      new CompileTokenMetadata(
          value: dart_objects.coerceString(
              _getAnnotation(p, Attribute).constantValue, 'attributeName'));

  CompileTokenMetadata _tokenForInject(ParameterElement p) {
    final annotation = _getAnnotation(p, Inject);
    final injectToken = annotation.computeConstantValue();
    final token = dart_objects.getField(injectToken, 'token');
    return _token(token, annotation);
  }

  CompileTokenMetadata _tokenForOpaqueToken(ParameterElement p) {
    final annotation = $OpaqueToken.firstAnnotationOf(p);
    return _token(annotation);
  }

  CompileTokenMetadata _annotationToToken(ElementAnnotationImpl annotation) {
    String name;
    final id = annotation.annotationAst.arguments.arguments.first;
    if (id is Identifier) {
      if (id is PrefixedIdentifier) {
        name = id.identifier.name;
      } else {
        name = id.name;
      }
    }
    return new CompileTokenMetadata(
      identifier: new CompileIdentifierMetadata(
        name: name,
        moduleUrl: moduleUrl((id as Identifier).staticElement.library),
      ),
    );
  }

  CompileTokenMetadata _token(
    DartObject token, [
    ElementAnnotation annotation,
  ]) {
    if (token == null) {
      // provide(someOpaqueToken, ...) where someOpaqueToken did not resolve.
      if (annotation == null) {
        logWarning('Could not resolve an OpaqueToken on a Provider!');
        return new CompileTokenMetadata(value: 'OpaqueToken__NOT_RESOLVED');
      } else {
        logWarning(''
            'Could not resolve a token from $annotation: '
            'Will fall back to using a reference to the identifier.');
        return _annotationToToken(annotation as ElementAnnotationImpl);
      }
    } else if (_isOpaqueToken(token)) {
      // We actually resolved this an OpaqueToken.
      return _canonicalOpaqueToken(token);
    } else if (token.toStringValue() != null) {
      return new CompileTokenMetadata(value: token.toStringValue());
    } else if (token.toBoolValue() != null) {
      return new CompileTokenMetadata(value: token.toBoolValue());
    } else if (token.toIntValue() != null) {
      return new CompileTokenMetadata(value: token.toIntValue());
    } else if (token.toDoubleValue() != null) {
      return new CompileTokenMetadata(value: token.toDoubleValue());
    } else if (token.toTypeValue() != null) {
      return _tokenForType(token.toTypeValue());
    } else if (token.type is InterfaceType) {
      // TODO(het): allow this to be any const invocation
      var invocation = (token as DartObjectImpl).getInvocation();
      if (invocation != null) {
        if (invocation.positionalArguments.isNotEmpty ||
            invocation.namedArguments.isNotEmpty) {
          logWarning('Cannot use const objects with arguments as a '
              'provider token: $annotation');
          return new CompileTokenMetadata(value: 'OpaqueToken__NOT_RESOLVED');
        }
      }
      return _tokenForType(token.type, isInstance: invocation != null);
    } else if (token.type.element is FunctionTypedElement) {
      return new CompileTokenMetadata(
          identifier: _identifierForFunction(token.type.element));
    }
    throw new ArgumentError('@Inject is not yet supported for $token.');
  }

  CompileTokenMetadata _canonicalOpaqueToken(DartObject object) {
    // Re-use code from angular_compiler :)
    const reader = const TokenReader();
    final token = reader.parseTokenObject(object) as OpaqueTokenElement;

    // Create an identifier referencing {Opaque|Multi}Token<T>.
    final typeArgument =
        token.typeUrl == null ? null : fromTypeLink(token.typeUrl, _library);
    final tokenId = new CompileIdentifierMetadata(
      name: token.classUrl.symbol,
      moduleUrl: linkToReference(token.classUrl, _library).url,
      genericTypes: typeArgument != null ? [typeArgument] : const [],
    );
    return new CompileTokenMetadata(
      value: token.identifier.isNotEmpty ? token.identifier : null,
      identifier: tokenId,
      identifierIsInstance: true,
    );
  }

  CompileTokenMetadata _tokenForType(DartType type, {bool isInstance: false}) {
    return new CompileTokenMetadata(
        identifier: _idFor(type), identifierIsInstance: isInstance);
  }

  CompileIdentifierMetadata _idFor(ParameterizedType type) =>
      new CompileIdentifierMetadata(
          name: getTypeName(type), moduleUrl: moduleUrl(type.element));

  o.Expression _useValueExpression(DartObject token) {
    if (token == null || token.isNull) {
      return o.NULL_EXPR;
    } else if (token.toStringValue() != null) {
      return new o.LiteralExpr(token.toStringValue(), o.STRING_TYPE);
    } else if (token.toBoolValue() != null) {
      return new o.LiteralExpr(token.toBoolValue(), o.BOOL_TYPE);
    } else if (token.toIntValue() != null) {
      return new o.LiteralExpr(token.toIntValue(), o.INT_TYPE);
    } else if (token.toDoubleValue() != null) {
      return new o.LiteralExpr(token.toDoubleValue(), o.DOUBLE_TYPE);
    } else if (token.toListValue() != null) {
      return new o.LiteralArrayExpr(
          token.toListValue().map(_useValueExpression).toList(),
          new o.ArrayType(null, [o.TypeModifier.Const]));
    } else if (token.toMapValue() != null) {
      return new o.LiteralMapExpr(_toMapEntities(token.toMapValue()),
          new o.MapType(null, [o.TypeModifier.Const]));
    } else if (token.toTypeValue() != null) {
      return o.importExpr(_idFor(token.toTypeValue()));
    } else if (_isEnum(token.type)) {
      return _expressionForEnum(token);
    } else if (_isProtobufEnum(token.type)) {
      return _expressionForProtobufEnum(token);
    } else if (token.type is InterfaceType) {
      return _expressionForType(token);
    } else if (token.type.element is FunctionTypedElement) {
      return o.importExpr(_identifierForFunction(token.type.element));
    } else {
      throw new ArgumentError(
          'Could not create useValue expression for $token');
    }
  }

  List<List> _toMapEntities(Map<DartObject, DartObject> tokens) {
    final entities = <List>[];
    for (DartObject key in tokens.keys) {
      entities
          .add([_useValueExpression(key), _useValueExpression(tokens[key])]);
    }
    return entities;
  }

  o.Expression _expressionForType(DartObject token) {
    final id = _idFor(token.type);
    final type = o.importExpr(id);

    final invocation = (token as DartObjectImpl).getInvocation();
    if (invocation == null) return type;

    var params =
        invocation.positionalArguments.map(_useValueExpression).toList();
    var namedParams = <o.NamedExpr>[];
    invocation.namedArguments.forEach((name, expr) {
      namedParams.add(new o.NamedExpr(name, _useValueExpression(expr)));
    });
    params.addAll(namedParams);
    var importType = o.importType(id, null, [o.TypeModifier.Const]);

    if (invocation.constructor.name.isNotEmpty) {
      if (invocation.constructor.name.startsWith('_')) {
        throw new _PrivateConstructorException(
            '${id.name}.${invocation.constructor.name}');
      }
      return new o.InstantiateExpr(
          type.prop(invocation.constructor.name), params, importType);
    }
    return type.instantiate(params, importType);
  }

  CompileIdentifierMetadata _identifierForFunction(
      FunctionTypedElement function) {
    String prefix;
    if (function.enclosingElement is ClassElement) {
      prefix = function.enclosingElement.name;
    }
    return new CompileIdentifierMetadata(
        name: function.name,
        moduleUrl: moduleUrl(function),
        prefix: prefix,
        emitPrefix: true);
  }

  CompileFactoryMetadata _factoryForFunction(
    FunctionTypedElement function, [
    List<DartObject> typesOrTokens,
  ]) {
    String prefix;
    if (function.enclosingElement is ClassElement) {
      prefix = function.enclosingElement.name;
    }
    return new CompileFactoryMetadata(
      name: function.name,
      moduleUrl: moduleUrl(function),
      prefix: prefix,
      emitPrefix: true,
      diDeps: typesOrTokens != null
          ? typesOrTokens.map(_factoryDiDep).toList()
          : _getCompileDiDependencyMetadata(function.parameters, function),
    );
  }

  // If deps: const [ ... ] is passed, we use that instead of the parameters.
  CompileDiDependencyMetadata _factoryDiDep(DartObject object) {
    // Simple case: A dependency is a dart `Type` or an Angular `OpaqueToken`.
    if (object.toTypeValue() != null || _isOpaqueToken(object)) {
      return new CompileDiDependencyMetadata(token: _token(object));
    }

    // Complex case: A dependency is a List, which means it might have metadata.
    if (object.toListValue() != null) {
      final metadata = object.toListValue();
      final token = _token(metadata.first);
      var isSelf = false;
      var isHost = false;
      var isSkipSelf = false;
      var isOptional = false;
      for (var i = 1; i < metadata.length; i++) {
        if (const TypeChecker.fromRuntime(Self)
            .isExactlyType(metadata[i].type)) {
          isSelf = true;
        } else if (const TypeChecker.fromRuntime(Host)
            .isExactlyType(metadata[i].type)) {
          isHost = true;
        } else if (const TypeChecker.fromRuntime(SkipSelf)
            .isExactlyType(metadata[i].type)) {
          isSkipSelf = true;
        } else if (const TypeChecker.fromRuntime(Optional)
            .isExactlyType(metadata[i].type)) {
          isOptional = true;
        }
      }
      return new CompileDiDependencyMetadata(
        token: token,
        isSelf: isSelf,
        isHost: isHost,
        isSkipSelf: isSkipSelf,
        isOptional: isOptional,
      );
    }

    // TODO: Make this more severe/an error.
    logWarning('Could not resolve dependency $object');
    return new CompileDiDependencyMetadata();
  }

  bool _isOpaqueToken(DartObject token) =>
      token != null && $OpaqueToken.isAssignableFromType(token.type);

  ElementAnnotation _getAnnotation(Element element, Type type) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  bool _hasAnnotation(Element element, Type type) => element.metadata.any(
      (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  o.Expression _expressionForEnum(DartObject token) {
    final field =
        _enumValues(token).singleWhere((field) => field.constantValue == token);
    return o.importExpr(_idFor(token.type)).prop(field.name);
  }

  Iterable<FieldElement> _enumValues(DartObject token) {
    final clazz = token.type.element as ClassElement;
    // Due to https://github.com/dart-lang/sdk/issues/29306, isEnumConstant is
    // not enough, so we also need to skip synthetic fields 'index' and 'value'.
    return clazz.fields
        .where((field) => field.isEnumConstant && !field.isSynthetic);
  }

  bool _isEnum(ParameterizedType type) =>
      type is InterfaceType && type.element.isEnum;

  bool _isPositional(ParameterElement param) =>
      param.parameterKind == ParameterKind.POSITIONAL;

  bool _isProtobufEnum(ParameterizedType type) {
    return type is InterfaceType &&
        const TypeChecker.fromUrl('package:protobuf/protobuf.dart#ProtobufEnum')
            .isExactlyType(type.superclass);
  }

  /// Creates an expression for protobuf enums.
  ///
  /// We can't just call the const constructor directly, because protobuf enums
  /// use a private constructor. Instead, we can look up the name, which is
  /// stored in a field, and use that to generate the code instead.
  o.Expression _expressionForProtobufEnum(DartObject token) {
    return o
        .importExpr(_idFor(token.type))
        .prop(dart_objects.coerceString(token, 'name'));
  }
}

class _PrivateConstructorException extends Error {
  final String constructorName;
  _PrivateConstructorException(this.constructorName);
}
