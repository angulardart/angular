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
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_metadata.dart';
import 'package:angular2/src/source_gen/template_compiler/dart_object_utils.dart';
import 'package:angular2/src/source_gen/template_compiler/pipe_visitor.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/src/annotation.dart';

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
    var componentVisitor = new ComponentVisitor(_buildStep);
    CompileDirectiveMetadata directive = element.accept(componentVisitor);
    if (directive == null || !directive.isComponent) return null;
    var directives = _visitDirectives(element);
    var pipes = _visitPipes(element);
    return new NormalizedComponentWithViewDirectives(
        directive, directives, pipes);
  }

  List<CompilePipeMetadata> _visitPipes(ClassElement element) => _visitTypes(
      element,
      'pipes',
      annotation_matcher.isPipe,
      () => new PipeVisitor(_buildStep.logger));

  List<CompileDirectiveMetadata> _visitDirectives(ClassElement element) =>
      _visitTypes(element, 'directives', annotation_matcher.isDirective,
          () => new ComponentVisitor(_buildStep));

  List<T> _visitTypes<T>(
          ClassElement element,
          String field,
          annotation_matcher.AnnotationMatcher annotationMatcher,
          ElementVisitor<T> visitor()) =>
      element.metadata
          .where(annotation_matcher.hasDirectives)
          .expand((annotation) => _visitTypeObjects(
              coerceList(annotation.computeConstantValue(), field),
              annotationMatcher,
              visitor))
          .toList();

  List<T> _visitTypeObjects<T>(
          Iterable<DartObject> directives,
          annotation_matcher.AnnotationMatcher annotationMatcher,
          ElementVisitor<T> visitor()) =>
      visitAll<T>(directives, (obj) {
        var type = obj.toTypeValue();
        if (type != null &&
            type.element != null &&
            type.element.metadata.any(annotationMatcher)) {
          return type.element.accept(visitor());
        }
      });
}

