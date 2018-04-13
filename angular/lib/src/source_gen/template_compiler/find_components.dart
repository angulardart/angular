import 'package:analyzer/analyzer.dart' hide Directive;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular_compiler/cli.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/output/convert.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/metadata.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:source_span/source_span.dart';

import '../../compiler/view_compiler/property_binder.dart'
    show isPrimitiveTypeName;
import 'compile_metadata.dart';
import 'dart_object_utils.dart';
import 'pipe_visitor.dart';

const String _directivesProperty = 'directives';
const String _visibilityProperty = 'visibility';
const _statefulDirectiveFields = const [
  'exportAs',
  'host',
];

AngularArtifacts findComponentsAndDirectives(LibraryReader library) {
  var componentVisitor = new NormalizedComponentVisitor(library);
  library.element.accept(componentVisitor);
  return new AngularArtifacts(
    componentVisitor.components,
    componentVisitor.directives,
  );
}

class NormalizedComponentVisitor extends RecursiveElementVisitor<Null> {
  final List<NormalizedComponentWithViewDirectives> components = [];
  final List<CompileDirectiveMetadata> directives = [];
  final LibraryReader _library;

  NormalizedComponentVisitor(this._library);

  @override
  Null visitClassElement(ClassElement element) {
    final directive = element.accept(new ComponentVisitor(_library));
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

  @override
  Null visitFunctionElement(FunctionElement element) {
    final directive = element.accept(new ComponentVisitor(_library));
    if (directive != null) {
      directives.add(directive);
    }
    return null;
  }

  List<CompilePipeMetadata> _visitPipes(ClassElement element) => _visitTypes(
        element,
        'pipes',
        safeMatcher(isPipe),
        () => new PipeVisitor(_library),
      );

  List<CompileDirectiveMetadata> _visitDirectives(ClassElement element) =>
      _visitTypes(
        element,
        _directivesProperty,
        safeMatcher(isDirective),
        () => new ComponentVisitor(_library),
      );

  List<T> _visitTypes<T>(
    ClassElement element,
    String field,
    AnnotationMatcher annotationMatcher,
    ElementVisitor<T> visitor(),
  ) {
    return element.metadata
        .where(safeMatcher(hasDirectives))
        .expand((annotation) => _visitTypesForComponent(
              coerceList(annotation.computeConstantValue(), field),
              safeMatcher(annotationMatcher),
              visitor,
              // Only pass the annotation for directives: [ ... ], not other
              // elements. They also can cause problems if not resolved but it
              // is missing directives that blow up in a non-actionable way.
              annotation: field == _directivesProperty
                  ? annotation as ElementAnnotationImpl
                  : null,
              element: element,
            ))
        .toList();
  }

  void _failFastOnUnresolvedDirectives(
    Iterable<Expression> expressions,
    ClassElement componentType,
  ) {
    final sourceUrl = componentType.source.uri;
    throw new BuildError(
      messages.unresolvedSource(
        expressions.map((e) {
          return new SourceSpan(
            new SourceLocation(e.offset, sourceUrl: sourceUrl),
            new SourceLocation(e.offset + e.length, sourceUrl: sourceUrl),
            e.toSource(),
          );
        }),
        message: 'This argument *may* have not been resolved',
        reason: ''
            'Compiling @Component-annotated class "${componentType.name}" '
            'failed.\n\n${messages.analysisFailureReasons}',
      ),
    );
  }

  List<T> _visitTypesForComponent<T>(
    Iterable<DartObject> directives,
    AnnotationMatcher annotationMatcher,
    ElementVisitor<T> visitor(), {
    ElementAnnotationImpl annotation,
    ClassElement element,
  }) {
    // TODO(matanl): Extract this code somewhere common, likely useful.
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
            _failFastOnUnresolvedDirectives(
                values.elements.where((e) => e.staticType?.isDynamic != false),
                element);
          }
        }
      }
    }
    return visitAll<T>(directives, (obj) {
      // For functions, `toTypeValue()` is null so we fall back on `type`.
      final type = obj.toTypeValue() ?? obj.type;
      return type?.element?.accept(visitor());
    });
  }
}

