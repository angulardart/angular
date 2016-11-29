import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/core/di/decorators.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:angular2/src/source_gen/template_compiler/dart_object_utils.dart';
import 'package:build/build.dart';

class CompileTypeMetadataVisitor
    extends SimpleElementVisitor<CompileTypeMetadata> {
  final BuildStep _buildStep;

  CompileTypeMetadataVisitor(this._buildStep);

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
      element?.source?.uri?.toString() ?? toAssetUri(_buildStep.input.id);

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
          isOptional: _hasAnnotation(p, Optional),
          query: _getQuery(p),
          viewQuery: _getViewQuery(p));

  CompileTokenMetadata _getToken(ParameterElement p) =>
      _hasAnnotation(p, Attribute)
          ? _tokenForAttribute(p)
          : _hasAnnotation(p, Inject) ? _tokenForInject(p) : _tokenForType(p);

  CompileTokenMetadata _tokenForAttribute(ParameterElement p) =>
      new CompileTokenMetadata(
          value: coerceString(
              _getAnnotation(p, Attribute).constantValue, 'attributeName'));

  CompileTokenMetadata _tokenForInject(ParameterElement p) {
    throw new ArgumentError("@Inject is not yet supported.");
  }

  CompileTokenMetadata _tokenForType(ParameterElement p) =>
      new CompileTokenMetadata(
          identifier: new CompileIdentifierMetadata(name: p.type.name));

  CompileQueryMetadata _getQuery(ParameterElement p) => _hasAnnotation(p, Query)
      ? _createQueryMetadata(_getAnnotation(p, Query))
      : _hasAnnotation(p, ContentChildren)
          ? _createQueryMetadata(_getAnnotation(p, ContentChildren))
          : null; // TODO(alorenzen): handle ContentChild

  CompileQueryMetadata _getViewQuery(ParameterElement p) =>
      _hasAnnotation(p, ViewQuery)
          ? _createQueryMetadata(_getAnnotation(p, ViewQuery), first: true)
          : _hasAnnotation(p, ViewChildren)
              ? _createQueryMetadata(_getAnnotation(p, ViewChildren))
              : null;

  CompileQueryMetadata _createQueryMetadata(ElementAnnotation annotation,
      {bool first: false}) {
    return new CompileQueryMetadata(
        selectors: _getSelector(getField(annotation.constantValue, 'selector')),
        descendants: coerceBool(annotation.constantValue, 'descendants'),
        first: first,
        read: null,
        propertyName: null);
  }

  List<CompileTokenMetadata> _getSelector(DartObject obj) {
    if (obj.toStringValue() != null) {
      return obj
          .toStringValue()
          .split(',')
          .map((value) => new CompileTokenMetadata(value: value))
          .toList();
    }
    throw new ArgumentError("Types not yet supported.");
  }

  ElementAnnotation _getAnnotation(Element element, Type type) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(type, annotation));

  bool _hasAnnotation(Element element, Type type) => element.metadata.any(
      (annotation) => annotation_matcher.matchAnnotation(type, annotation));
}
