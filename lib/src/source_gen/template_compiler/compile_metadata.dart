import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/core/di.dart';
import 'package:angular2/src/core/di/decorators.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:angular2/src/source_gen/template_compiler/dart_object_utils.dart'
    as dart_objects;
import 'package:logging/logging.dart';
import 'package:quiver/strings.dart' as strings;
import 'package:source_gen/src/annotation.dart' as source_gen;

class CompileTypeMetadataVisitor
    extends SimpleElementVisitor<CompileTypeMetadata> {
  final Logger _logger;

  CompileTypeMetadataVisitor(this._logger);

  @override
  CompileTypeMetadata visitClassElement(ClassElement element) =>
      annotation_matcher.isInjectable(element)
          ? _getCompileTypeMetadata(element)
          : null;

  /// Finds the unnamed constructor if it is present.
  ///
  /// Otherwise, use the first encountered.
  ConstructorElement unnamedConstructor(ClassElement element) {
    var constructors = element.constructors;
    if (constructors.isEmpty) {
      _logger.severe('Invalid @Injectable() annotation: '
          'No constructors found for class ${element.name}.');
      return null;
    }

    var constructor = constructors.firstWhere(
        (constructor) => strings.isEmpty(constructor.name),
        orElse: () => constructors.first);

    if (constructor.isPrivate) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Cannot use private constructor on class ${element.name}');
      return null;
    }
    if (element.isAbstract && !constructor.isFactory) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Found a constructor for abstract class ${element.name} but it is '
          'not a "factory", and cannot be invoked');
      return null;
    }
    if (element.constructors.length > 1 &&
        strings.isNotEmpty(constructor.name)) {
      _logger.warning(
          'Found ${element.constructors.length} constructors for class '
          '${element.name}; using constructor ${constructor.name}.');
    }
    return constructor;
  }

  CompileProviderMetadata createProviderMetadata(DartObject provider) {
    // If `provider` is a type literal, then treat it as a `useClass` provider
    // with the class literal itself as the token.
    if (provider.toTypeValue() != null) {
      var metadata = _getCompileTypeMetadata(provider.toTypeValue().element);
      return new CompileProviderMetadata(
          token: new CompileTokenMetadata(identifier: metadata),
          useClass: metadata);
    }
    return new CompileProviderMetadata(
        token: _token(dart_objects.getField(provider, 'token')),
        useClass: _getUseClass(provider),
        useExisting: _getUseExisting(provider),
        useFactory: _getUseFactory(provider),
        useValue: _getUseValue(provider));
  }

  CompileTypeMetadata _getUseClass(DartObject provider) {
    var maybeUseClass = provider.getField('useClass');
    if (!dart_objects.isNull(maybeUseClass)) {
      var type = maybeUseClass.toTypeValue();
      if (type is InterfaceType) {
        return _getCompileTypeMetadata(type.element);
      } else {
        _logger.severe(
            'Provider.useClass can only be used with a class, but found '
            '${type.element}');
      }
    }
    return null;
  }

  CompileTokenMetadata _getUseExisting(DartObject provider) {
    var maybeUseExisting = provider.getField('useExisting');
    if (!dart_objects.isNull(maybeUseExisting)) {
      return _token(maybeUseExisting);
    }
    return null;
  }

  CompileFactoryMetadata _getUseFactory(DartObject provider) {
    var maybeUseFactory = provider.getField('useFactory');
    if (!dart_objects.isNull(maybeUseFactory)) {
      if (maybeUseFactory.type.element is FunctionTypedElement) {
        return _factoryForFunction(maybeUseFactory.type.element);
      } else {
        _logger.severe('Provider.useFactory can only be used with a function, '
            'but found ${maybeUseFactory.type.element}');
      }
    }
    return null;
  }

  CompileTypeMetadata _getCompileTypeMetadata(ClassElement element) =>
      new CompileTypeMetadata(
          moduleUrl: moduleUrl(element),
          name: element.name,
          diDeps: _getCompileDiDependencyMetadata(
              unnamedConstructor(element)?.parameters ?? []),
          runtime: null // Intentionally `null`, cannot be provided here.
          );

  CompileTokenMetadata _getUseValue(DartObject provider) {
    var maybeUseValue = provider.getField('useValue');
    if (!dart_objects.isNull(maybeUseValue)) {
      if (maybeUseValue.toStringValue() == noValueProvided) return null;
      return _token(maybeUseValue);
    }
    return null;
  }

  List<CompileDiDependencyMetadata> _getCompileDiDependencyMetadata(
          List<ParameterElement> parameters) =>
      parameters.map(_createCompileDiDependencyMetadata).toList();

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
        isOptional: _hasAnnotation(p, Optional),
      );
    } on ArgumentError catch (_) {
      // Handle cases where something is annotated with @Injectable() but does
      // not have something annotated properly. It's likely this is either
      // dead code or is not actually used via DI. We can ignore for now.
      _logger.warning(''
          'Could not resolve token for $p on ${p.enclosingElement} in '
          '${p.library.identifier}');
      return new CompileDiDependencyMetadata();
    }
  }

  CompileTokenMetadata _getToken(ParameterElement p) =>
      _hasAnnotation(p, Attribute)
          ? _tokenForAttribute(p)
          : _hasAnnotation(p, Inject)
              ? _tokenForInject(p)
              : _tokenForType(p.type);

  CompileTokenMetadata _tokenForAttribute(ParameterElement p) =>
      new CompileTokenMetadata(
          value: dart_objects.coerceString(
              _getAnnotation(p, Attribute).constantValue, 'attributeName'));

  CompileTokenMetadata _tokenForInject(ParameterElement p) {
    final inject = _getAnnotation(p, Inject).computeConstantValue();
    final token = dart_objects.getField(inject, 'token');
    if (token == null) {
      // Workaround for OpaqueToken's that are not resolvable.
      _logger.warning(''
          'Could not resolve an @Inject() annotation for $p on '
          '"${p.enclosingElement}" in "${p.library.identifier}". Direct '
          'dependencies are likely missing on an imported library.');
      return new CompileTokenMetadata(
        value: 'OpaqueToken__UNRESOLVED',
      );
    }
    return _token(token);
  }

  CompileTokenMetadata _token(DartObject token) {
    if (token == null) {
      throw new ArgumentError.notNull('token');
    }
    if (token.toStringValue() != null) {
      return new CompileTokenMetadata(value: token.toStringValue());
    } else if (token.toBoolValue() != null) {
      return new CompileTokenMetadata(value: token.toBoolValue());
    } else if (token.toIntValue() != null) {
      return new CompileTokenMetadata(value: token.toIntValue());
    } else if (token.toDoubleValue() != null) {
      return new CompileTokenMetadata(value: token.toDoubleValue());
    } else if (token.toTypeValue() != null) {
      return _tokenForType(token.toTypeValue());
    } else if (_isOpaqueToken(token)) {
      return new CompileTokenMetadata(
        value: 'OpaqueToken__${dart_objects.coerceString(token, '_desc')}',
      );
    } else if (token.type is InterfaceType) {
      return _tokenForType(token.type);
    } else if (token.type.element is FunctionTypedElement) {
      return _tokenForFunction(token.type.element);
    }
    throw new ArgumentError('@Inject is not yet supported for $token.');
  }

  CompileTokenMetadata _tokenForType(DartType type) {
    return new CompileTokenMetadata(
        identifier: new CompileIdentifierMetadata(
            name: type.name, moduleUrl: moduleUrl(type.element)));
  }

  CompileTokenMetadata _tokenForFunction(FunctionTypedElement function) {
    String prefix;
    if (function.enclosingElement is ClassElement) {
      prefix = function.enclosingElement.name;
    }
    return new CompileTokenMetadata(
        identifier: new CompileIdentifierMetadata(
            name: function.name,
            moduleUrl: moduleUrl(function),
            prefix: prefix,
            emitPrefix: true));
  }

  CompileFactoryMetadata _factoryForFunction(FunctionTypedElement function) {
    String prefix;
    if (function.enclosingElement is ClassElement) {
      prefix = function.enclosingElement.name;
    }
    return new CompileFactoryMetadata(
        name: function.name,
        moduleUrl: moduleUrl(function),
        prefix: prefix,
        emitPrefix: true,
        diDeps: _getCompileDiDependencyMetadata(function.parameters));
  }

  bool _isOpaqueToken(DartObject token) =>
      source_gen.matchTypes(OpaqueToken, token.type);

  ElementAnnotation _getAnnotation(Element element, Type type) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  bool _hasAnnotation(Element element, Type type) => element.metadata.any(
      (annotation) => annotation_matcher.matchAnnotation(type, annotation));
}
