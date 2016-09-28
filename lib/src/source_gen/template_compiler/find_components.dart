import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/core/change_detection/constants.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart';
import 'package:angular2/src/source_gen/template_compiler/async_element_visitor.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:angular2/src/source_gen/template_compiler/pipe_visitor.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';

import 'dart_object_utils.dart';

Future<List<NormalizedComponentWithViewDirectives>> findComponents(
    BuildStep buildStep, Element element) async {
  var componentVisitor = new NormalizedComponentVisitor(buildStep);
  element.accept(componentVisitor);
  List<NormalizedComponentWithViewDirectives> compileComponentsData =
  await componentVisitor.directives;
  return compileComponentsData;
}

class NormalizedComponentVisitor extends RecursiveElementVisitor<Object> {
  final List<Future<NormalizedComponentWithViewDirectives>> _directives = [];
  final AnnotationMatcher _annotationMatcher;
  final BuildStep _buildStep;

  NormalizedComponentVisitor(this._buildStep)
      : _annotationMatcher = new AnnotationMatcher();

  Future<List<NormalizedComponentWithViewDirectives>> get directives async {
    var directives = await Future.wait(_directives);
    return directives.where((directive) => directive != null).toList();
  }

  @override
  Object visitClassElement(ClassElement element) {
    _directives.add(visitClassElementAsync(element));
    return null;
  }

  Future<NormalizedComponentWithViewDirectives> visitClassElementAsync(
      ClassElement element) async {
    var componentVisitor = new AsyncElementVisitor(
        new ComponentVisitor(_buildStep, loadTemplate: true));
    element.accept(componentVisitor);
    var directive = await componentVisitor.value;
    if (directive == null) return null;
    var directives = await visitDirectives(element);
    var pipes = await visitPipes(element);
    return new NormalizedComponentWithViewDirectives(
        directive, directives, pipes);
  }

  Future<List<CompilePipeMetadata>> visitPipes(ClassElement element) async {
    for (ElementAnnotation annotation in element.metadata) {
      if (_isDirective(annotation)) {
        var value = annotation.computeConstantValue();
        var pipes = getList(value, 'pipes');
        return await visitPipeObjects(pipes);
      }
    }
    return [];
  }

  Future<List<CompilePipeMetadata>> visitPipeObjects(
      Iterable<DartObject> pipes) async =>
      visitListOfObjects(pipes, (Element element) async {
        for (ElementAnnotation annotation in element.metadata) {
          if (_annotationMatcher.isPipe(annotation)) {
            var visitor = new AsyncElementVisitor(new PipeVisitor(_buildStep));
            element.accept(visitor);
            return await visitor.value;
          }
        }
        return null;
      });

  Future<List<CompileDirectiveMetadata>> visitDirectives(
      ClassElement element) async {
    for (ElementAnnotation annotation in element.metadata) {
      if (_isDirective(annotation)) {
        var value = annotation.computeConstantValue();
        var directives = getList(value, 'directives');
        return await visitDirectiveObjects(directives);
      }
    }
    return [];
  }

  Future<List<CompileDirectiveMetadata>> visitDirectiveObjects(
      Iterable<DartObject> directives) async {
    return visitListOfObjects(directives, (Element element) async {
      for (ElementAnnotation annotation in element.metadata) {
        if (_isDirective(annotation)) {
          var visitor =
          new AsyncElementVisitor(new ComponentVisitor(_buildStep));
          element.accept(visitor);
          return await visitor.value;
        }
      }
      return null;
    });
  }

  bool _isDirective(ElementAnnotation annotation) =>
      _annotationMatcher.isComponent(annotation) ||
          _annotationMatcher.isDirective(annotation);
}

class ComponentVisitor
    extends AsyncRecursiveElementVisitor<CompileDirectiveMetadata> {
  final AnnotationMatcher _annotationMatcher;
  final BuildStep _buildStep;
  final _loadTemplate;

  List<String> _inputs = [];
  List<String> _outputs = [];
  ComponentVisitor(this._buildStep, {bool loadTemplate: false})
      : _annotationMatcher = new AnnotationMatcher(),
        _loadTemplate = loadTemplate;

  Logger get _logger => _buildStep.logger;

  @override
  Future<CompileDirectiveMetadata> visitClassElement(
      ClassElement element) async {
    super.visitClassElement(element);
    for (ElementAnnotation annotation in element.metadata) {
      if (_isDirective(annotation)) {
        return await _createCompileDirectiveMetadata(annotation, element);
      }
    }
    return null;
  }

  bool _isDirective(ElementAnnotation annotation) =>
      _annotationMatcher.isComponent(annotation) ||
          _annotationMatcher.isDirective(annotation);

  @override
  Future<CompileDirectiveMetadata> visitFieldElement(FieldElement element) {
    super.visitFieldElement(element);
    visitInputOutputElement(element,
        getter: element.getter != null, setter: element.setter != null);
    return null;
  }

  @override
  Future<CompileDirectiveMetadata> visitPropertyAccessorElement(
      PropertyAccessorElement element) {
    super.visitPropertyAccessorElement(element);
    visitInputOutputElement(element,
        getter: element.isGetter, setter: element.isSetter);
    return null;
  }

  void visitInputOutputElement(Element element,
      {bool getter: false, setter: false}) {
    for (ElementAnnotation annotation in element.metadata) {
      if (_annotationMatcher.matchAnnotation(Input, annotation)) {
        if (setter) {
          _addPropertyToType(_inputs, annotation, element);
        } else {
          _logger.severe('@Input can only be used on a setter or non-final '
              'field, but was found on $element.');
        }
      }
      if (_annotationMatcher.matchAnnotation(Output, annotation)) {
        if (getter) {
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
    var bindingName = getString(value, 'bindingPropertyName');
    types.add(bindingName != null
        ? '${element.displayName}: ${bindingName}'
        : element.displayName);
  }

  Future<CompileDirectiveMetadata> _createCompileDirectiveMetadata(
      ElementAnnotation annotation, Element element) async {
    var value = annotation.computeConstantValue();
    var isComponent = _annotationMatcher.isComponent(annotation);
    var template = (isComponent && _loadTemplate)
        ? (await _createTemplateMetadata(value))
        : null;
    var inputs = getStringList(value, '_inputs')..addAll(_inputs);
    var outputs = getStringList(value, '_outputs')..addAll(_outputs);
    return CompileDirectiveMetadata.create(
        type: getType(element, _buildStep.input.id),
        isComponent: isComponent,
        selector: getString(value, 'selector'),
        exportAs: getString(value, 'exportAs'),
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

  Future _createTemplateMetadata(DartObject value) async {
    return new CompileTemplateMetadata(
        encapsulation: _encapsulation(value),
        template: getString(value, 'template'),
        templateUrl: getString(value, 'templateUrl'));
  }

  ViewEncapsulation _encapsulation(DartObject value) => getEnumValue(value,
      'encapsulation', ViewEncapsulation.values, ViewEncapsulation.Emulated);

  ChangeDetectionStrategy _changeDetection(DartObject value) => getEnumValue(
      value,
      'changeDetection',
      ChangeDetectionStrategy.values,
      ChangeDetectionStrategy.Default);
}
