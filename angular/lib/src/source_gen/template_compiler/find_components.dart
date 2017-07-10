import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/metadata.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular/src/source_gen/common/annotation_matcher.dart'
    show safeMatcher, safeMatcherType, safeMatcherTypes;
import 'package:angular/src/source_gen/common/url_resolver.dart';

import 'compile_metadata.dart';
import 'dart_object_utils.dart';
import 'pipe_visitor.dart';

const String _directivesProperty = 'directives';

AngularArtifacts findComponentsAndDirectives(Element element) {
  var componentVisitor = new NormalizedComponentVisitor();
  element.accept(componentVisitor);
  return new AngularArtifacts(
      componentVisitor.components, componentVisitor.directives);
}

class NormalizedComponentVisitor extends RecursiveElementVisitor<Null> {
  final List<NormalizedComponentWithViewDirectives> components = [];
  final List<CompileDirectiveMetadata> directives = [];

  @override
  Null visitClassElement(ClassElement element) {
    final directive = extractDirectiveMetadata(element);
    if (directive != null) {
      if (directive.isComponent) {
        var pipes = _visitPipes(element);
        components.add(new NormalizedComponentWithViewDirectives(
            directive, _visitDirectives(element), pipes));
      } else {
        directives.add(directive);
      }
    }
    return null;
  }

  List<CompilePipeMetadata> _visitPipes(ClassElement element) => _visitTypes(
        element,
        'pipes',
        safeMatcher(annotation_matcher.isPipe, log),
        () => new PipeVisitor(log),
      );

  List<CompileDirectiveMetadata> _visitDirectives(ClassElement element) =>
      _visitTypes(
        element,
        _directivesProperty,
        safeMatcher(annotation_matcher.isDirective, log),
        () => new ComponentVisitor(),
      );

  List<T> _visitTypes<T>(
    ClassElement element,
    String field,
    annotation_matcher.AnnotationMatcher annotationMatcher,
    ElementVisitor<T> visitor(),
  ) {
    return element.metadata
        .where(safeMatcher(
          annotation_matcher.hasDirectives,
          log,
        ))
        .expand((annotation) => _visitTypeObjects(
              coerceList(annotation.computeConstantValue(), field),
              safeMatcher(annotationMatcher, log),
              visitor,
              // Only pass the annotation for directives: [ ... ], not other
              // elements. They also can cause problems if not resolved but it
              // is missing directives that blow up in a non-actionable way.
              annotation: field == _directivesProperty ? annotation : null,
              element: element,
            ))
        .toList();
  }

  void _failFastOnUnresolvedTypes(
    NodeList<Expression> expressions,
    ClassElement componentType,
  ) {
    // TODO: Throw an exception type that is specifically handled by the builder
    // and doesn't print a stack trace.
    throw new StateError(''
        'Failed to parse @Component annotation for ${componentType.name}:\n'
        'One or more of the following arguments were unresolvable: \n'
        '* ${expressions.join('\n* ')}'
        '\n'
        'The root cause could be a mispelling, or an import statement that \n'
        'looks valid but is not resolvable at build time. Bazel users should \n'
        'check their BUILD file to ensure all dependencies are listed.\n\n');
  }

  List<T> _visitTypeObjects<T>(
    Iterable<DartObject> directives,
    annotation_matcher.AnnotationMatcher annotationMatcher,
    ElementVisitor<T> visitor(), {
    ElementAnnotationImpl annotation,
    ClassElement element,
  }) {
    if (directives.isEmpty && annotation != null) {
      // Two reasons we got to this point:
      // 1. The directives: const [ ... ] list was empty or omitted.
      // 2. One or more identifiers in the list were not resolved, potentially
      //    due to missing imports or dependencies.
      //
      // The latter is specifically tricky to debug, because it ends up failing
      // template parsing in a similar way to #1, but a user will look at the
      // code and not see a problem potentially.
      for (final argument in annotation.annotationAst.arguments.arguments) {
        if (argument is NamedExpression &&
            argument.name.label.name == _directivesProperty) {
          final values = argument.expression as ListLiteral;
          if (values.elements.isNotEmpty &&
              // Avoid an edge case where all of your directives: ... entries
              // are just empty lists. Not likely to happen, but might as well
              // check anyway at this point.
              values.elements.every((e) => e.staticType?.isDynamic != false)) {
            // We didn't resolve something.
            _failFastOnUnresolvedTypes(values.elements, element);
          }
        }
      }
    }
    return visitAll<T>(directives, (obj) {
      var type = obj.toTypeValue();
      if (type != null &&
          type.element != null &&
          type.element.metadata.any(safeMatcher(
            annotationMatcher,
            log,
          ))) {
        return type.element.accept(visitor());
      }
    });
  }
}