class ComponentVisitor
    extends RecursiveElementVisitor<CompileDirectiveMetadata> {
  final _fieldInputs = <String, String>{};
  final _setterInputs = <String, String>{};
  final _inputs = <String, String>{};
  final _inputTypes = <String, CompileTypeMetadata>{};
  final _outputs = <String, String>{};
  final _hostAttributes = <String, String>{};
  final _hostListeners = <String, String>{};
  final _hostProperties = <String, String>{};
  final _queries = <CompileQueryMetadata>[];
  final _viewQueries = <CompileQueryMetadata>[];

  final LibraryReader _library;

  /// Whether the component being visited re-implements 'noSuchMethod'.
  bool _implementsNoSuchMethod = false;

  /// Element of the current directive being visited.
  ///
  /// This is used to look up resolved type information.
  ClassElement _directiveClassElement;

  ComponentVisitor(this._library);

  @override
  CompileDirectiveMetadata visitClassElement(ClassElement element) {
    final annotation = element.metadata.firstWhere(
      safeMatcher(isDirective),
      orElse: () => null,
    );
    if (annotation == null) return null;
    if (element.isPrivate) {
      log.severe('Components and directives must be public: $element');
      return null;
    }
    return _createCompileDirectiveMetadata(annotation, element);
  }

  @override
  CompileDirectiveMetadata visitFunctionElement(FunctionElement element) {
    final annotation = element.metadata.firstWhere(
      safeMatcherType(Directive),
      orElse: () => null,
    );
    if (annotation == null) return null;
    var invalid = false;
    if (element.isPrivate) {
      log.severe('Functional directives must be public: $element');
      invalid = true;
    }
    if (!element.returnType.isVoid) {
      log.severe('Functional directives must return void: $element');
      invalid = true;
    }
    final annotationValue = annotation.computeConstantValue();
    for (var field in _statefulDirectiveFields) {
      if (!annotationValue.getField(field).isNull) {
        log.severe("Functional directives don't support '$field': $element");
        invalid = true;
      }
    }
    final visibility = coerceEnum(
      annotationValue,
      _visibilityProperty,
      Visibility.values,
    );
    if (visibility != Visibility.local) {
      log.severe('Functional directives must be visibility: Visibility.local');
      invalid = true;
    }
    if (invalid) return null;
    final type = element.accept(new CompileTypeMetadataVisitor(_library));
    final selector = coerceString(annotationValue, 'selector');
    return new CompileDirectiveMetadata(
      type: type,
      metadataType: CompileDirectiveMetadataType.FunctionalDirective,
      selector: selector,
      inputs: const {},
      inputTypes: const {},
      outputs: const {},
      hostListeners: const {},
      hostProperties: const {},
      hostAttributes: const {},
      providers: _extractProviders(annotationValue, 'providers'),
    );
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
      if (safeMatcherType(HostListener)(annotation)) {
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
      if (safeMatcherType(Input)(annotation)) {
        if (isSetter && element.isPublic) {
          final isField = element is FieldElement;
          // Resolves specified generic type parameters.
          final setter = _directiveClassElement.type
              .lookUpInheritedSetter(element.displayName);
          final propertyType = setter.parameters.first.type;
          final dynamicType = setter.context.typeProvider.dynamicType;
          // Resolves unspecified or bounded generic type parameters.
          final resolvedType = propertyType.resolveToBound(dynamicType);
          final typeName = getTypeName(resolvedType);
          _addPropertyBindingTo(
              isField ? _fieldInputs : _setterInputs, annotation, element,
              immutableBindings: _inputs);
          if (typeName != null) {
            if (isPrimitiveTypeName(typeName)) {
              _inputTypes[element.displayName] =
                  new CompileTypeMetadata(name: typeName);
            } else {
              // Convert any generic type parameters from the input's type to
              // our internal output AST.
              final List<o.OutputType> typeArguments =
                  resolvedType is ParameterizedType
                      ? resolvedType.typeArguments.map(fromDartType).toList()
                      : const [];
              _inputTypes[element.displayName] = new CompileTypeMetadata(
                  moduleUrl: moduleUrl(element),
                  name: typeName,
                  genericTypes: typeArguments);
            }
          }
        } else {
          log.severe('@Input can only be used on a public setter or non-final '
              'field, but was found on $element.');
        }
      } else if (safeMatcherType(Output)(annotation)) {
        if (isGetter && element.isPublic) {
          _addPropertyBindingTo(_outputs, annotation, element);
        } else {
          log.severe('@Output can only be used on a public getter or field, '
              'but was found on $element.');
        }
      } else if (safeMatcherType(HostBinding)(annotation)) {
        if (isGetter && element.isPublic) {
          _addHostBinding(annotation, element);
        } else {
          log.severe('@HostBinding can only be used on a public getter or '
              'field, but was found on $element.');
        }
      } else if (safeMatcherTypes(const [
        ContentChildren,
        ContentChild,
      ])(annotation)) {
        if (isSetter && element.isPublic) {
          _queries.add(_getQuery(
            annotation,
            // Avoid emitting the '=' part of the setter.
            element.displayName,
            _fieldOrPropertyType(element),
          ));
        } else {
          log.severe('@ContentChild or @ContentChildren can only be used on a '
              'public setter or non-final field, but was found on $element.');
        }
      } else if (safeMatcherTypes(const [
        ViewChildren,
        ViewChild,
      ])(annotation)) {
        if (isSetter && element.isPublic) {
          _viewQueries.add(_getQuery(
            annotation,
            // Avoid emitting the '=' part of the setter.
            element.displayName,
            _fieldOrPropertyType(element),
          ));
        } else {
          log.severe('@ViewChild or @ViewChildren can only be used on a public '
              'setter or non-final field, but was found on $element.');
        }
      }
    }
  }

  DartType _fieldOrPropertyType(Element element) {
    if (element is PropertyAccessorElement && element.isSetter) {
      return element.parameters.first.type;
    }
    if (element is FieldElement) {
      return element.type;
    }
    return null;
  }

  List<CompileTokenMetadata> _getSelectors(
    ElementAnnotation annotation,
    DartObject value,
  ) {
    var selector = getField(value, 'selector');
    if (isNull(selector)) {
      BuildError.throwForAnnotation(
        annotation,
        'Missing selector argument for "@${value.type.name}"',
      );
    }
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

  static final _coreIterable = new TypeChecker.fromUrl('dart:core#Iterable');
  static final _htmlElement = new TypeChecker.fromUrl('dart:html#Element');

  CompileQueryMetadata _getQuery(
    ElementAnnotation annotation,
    String propertyName,
    DartType propertyType,
  ) {
    final value = annotation.computeConstantValue();
    final readType = getField(value, 'read')?.toTypeValue();
    return new CompileQueryMetadata(
      selectors: _getSelectors(annotation, value),
      descendants: coerceBool(value, 'descendants', defaultTo: false),
      first: coerceBool(value, 'first', defaultTo: false),
      propertyName: propertyName,
      isElementType: propertyType?.element != null &&
              _htmlElement.isAssignableFromType(propertyType) ||
          // A bit imprecise, but this will cover 'Iterable' and 'List'.
          _coreIterable.isAssignableFromType(propertyType) &&
              propertyType is ParameterizedType &&
              _htmlElement
                  .isAssignableFromType(propertyType.typeArguments.first),
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
    final value = annotation.computeConstantValue();
    final property = coerceString(
      value,
      'hostPropertyName',
      defaultTo: element.name,
    );
    // Allows using static members for @HostBinding. For example:
    //
    // class Foo {
    //   @HostBinding('title')
    //   static const title = 'Hello';
    // }
    var bindTo = element.name;
    if (element is PropertyAccessorElement && element.isStatic ||
        element is FieldElement && element.isStatic) {
      bindTo = '${_directiveClassElement.name}.$bindTo';
    }
    _hostProperties[property] = bindTo;
  }

  void _addHostListener(ElementAnnotation annotation, MethodElement element) {
    var value = annotation.computeConstantValue();
    var eventName = coerceString(value, 'eventName');
    var methodName = element.name;
    var methodArgs = coerceStringList(value, 'args');
    if (methodArgs.isEmpty && element.parameters.length == 1) {
      // Infer $event.
      methodArgs = const [r'$event'];
    }
    _hostListeners[eventName] = '$methodName(${methodArgs.join(', ')})';
  }

  /// Adds a property binding for [element] to [bindings].
  ///
  /// The property binding maps [element]'s display name to a binding name. By
  /// default, [element]'s name is used as the binding name. However, if
  /// [annotation] has a `bindingPropertyName` field, its value is used instead.
  ///
  /// Property bindings are immutable by default, to prevent derived classes
  /// from overriding inherited binding names. The optional [immutableBindings]
  /// may be provided to restrict a different set of property bindings than
  /// [bindings].
  void _addPropertyBindingTo(
    Map<String, String> bindings,
    ElementAnnotation annotation,
    Element element, {
    Map<String, String> immutableBindings,
  }) {
    final value = annotation.computeConstantValue();
    final propertyName = element.displayName;
    final bindingName =
        coerceString(value, 'bindingPropertyName', defaultTo: propertyName);
    _prohibitBindingChange(element.enclosingElement as ClassElement,
        propertyName, bindingName, immutableBindings ?? bindings);
    bindings[propertyName] = bindingName;
  }

  /// Collects inheritable metadata declared on [element].
  void _collectInheritableMetadataOn(ClassElement element) {
    // Skip 'Object' since it can't have metadata and we only want to record
    // whether a user type implements 'noSuchMethod'.
    if (element.type.isObject) return;
    if (element.getMethod('noSuchMethod') != null) {
      _implementsNoSuchMethod = true;
    }
    final annotation = element.metadata
        .firstWhere(safeMatcher(isDirective), orElse: () => null);
    if (annotation != null) {
      // Collect metadata from class annotation.
      final annotationValue = annotation.computeConstantValue();
      final host = coerceStringMap(annotationValue, 'host');
      CompileDirectiveMetadata.deserializeHost(
          host, _hostAttributes, _hostListeners, _hostProperties);
    }
    // Collect metadata from field and property accessor annotations.
    super.visitClassElement(element);
    // Merge field and setter inputs, so that a derived field input binding is
    // not overridden by an inherited setter input.
    _inputs..addAll(_fieldInputs)..addAll(_setterInputs);
    _fieldInputs..clear();
    _setterInputs..clear();
  }

  /// Collects inheritable metadata from [element] and its supertypes.
  void _collectInheritableMetadata(ClassElement element) {
    // Reverse supertypes to traverse inheritance hierarchy from top to bottom
    // so that derived bindings overwrite their inherited definition.
    for (var type in element.allSupertypes.reversed) {
      _collectInheritableMetadataOn(type.element);
    }
    _collectInheritableMetadataOn(element);
  }

  CompileDirectiveMetadata _createCompileDirectiveMetadata(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    _directiveClassElement = element;
    _collectInheritableMetadata(element);
    final isComp = safeMatcher(isComponent)(annotation);
    final annotationValue = annotation.computeConstantValue();
    // Some directives won't have templates but the template parser is going to
    // assume they have at least defaults.
    CompileTypeMetadata componentType =
        element.accept(new CompileTypeMetadataVisitor(_library));
    final template = isComp
        ? _createTemplateMetadata(annotationValue, componentType)
        : new CompileTemplateMetadata();
    final analyzedClass =
        new AnalyzedClass(element, isMockLike: _implementsNoSuchMethod);
    return new CompileDirectiveMetadata(
      type: componentType,
      metadataType: isComp
          ? CompileDirectiveMetadataType.Component
          : CompileDirectiveMetadataType.Directive,
      selector: coerceString(annotationValue, 'selector'),
      exportAs: coerceString(annotationValue, 'exportAs'),
      // Even for directives, we want change detection set to the default.
      changeDetection:
          _changeDetection(element, annotationValue, 'changeDetection'),
      inputs: _inputs,
      inputTypes: _inputTypes,
      outputs: _outputs,
      hostListeners: _hostListeners,
      hostProperties: _hostProperties,
      hostAttributes: _hostAttributes,
      analyzedClass: analyzedClass,
      lifecycleHooks: extractLifecycleHooks(element),
      providers: _extractProviders(annotationValue, 'providers'),
      viewProviders: _extractProviders(annotationValue, 'viewProviders'),
      exports: _extractExports(annotation as ElementAnnotationImpl, element),
      queries: _queries,
      viewQueries: _viewQueries,
      template: template,
      visibility: coerceEnum(
        annotationValue,
        _visibilityProperty,
        Visibility.values,
        defaultTo: Visibility.local,
      ),
    );
  }

  CompileTemplateMetadata _createTemplateMetadata(
      DartObject component, CompileTypeMetadata componentType) {
    var template = component;
    String templateContent = coerceString(template, 'template');
    String templateUrl = coerceString(template, 'templateUrl');
    if (templateContent != null && templateUrl != null) {
      // TODO: https://github.com/dart-lang/angular/issues/851.
      log.severe(''
          'Component "${componentType.name}" in\n  ${componentType.moduleUrl}:\n'
          '  Cannot supply both "template" and "templateUrl"');
    }
    return new CompileTemplateMetadata(
      encapsulation: _encapsulation(template),
      template: templateContent,
      templateUrl: templateUrl,
      styles: coerceStringList(template, 'styles'),
      styleUrls: coerceStringList(template, 'styleUrls'),
      preserveWhitespace: coerceBool(
        component,
        'preserveWhitespace',
        defaultTo: false,
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
      visitAll(
          const ModuleReader()
              .extractProviderObjects(getField(component, providerField)),
          new CompileTypeMetadataVisitor(_library).createProviderMetadata);

  List<CompileIdentifierMetadata> _extractExports(
      ElementAnnotationImpl annotation, ClassElement element) {
    var exports = <CompileIdentifierMetadata>[];

    // There is an implicit "export" for the directive class itself
    exports.add(new CompileIdentifierMetadata(
        name: element.name,
        moduleUrl: moduleUrl(element.library),
        analyzedClass: new AnalyzedClass(element)));

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
      AnalyzedClass analyzedClass;
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

      if (id.staticElement is ClassElement) {
        analyzedClass = new AnalyzedClass(id.staticElement as ClassElement);
      }

      // TODO(het): Also store the `DartType` since we know it statically.
      exports.add(new CompileIdentifierMetadata(
        name: name,
        prefix: prefix,
        moduleUrl: moduleUrl(id.staticElement.library),
        analyzedClass: analyzedClass,
      ));
    }
    return exports;
  }
}

List<LifecycleHooks> extractLifecycleHooks(ClassElement clazz) {
  const hooks = const <TypeChecker, LifecycleHooks>{
    const TypeChecker.fromRuntime(OnInit): LifecycleHooks.onInit,
    const TypeChecker.fromRuntime(OnDestroy): LifecycleHooks.onDestroy,
    const TypeChecker.fromRuntime(DoCheck): LifecycleHooks.doCheck,
    const TypeChecker.fromRuntime(OnChanges): LifecycleHooks.onChanges,
    const TypeChecker.fromRuntime(AfterChanges): LifecycleHooks.afterChanges,
    const TypeChecker.fromRuntime(AfterContentInit):
        LifecycleHooks.afterContentInit,
    const TypeChecker.fromRuntime(AfterContentChecked):
        LifecycleHooks.afterContentChecked,
    const TypeChecker.fromRuntime(AfterViewInit): LifecycleHooks.afterViewInit,
    const TypeChecker.fromRuntime(AfterViewChecked):
        LifecycleHooks.afterViewChecked,
  };
  return hooks.keys
      .where((hook) => hook.isAssignableFrom(clazz))
      .map((t) => hooks[t])
      .toList();
}

void _prohibitBindingChange(
  ClassElement element,
  String propertyName,
  String bindingName,
  Map<String, String> bindings,
) {
  if (bindings.containsKey(propertyName) &&
      bindings[propertyName] != bindingName) {
    log.severe(
        "'${element.displayName}' overwrites the binding name of property "
        "'$propertyName' from '${bindings[propertyName]}' to '$bindingName'.");
  }
}
