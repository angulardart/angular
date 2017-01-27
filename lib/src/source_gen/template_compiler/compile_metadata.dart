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

  CompileProviderMetadata createProviderMetadata(DartObject provider) {
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
      var type = maybeUseFactory.type;
      String prefix;
      if (type.element.enclosingElement is ClassElement) {
        prefix = type.element.enclosingElement.name;
      }
      if (type.element is FunctionTypedElement) {
        return new CompileFactoryMetadata(
            name: type.element.name,
            moduleUrl: moduleUrl(type.element),
            prefix: prefix,
            diDeps: _getCompileDiDependencyMetadata(
                (type.element as FunctionTypedElement).parameters));
      } else {
        _logger.severe('Provider.useFactory can only be used with a function, '
            'but found ${type.element}');
      }
    }
    return null;
  }

  CompileTypeMetadata _getCompileTypeMetadata(ClassElement element) =>
      new CompileTypeMetadata(
          moduleUrl: moduleUrl(element),
          name: element.name,
          diDeps: _getCompileDiDependencyMetadata(
              element.unnamedConstructor?.parameters ?? []),
          runtime: null // Intentionally `null`, cannot be provided here.
          );

  CompileTokenMetadata _getUseValue(DartObject provider) {
    var maybeUseValue = provider.getField('useValue');
    if (!dart_objects.isNull(maybeUseValue)) {
      if (maybeUseValue.toStringValue() == noValueProvided) return null;
      // TODO: Andrew to see how this is possible to do.
      // return _token(maybeUseValue);
      return null;
    }
    return null;
  }

  List<CompileDiDependencyMetadata> _getCompileDiDependencyMetadata(
          List<ParameterElement> parameters) =>
      parameters.map(_createCompileDiDependencyMetadata).toList();

  CompileDiDependencyMetadata _createCompileDiDependencyMetadata(
          ParameterElement p) =>
      new CompileDiDependencyMetadata(
          token: _getToken(p),
          isAttribute: _hasAnnotation(p, Attribute),
          isSelf: _hasAnnotation(p, Self),
          isHost: _hasAnnotation(p, Host),
          isSkipSelf: _hasAnnotation(p, SkipSelf),
          isOptional: _hasAnnotation(p, Optional));

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

  CompileTokenMetadata _tokenForInject(ParameterElement p) => _token(
      dart_objects.getField(_getAnnotation(p, Inject).constantValue, 'token'));

  CompileTokenMetadata _token(DartObject token) {
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
          value: 'OpaqueToken__${dart_objects.coerceString(token, '_desc')}');
    } else if (token.type is InterfaceType) {
      return _tokenForType(token.type);
    }
    throw new ArgumentError('@Inject is not yet supported for $token.');
  }

  CompileTokenMetadata _tokenForType(DartType type) {
    return new CompileTokenMetadata(
        identifier: new CompileIdentifierMetadata(
            name: type.name, moduleUrl: moduleUrl(type.element)));
  }

  bool _isOpaqueToken(DartObject token) =>
      source_gen.matchTypes(OpaqueToken, token.type);

  ElementAnnotation _getAnnotation(Element element, Type type) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  bool _hasAnnotation(Element element, Type type) => element.metadata.any(
      (annotation) => annotation_matcher.matchAnnotation(type, annotation));
}
