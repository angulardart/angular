import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/core/change_detection/constants.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:angular2/src/source_gen/template_compiler/pipe_visitor.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/src/annotation.dart';

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
  Map<String, String> _host = {};

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

  @override
  CompileDirectiveMetadata visitMethodElement(MethodElement element) {
    super.visitMethodElement(element);
    for (ElementAnnotation annotation in element.metadata) {
      if (annotation_matcher.matchAnnotation(HostListener, annotation)) {
        _addHostListener(annotation, element);
      }
    }
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
              'was found on $element.');
        }
      }
      if (annotation_matcher.matchAnnotation(HostBinding, annotation)) {
        if (isGetter) {
          _addHostBinding(annotation, element);
        } else {
          _logger
              .severe('@HostBinding can only be used on a getter or a field, '
                  'but was found on $element.');
        }
      }
    }
  }

  void _addHostBinding(ElementAnnotation annotation, Element element) {
    var value = annotation.computeConstantValue();
    _host[coerceString(value, 'hostPropertyName', defaultTo: element.name)] =
        element.name;
  }

  void _addHostListener(ElementAnnotation annotation, Element element) {
    var value = annotation.computeConstantValue();
    var eventName = coerceString(value, 'eventName');
    var methodName = element.name;
    var methodArgs = coerceStringList(value, 'args');
    _host['($eventName)'] = '$methodName(${methodArgs.join(', ')})';
  }

  void _addPropertyToType(
      List<String> types, ElementAnnotation annotation, Element element) {
    var value = annotation.computeConstantValue();
    var bindingName = coerceString(value, 'bindingPropertyName');
    types.add(bindingName != null
        ? '${element.displayName}: ${bindingName}'
        : element.displayName);
  }

  List<LifecycleHooks> _extractLifecycleHooks(ClassElement clazz) {
    const hooks = const <Type, LifecycleHooks>{
      OnInit: LifecycleHooks.OnInit,
      OnDestroy: LifecycleHooks.OnDestroy,
      DoCheck: LifecycleHooks.DoCheck,
      OnChanges: LifecycleHooks.OnChanges,
      AfterContentInit: LifecycleHooks.AfterContentInit,
      AfterContentChecked: LifecycleHooks.AfterContentChecked,
      AfterViewInit: LifecycleHooks.AfterViewInit,
      AfterViewChecked: LifecycleHooks.AfterViewChecked,
    };
    return hooks.keys
        .where((hook) => clazz.interfaces.any((t) => matchTypes(hook, t)))
        .map((t) => hooks[t])
        .toList();
  }

  CompileDirectiveMetadata _createCompileDirectiveMetadata(
      ElementAnnotation annotation, ClassElement element) {
    var value = annotation.computeConstantValue();
    var isComponent = annotation_matcher.isComponent(annotation);
    var template = (isComponent && _loadTemplate)
        ? _createTemplateMetadata(value,
            view: _findView(element)?.computeConstantValue())
        : null;
    var inputs = new List<String>.from(coerceStringList(value, 'inputs'))
      ..addAll(_inputs);
    var outputs = new List<String>.from(coerceStringList(value, 'outputs'))
      ..addAll(_outputs);
    var host = new Map<String, String>.from(coerceStringMap(value, 'host'))
      ..addAll(_host);
    return CompileDirectiveMetadata.create(
        type: element.accept(new CompileTypeMetadataVisitor()),
        isComponent: isComponent,
        selector: coerceString(value, 'selector'),
        exportAs: coerceString(value, 'exportAs'),
        changeDetection: isComponent ? _changeDetection(value) : null,
        inputs: inputs,
        outputs: outputs,
        host: host,
        lifecycleHooks: _extractLifecycleHooks(element),
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
            coerceBool(component, 'preserveWhitespace', defaultTo: true));
  }

  ViewEncapsulation _encapsulation(DartObject value) => coerceEnum(
        value,
        'encapsulation',
        ViewEncapsulation.values,
        defaultTo: ViewEncapsulation.Emulated,
      );

  ChangeDetectionStrategy _changeDetection(DartObject value) => coerceEnum(
        value,
        'changeDetection',
        ChangeDetectionStrategy.values,
        defaultTo: ChangeDetectionStrategy.Default,
      );
}
