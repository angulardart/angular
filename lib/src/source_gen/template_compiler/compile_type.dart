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
import 'package:angular2/src/source_gen/template_compiler/dart_object_utils.dart';
import 'package:source_gen/src/annotation.dart' as source_gen;

class CompileTypeMetadataVisitor
    extends SimpleElementVisitor<CompileTypeMetadata> {
  @override
  CompileTypeMetadata visitClassElement(ClassElement element) =>
      annotation_matcher.isInjectable(element)
          ? new CompileTypeMetadata(
              moduleUrl: _moduleUrl(element),
              name: element.name,
              diDeps: _getCompileDiDependencyMetadata(
                  element.unnamedConstructor?.parameters ?? []),
              runtime: null // Intentionally `null`, cannot be provided here.
              )
          : null;

  String _moduleUrl(ClassElement element) =>
      toAssetUri(fromUri(element?.source?.uri?.toString()));

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
          value: coerceString(
              _getAnnotation(p, Attribute).constantValue, 'attributeName'));

  CompileTokenMetadata _tokenForInject(ParameterElement p) =>
      _token(getField(_getAnnotation(p, Inject).constantValue, 'token'));

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
          value: 'OpaqueToken__${coerceString(token, '_desc')}');
    }
    throw new ArgumentError('@Inject is not yet supported for $token.');
  }

  CompileTokenMetadata _tokenForType(DartType type) {
    return new CompileTokenMetadata(
        identifier: new CompileIdentifierMetadata(name: type.name));
  }

  bool _isOpaqueToken(DartObject token) =>
      source_gen.matchTypes(OpaqueToken, token.type);

  ElementAnnotation _getAnnotation(Element element, Type type) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  bool _hasAnnotation(Element element, Type type) => element.metadata.any(
      (annotation) => annotation_matcher.matchAnnotation(type, annotation));
}