class ComponentVisitor
    extends RecursiveElementVisitor<CompileDirectiveMetadata> {
  final BuildStep _buildStep;

  List<String> _inputs = [];
  List<String> _outputs = [];
  Map<String, String> _host = {};
  List<CompileQueryMetadata> _queries = [];
  List<CompileQueryMetadata> _viewQueries = [];

  ComponentVisitor(this._buildStep);

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
    _visitClassMember(
      element,
      isGetter: element.getter != null,
      isSetter: element.setter != null,
    );
    return null;
  }

  @override
  CompileDirectiveMetadata visitPropertyAccessorElement(
    PropertyAccessorElement element,
  ) {
    super.visitPropertyAccessorElement(element);
    _visitClassMember(
      element,
      isGetter: element.isGetter,
      isSetter: element.isSetter,
    );
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

  void _visitClassMember(
    Element element, {
    bool isGetter: false,
    isSetter: false,
  }) {
    for (ElementAnnotation annotation in element.metadata) {
      if (annotation_matcher.matchAnnotation(Input, annotation)) {
        if (isSetter) {
          _addPropertyToType(_inputs, annotation, element);
        } else {
          _logger.severe('@Input can only be used on a setter or non-final '
              'field, but was found on $element.');
        }
      } else if (annotation_matcher.matchAnnotation(Output, annotation)) {
        if (isGetter) {
          _addPropertyToType(_outputs, annotation, element);
        } else {
          _logger.severe('@Output can only be used on a getter or a field, but '
              'was found on $element.');
        }
      } else if (annotation_matcher.matchAnnotation(HostBinding, annotation)) {
        if (isGetter) {
          _addHostBinding(annotation, element);
        } else {
          _logger
              .severe('@HostBinding can only be used on a getter or a field, '
                  'but was found on $element.');
        }
      } else if (annotation_matcher.matchTypes(
          const [Query, ContentChildren, ContentChild], annotation)) {
        if (isSetter) {
          _queries.add(_getQuery(
            annotation.computeConstantValue(),
            element.name,
          ));
        } else {
          _logger.severe(''
              'Any of the @Query/ViewQuery/Content/view annotations '
              'can only be used on a setter, but was found on $element.');
        }
      } else if (annotation_matcher
          .matchTypes(const [ViewQuery, ViewChildren, ViewChild], annotation)) {
        if (isSetter) {
          _viewQueries.add(_getQuery(
            annotation.computeConstantValue(),
            element.name,
          ));
        } else {
          _logger.severe(''
              'Any of the @Query/ViewQuery/Content/view annotations '
              'can only be used on a setter, but was found on $element.');
        }
      }
    }
  }

  List<CompileTokenMetadata> _getSelectors(DartObject value) {
    var selector = getField(value, 'selector');
    var selectorString = selector?.toStringValue();
    if (selectorString != null) {
      return selectorString
          .split(',')
          .map((s) => new CompileTokenMetadata(value: s))
          .toList();
    }
    var selectorType = selector.toTypeValue();
    return [
      new CompileTokenMetadata(
        identifier: new CompileIdentifierMetadata(
          name: selectorType.name,
          moduleUrl: moduleUrl(selectorType.element),
        ),
      ),
    ];
  }

  CompileQueryMetadata _getQuery(
    annotationOrObject,
    String propertyName,
  ) {
    DartObject value;
    if (annotationOrObject is ElementAnnotation) {
      value = annotationOrObject.computeConstantValue();
    } else {
      value = annotationOrObject;
    }
    final readType = value.getField('read')?.toTypeValue();
    return new CompileQueryMetadata(
      selectors: _getSelectors(value),
      descendants: coerceBool(value, 'descendants', defaultTo: false),
      first: coerceBool(value, 'first', defaultTo: false),
      propertyName: propertyName,
      read: readType != null
          ? new CompileTokenMetadata(
              identifier: new CompileIdentifierMetadata(
                name: readType.displayName,
                moduleUrl: moduleUrl(readType.element),
              ),
            )
          : null,
    );
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
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    var componentValue = annotation.computeConstantValue();
    var isComponent = annotation_matcher.isComponent(annotation);
    // Some directives won't have templates but the template parser is going to
    // assume they have at least defaults.
    var template = isComponent
        ? _createTemplateMetadata(componentValue,
            view: _findView(element)?.computeConstantValue())
        : new CompileTemplateMetadata();
    var inputs =
        new List<String>.from(coerceStringList(componentValue, 'inputs'))
          ..addAll(_inputs);
    var outputs =
        new List<String>.from(coerceStringList(componentValue, 'outputs'))
          ..addAll(_outputs);
    var host =
        new Map<String, String>.from(coerceStringMap(componentValue, 'host'))
          ..addAll(_host);
    var queries = new List<CompileQueryMetadata>.from(_queries);
    coerceMap(componentValue, 'queries').forEach((propertyName, query) {
      queries.add(_getQuery(query, propertyName.toStringValue()));
    });
    return CompileDirectiveMetadata.create(
      type: element.accept(new CompileTypeMetadataVisitor(_logger)),
      isComponent: isComponent,
      selector: coerceString(componentValue, 'selector'),
      exportAs: coerceString(componentValue, 'exportAs'),
      // Even for directives, we want change detection set to the default.
      changeDetection: _changeDetection(element, componentValue),
      inputs: inputs,
      outputs: outputs,
      host: host,
      lifecycleHooks: _extractLifecycleHooks(element),
      providers: _extractProviders(componentValue, 'providers'),
      viewProviders: _extractProviders(componentValue, 'viewProviders'),
      queries: queries,
      viewQueries: _viewQueries,
      template: template,
    );
  }

  ElementAnnotation _findView(ClassElement element) =>
      element.metadata.firstWhere(
          (annotation) => annotation_matcher.matchAnnotation(View, annotation),
          orElse: () => null);

  CompileTemplateMetadata _createTemplateMetadata(
    DartObject component, {
    DartObject view,
  }) {
    var template = view ?? component;
    return new CompileTemplateMetadata(
      encapsulation: _encapsulation(template),
      template: coerceString(template, 'template'),
      templateUrl: coerceString(template, 'templateUrl'),
      styles: coerceStringList(template, 'styles'),
      styleUrls: coerceStringList(template, 'styleUrls'),
      preserveWhitespace: coerceBool(
        component,
        'preserveWhitespace',
        defaultTo: true,
      ),
    );
  }

  ViewEncapsulation _encapsulation(DartObject value) => coerceEnum(
        value,
        'encapsulation',
        ViewEncapsulation.values,
        defaultTo: ViewEncapsulation.Emulated,
      );

  ChangeDetectionStrategy _changeDetection(
    ClassElement clazz,
    DartObject value,
  ) {
    // TODO: Use angular2/src/meta instead of this error-prone check.
    if (clazz.allSupertypes.any((t) => t.name == 'ComponentState')) {
      // TODO: Warn/fail if changeDetection: ... is set to anything else.
      return ChangeDetectionStrategy.Stateful;
    }
    return coerceEnum(
      value,
      'changeDetection',
      ChangeDetectionStrategy.values,
      defaultTo: ChangeDetectionStrategy.Default,
    );
  }

  List<CompileProviderMetadata> _extractProviders(
          DartObject component, String providerField) =>
      visitAll(coerceList(component, providerField),
          new CompileTypeMetadataVisitor(_logger).createProviderMetadata);
}