class ComponentVisitor
    extends RecursiveElementVisitor<CompileDirectiveMetadata> {
  final _fieldInputs = <String, String>{};
  final _setterInputs = <String, String>{};
  final _inputTypes = <String, String>{};
  final _outputs = <String, String>{};
  final _hostListeners = <String, String>{};
  final _hostProperties = <String, String>{};
  final _queries = <CompileQueryMetadata>[];
  final _viewQueries = <CompileQueryMetadata>[];

  @override
  CompileDirectiveMetadata visitClassElement(ClassElement element) {
    super.visitClassElement(element);
    for (ElementAnnotation annotation in element.metadata) {
      if (safeMatcher(annotation_matcher.isDirective, log)(annotation)) {
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
      if (safeMatcherType(HostListener, log)(annotation)) {
        _addHostListener(annotation, element);
      }
    }
    return null;
  }

  void _visitClassMember(
    Element element, {
    bool isGetter: false,
    bool isSetter: false,
  }) {
    for (ElementAnnotation annotation in element.metadata) {
      if (safeMatcherType(Input, log)(annotation)) {
        if (isSetter) {
          String typeName;
          bool isField = false;
          if (element is FieldElement) {
            typeName = element.type?.name;
            isField = true;
          } else if (element is PropertyAccessorElement) {
            typeName = element.parameters.first.type?.name;
          }
          _addPropertyBindingTo(
              isField ? _fieldInputs : _setterInputs, annotation, element);
          if (typeName != null) {
            _inputTypes[element.displayName] = typeName;
          }
        } else {
          log.severe('@Input can only be used on a setter or non-final '
              'field, but was found on $element.');
        }
      } else if (safeMatcherType(Output, log)(annotation)) {
        if (isGetter) {
          _addPropertyBindingTo(_outputs, annotation, element);
        } else {
          log.severe('@Output can only be used on a getter or a field, but '
              'was found on $element.');
        }
      } else if (safeMatcherType(HostBinding, log)(annotation)) {
        if (isGetter) {
          _addHostBinding(annotation, element);
        } else {
          log.severe('@HostBinding can only be used on a getter or a field, '
              'but was found on $element.');
        }
      } else if (safeMatcherTypes(const [
        ContentChildren,
        ContentChild,
      ], log)(annotation)) {
        if (isSetter) {
          _queries.add(_getQuery(
            annotation.computeConstantValue(),
            // Avoid emitting the '=' part of the setter.
            element.displayName,
          ));
        } else {
          log.severe(''
              'ContentChild or ContentChildren annotation '
              'can only be used on a setter, but was found on $element.');
        }
      } else if (safeMatcherTypes(const [
        ViewChildren,
        ViewChild,
      ], log)(annotation)) {
        if (isSetter) {
          _viewQueries.add(_getQuery(
            annotation.computeConstantValue(),
            // Avoid emitting the '=' part of the setter.
            element.displayName,
          ));
        } else {
          log.severe(''
              'ViewChild or ViewChildren annotation '
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
    final readType = getField(value, 'read')?.toTypeValue();
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
    var property =
        coerceString(value, 'hostPropertyName', defaultTo: element.name);
    _hostProperties[property] = element.name;
  }

  void _addHostListener(ElementAnnotation annotation, Element element) {
    var value = annotation.computeConstantValue();
    var eventName = coerceString(value, 'eventName');
    var methodName = element.name;
    var methodArgs = coerceStringList(value, 'args');
    _hostListeners[eventName] = '$methodName(${methodArgs.join(', ')})';
  }

  void _addPropertyBindingTo(
    Map<String, String> bindings,
    ElementAnnotation annotation,
    Element element,
  ) {
    var value = annotation.computeConstantValue();
    var bindingName = coerceString(value, 'bindingPropertyName',
        defaultTo: element.displayName);
    bindings[element.displayName] = bindingName;
  }

  CompileDirectiveMetadata _createCompileDirectiveMetadata(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    var componentValue = annotation.computeConstantValue();
    var isComponent = safeMatcher(
      annotation_matcher.isComponent,
      log,
    )(annotation);
    // Some directives won't have templates but the template parser is going to
    // assume they have at least defaults.
    var template = isComponent
        ? _createTemplateMetadata(componentValue,
            view: _findView(element)?.computeConstantValue())
        : new CompileTemplateMetadata();

    final inputs = <String, String>{};
    CompileDirectiveMetadata.deserializeInputs(
        coerceStringList(componentValue, 'inputs'), inputs, _inputTypes);
    inputs..addAll(_fieldInputs)..addAll(_setterInputs);

    CompileDirectiveMetadata.deserializeOutputs(
        coerceStringList(componentValue, 'outputs'), _outputs);

    final hostAttributes = <String, String>{};
    final hostListeners = <String, String>{};
    final hostProperties = <String, String>{};
    CompileDirectiveMetadata.deserializeHost(
        coerceStringMap(componentValue, 'host'),
        hostAttributes,
        hostListeners,
        hostProperties);
    hostListeners..addAll(_hostListeners);
    hostProperties..addAll(_hostProperties);

    var queries = new List<CompileQueryMetadata>.from(_queries);
    coerceMap(componentValue, 'queries').forEach((propertyName, query) {
      queries.add(_getQuery(query, propertyName.toStringValue()));
    });
    final metadata = new CompileDirectiveMetadata(
      type: element.accept(new CompileTypeMetadataVisitor(log)),
      isComponent: isComponent,
      selector: coerceString(componentValue, 'selector'),
      exportAs: coerceString(componentValue, 'exportAs'),
      // Even for directives, we want change detection set to the default.
      changeDetection:
          _changeDetection(element, componentValue, 'changeDetection'),
      inputs: inputs,
      inputTypes: _inputTypes,
      outputs: _outputs,
      hostAttributes: hostAttributes,
      hostListeners: hostListeners,
      hostProperties: hostProperties,
      lifecycleHooks: extractLifecycleHooks(element),
      providers: _extractProviders(componentValue, 'providers'),
      viewProviders: _extractProviders(componentValue, 'viewProviders'),
      exports: _extractExports(annotation, element),
      queries: queries,
      viewQueries: _viewQueries,
      template: template,
      analyzedClass: new AnalyzedClass(element),
    );
    // For now only components support inheritance.
    if (metadata.isComponent) {
      // This is doing more work than necessary, as we only need to extract the
      // subset of ancestor directive metadata that is inherited. However, this
      // solution was simplest to implement, and trivial to extend if
      // inheritance of more metadata is required in the future.
      final supertypeElement = element.supertype.element;
      final supertypeMetadata = extractDirectiveMetadata(supertypeElement);
      _addInheritedDirectiveMetadata(metadata, supertypeMetadata);
    }
    return metadata;
  }

  ElementAnnotation _findView(ClassElement element) =>
      element.metadata.firstWhere(
        safeMatcherType(View, log),
        orElse: () => null,
      );

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

  int _changeDetection(
    ClassElement clazz,
    DartObject value,
    String field,
  ) {
    // TODO: Use angular2/src/meta instead of this error-prone check.
    if (clazz.allSupertypes.any((t) => t.name == 'ComponentState')) {
      // TODO: Warn/fail if changeDetection: ... is set to anything else.
      return ChangeDetectionStrategy.Stateful;
    }
    return coerceInt(value, field, defaultTo: ChangeDetectionStrategy.Default);
  }

  List<CompileProviderMetadata> _extractProviders(
          DartObject component, String providerField) =>
      visitAll(coerceList(component, providerField),
          new CompileTypeMetadataVisitor(log).createProviderMetadata);

  List<CompileIdentifierMetadata> _extractExports(
      ElementAnnotationImpl annotation, ClassElement element) {
    var exports = <CompileIdentifierMetadata>[];

    // There is an implicit "export" for the directive class itself
    exports.add(new CompileIdentifierMetadata(
        name: element.name, moduleUrl: moduleUrl(element.library)));

    var arguments = annotation.annotationAst.arguments.arguments;
    NamedExpression exportsArg = arguments.firstWhere(
        (arg) => arg is NamedExpression && arg.name.label.name == 'exports',
        orElse: () => null);
    if (exportsArg == null || exportsArg.expression is! ListLiteral) {
      return exports;
    }

    var staticNames = (exportsArg.expression as ListLiteral).elements;
    if (!staticNames.every((name) => name is Identifier)) {
      log.severe('Every item in the "exports" field must be an identifier');
      return exports;
    }

    for (Identifier id in staticNames) {
      String name;
      String prefix;
      if (id is PrefixedIdentifier) {
        // We only allow prefixed identifiers to have library prefixes.
        if (id.prefix.staticElement is! PrefixElement) {
          log.severe('Every item in the "exports" field must be either '
              'a simple identifier or an identifier with a library prefix');
          return exports;
        }
        name = id.identifier.name;
        prefix = id.prefix.name;
      } else {
        name = id.name;
      }
      exports.add(new CompileIdentifierMetadata(
        name: name,
        prefix: prefix,
        moduleUrl: moduleUrl(id.staticElement.library),
      ));
    }
    return exports;
  }
}

CompileDirectiveMetadata extractDirectiveMetadata(ClassElement element) =>
    element.accept(new ComponentVisitor());

List<LifecycleHooks> extractLifecycleHooks(ClassElement clazz) {
  const hooks = const <TypeChecker, LifecycleHooks>{
    const TypeChecker.fromRuntime(OnInit): LifecycleHooks.OnInit,
    const TypeChecker.fromRuntime(OnDestroy): LifecycleHooks.OnDestroy,
    const TypeChecker.fromRuntime(DoCheck): LifecycleHooks.DoCheck,
    const TypeChecker.fromRuntime(OnChanges): LifecycleHooks.OnChanges,
    const TypeChecker.fromRuntime(AfterContentInit):
        LifecycleHooks.AfterContentInit,
    const TypeChecker.fromRuntime(AfterContentChecked):
        LifecycleHooks.AfterContentChecked,
    const TypeChecker.fromRuntime(AfterViewInit): LifecycleHooks.AfterViewInit,
    const TypeChecker.fromRuntime(AfterViewChecked):
        LifecycleHooks.AfterViewChecked,
  };
  return hooks.keys
      .where((hook) => hook.isAssignableFrom(clazz))
      .map((t) => hooks[t])
      .toList();
}

/// Creates a new map from [oldMap] combined with [newMap].
///
/// If an entry from [newMap] will mutate an entry from [oldMap], [onMutation]
/// is invoked with the key, the original value, and the new value.
Map<A, B> _mergeImmutableValueMaps<A, B>(
  Map<A, B> oldMap,
  Map<A, B> newMap,
  void onMutation(A key, B value, B newValue),
) {
  final mergedMap = new Map.from(oldMap);
  newMap.forEach((key, value) {
    if (oldMap.containsKey(key) && value != oldMap[key]) {
      onMutation(key, oldMap[key], value);
    }
    mergedMap[key] = value;
  });
  return mergedMap;
}

/// Adds inheritable metadata from [inheritedMetadata] to [metadata].
void _addInheritedDirectiveMetadata(
  CompileDirectiveMetadata metadata,
  CompileDirectiveMetadata inheritedMetadata,
) {
  if (inheritedMetadata == null) return;
  if (!metadata.isComponent && inheritedMetadata.isComponent) {
    throw new UnsupportedError(
        "Inheritance of directive '${inheritedMetadata.type.name}' from "
        "component '${metadata.type.name}' is prohibited.");
  }
  if (inheritedMetadata.inputs.isNotEmpty) {
    metadata.inputs = _mergeImmutableValueMaps(
        inheritedMetadata.inputs,
        metadata.inputs,
        (name, binding, newBinding) => throw new UnsupportedError(
            "'${metadata.type.name}' violates interface of its ancestor "
            "'${inheritedMetadata.type.name}' by overriding the binding name "
            "of inherited input '$name' from '$binding' to '$newBinding'."));
  }
  if (inheritedMetadata.outputs.isNotEmpty) {
    metadata.outputs = _mergeImmutableValueMaps(
        inheritedMetadata.outputs,
        metadata.outputs,
        (name, binding, newBinding) => throw new UnsupportedError(
            "'${metadata.type.name}' violates interface of its ancestor "
            "'${inheritedMetadata.type.name}' by overriding the binding name "
            "of inherited output '$name' from '$binding' to '$newBinding'."));
  }
  if (inheritedMetadata.hostAttributes.isNotEmpty) {
    metadata.hostAttributes = new Map.from(inheritedMetadata.hostAttributes)
      ..addAll(metadata.hostAttributes);
  }
  if (inheritedMetadata.hostListeners.isNotEmpty) {
    metadata.hostListeners = new Map.from(inheritedMetadata.hostListeners)
      ..addAll(metadata.hostListeners);
  }
  if (inheritedMetadata.hostProperties.isNotEmpty) {
    metadata.hostProperties = new Map.from(inheritedMetadata.hostProperties)
      ..addAll(metadata.hostProperties);
  }
  if (inheritedMetadata.inputTypes.isNotEmpty) {
    metadata.inputTypes = new Map.from(inheritedMetadata.inputTypes)
      ..addAll(metadata.inputTypes);
  }
  if (inheritedMetadata.queries.isNotEmpty) {
    metadata.queries = new List.from(inheritedMetadata.queries)
      ..addAll(metadata.queries);
  }
  if (inheritedMetadata.viewQueries.isNotEmpty) {
    metadata.viewQueries = new List.from(inheritedMetadata.viewQueries)
      ..addAll(metadata.viewQueries);
  }
}
