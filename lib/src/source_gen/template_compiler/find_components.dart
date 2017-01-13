import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/core/change_detection/constants.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:angular2/src/source_gen/template_compiler/pipe_visitor.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'dart_object_utils.dart';

List<NormalizedComponentWithViewDirectives> findComponents(
    BuildStep buildStep, Element element) {
  var componentVisitor = new NormalizedComponentVisitor(buildStep);
  element.accept(componentVisitor);
  return componentVisitor.directives;
}

class NormalizedComponentVisitor extends RecursiveElementVisitor<Null> {
  final List<NormalizedComponentWithViewDirectives> _directives = [];
  final BuildStep _buildStep;

  NormalizedComponentVisitor(this._buildStep);

  List<NormalizedComponentWithViewDirectives> get directives {
    return _directives.where((directive) => directive != null).toList();
  }

  @override
  Null visitClassElement(ClassElement element) {
    _directives.add(_visitClassElement(element));
    return null;
  }

  NormalizedComponentWithViewDirectives _visitClassElement(
      ClassElement element) {
    var componentVisitor = new ComponentVisitor(_buildStep, loadTemplate: true);
    CompileDirectiveMetadata directive = element.accept(componentVisitor);
    if (directive == null || !directive.isComponent) return null;
    var directives = _visitDirectives(element);
    var pipes = _visitPipes(element);
    return new NormalizedComponentWithViewDirectives(
        directive, directives, pipes);
  }

  List<CompilePipeMetadata> _visitPipes(ClassElement element) => _visitTypes(
      element, 'pipes', annotation_matcher.isPipe, new PipeVisitor());

  List<CompileDirectiveMetadata> _visitDirectives(ClassElement element) =>
      _visitTypes(element, 'directives', annotation_matcher.isDirective,
          new ComponentVisitor(_buildStep));

  List<dynamic/*=T*/ > _visitTypes/*<T>*/(
          ClassElement element,
          String field,
          annotation_matcher.AnnotationMatcher annotationMatcher,
          ElementVisitor<dynamic/*=T*/ > visitor) =>
      element.metadata
          .where(annotation_matcher.hasDirectives)
          .expand((annotation) => _visitTypeObjects(
              coerceList(annotation.computeConstantValue(), field),
              annotationMatcher,
              visitor))
          .toList();

  List<dynamic/*=T*/ > _visitTypeObjects/*<T>*/(
          Iterable<DartObject> directives,
          annotation_matcher.AnnotationMatcher annotationMatcher,
          ElementVisitor<dynamic/*=T*/ > visitor) =>
      visitAll/*<T>*/(
          directives,
          (Element element) => element.metadata.any(annotationMatcher)
              ? element.accept(visitor)
              : null);
}

class ComponentVisitor
    extends RecursiveElementVisitor<CompileDirectiveMetadata> {
  final BuildStep _buildStep;
  final bool _loadTemplate;

  List<String> _inputs = [];
  List<String> _outputs = [];

  ComponentVisitor(this._buildStep, {bool loadTemplate: false})
      : _loadTemplate = loadTemplate;

  Logger get _logger => _buildStep.logger;

  @override
  CompileDirectiveMetadata visitClassElement(ClassElement element) {
    super.visitClassElement(element);
    for (ElementAnnotation annotation in element.metadata) {
      if (annotation_matcher.isDirective(annotation)) {
        return _createCompileDirectiveMetadata(annotation, element);
      }
    }
    return null;
  }

  @override
  CompileDirectiveMetadata visitFieldElement(FieldElement element) {
    super.visitFieldElement(element);
    _visitInputOutputElement(element,
        isGetter: element.getter != null, isSetter: element.setter != null);
    return null;
  }

  @override
  CompileDirectiveMetadata visitPropertyAccessorElement(
      PropertyAccessorElement element) {
    super.visitPropertyAccessorElement(element);
    _visitInputOutputElement(element,
        isGetter: element.isGetter, isSetter: element.isSetter);
    return null;
  }

  void _visitInputOutputElement(Element element,
      {bool isGetter: false, isSetter: false}) {
    for (ElementAnnotation annotation in element.metadata) {
      if (annotation_matcher.matchAnnotation(Input, annotation)) {
        if (isSetter) {
          _addPropertyToType(_inputs, annotation, element);
        } else {
          _logger.severe('@Input can only be used on a setter or non-final '
              'field, but was found on $element.');
        }
      }
      if (annotation_matcher.matchAnnotation(Output, annotation)) {
        if (isGetter) {
          _addPropertyToType(_outputs, annotation, element);
        } else {
          _logger.severe('@Output can only be used on a getter or a field, but '
              'was foundon $element.');
        }
      }
    }
  }

  void _addPropertyToType(
      List<String> types, ElementAnnotation annotation, Element element) {
    var value = annotation.computeConstantValue();
    var bindingName = coerceString(value, 'bindingPropertyName');
    types.add(bindingName != null
        ? '${element.displayName}: ${bindingName}'
        : element.displayName);
  }

  CompileDirectiveMetadata _createCompileDirectiveMetadata(
      ElementAnnotation annotation, ClassElement element) {
    var value = annotation.computeConstantValue();
    var isComponent = annotation_matcher.isComponent(annotation);
    var template = (isComponent && _loadTemplate)
        ? _createTemplateMetadata(value,
            view: _findView(element)?.computeConstantValue())
        : null;
    var inputs = coerceStringList(value, 'inputs')..addAll(_inputs);
    var outputs = coerceStringList(value, 'outputs')..addAll(_outputs);
    return CompileDirectiveMetadata.create(
        type: element.accept(new CompileTypeMetadataVisitor()),
        isComponent: isComponent,
        selector: coerceString(value, 'selector'),
        exportAs: coerceString(value, 'exportAs'),
        changeDetection: isComponent ? _changeDetection(value) : null,
        inputs: inputs,
        outputs: outputs,
        host: {},
        lifecycleHooks: isComponent ? [] : null,
        providers: [],
        viewProviders: isComponent ? [] : null,
        queries: [],
        viewQueries: isComponent ? [] : null,
        template: template);
  }

  ElementAnnotation _findView(ClassElement element) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(View, annotation),
          orElse: () => null);

  CompileTemplateMetadata _createTemplateMetadata(DartObject component,
      {DartObject view}) {
    var template = view ?? component;
    return new CompileTemplateMetadata(
        encapsulation: _encapsulation(template),
        template: coerceString(template, 'template'),
        templateUrl: coerceString(template, 'templateUrl'),
        styles: coerceStringList(template, 'styles'),
        styleUrls: coerceStringList(template, 'styleUrls'),
        preserveWhitespace:
            coerceBool(component, 'preserveWhitespace', defaultValue: true));
  }

  ViewEncapsulation _encapsulation(DartObject value) => coerceEnumValue(value,
      'encapsulation', ViewEncapsulation.values, ViewEncapsulation.Emulated);

  ChangeDetectionStrategy _changeDetection(DartObject value) => coerceEnumValue(
      value,
      'changeDetection',
      ChangeDetectionStrategy.values,
      ChangeDetectionStrategy.Default);
}
