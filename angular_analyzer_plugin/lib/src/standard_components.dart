import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:meta/meta.dart';

typedef CaptureAspectFn<T> = void Function(
    Map<String, T> aspectMap, PropertyAccessorElement accessor);

/// Visit the source of dart:html and generate the standard [Component]s for the
/// standard HTML tags.
///
/// Currently this operates on the AST of `dart:html`, instead of the element
/// model, because the element model does not cantain enough information to do
/// this.
///
/// We also must analyze this against the file rather than a plain schema so
/// that when users later do:
///
/// ```html
/// <div #foo></div>
/// {{foo.bar}}
/// ```
///
/// we can match the static type of `foo` against the definition of `DivElement`
/// in `dart:html` itself, give autocompletions, etc.
class BuildStandardHtmlComponentsVisitor extends RecursiveAstVisitor {
  static const Map<String, String> specialElementClasses = <String, String>{
    "AudioElement": 'audio',
    "OptionElement": 'option',
    "DialogElement": "dialog",
    "MediaElement": "media",
    "MenuItemElement": "menuitem",
    "ModElement": "mod",
    "PictureElement": "picture"
  };

  // https://github.com/dart-lang/angular/blob/master/angular/lib/src/compiler/schema/dom_element_schema_registry.dart#196
  static const alternativeInputs = {
    'className': 'class',
    'innerHTML': 'innerHtml',
    'readOnly': 'readonly',
    'tabIndex': 'tabindex',
  };

  static const missingOutputs = {
    'focusin': 'FocusEvent',
    'focusout': 'FocusEvent',
  };

  final Map<String, Component> components;
  final Map<String, Output> events;

  final Map<String, Input> attributes;

  final Source source;

  final SecuritySchema securitySchema;

  ClassElement classElement;

  BuildStandardHtmlComponentsVisitor(this.components, this.events,
      this.attributes, this.source, this.securitySchema);

  /// Custom `dart:html` fixup for special names.
  ///
  /// TODO(mfairhurst) remove this fix once dart:html is fixed
  String fixName(String name) => name == 'innerHtml' ? 'innerHTML' : name;

  @override
  void visitClassDeclaration(ast.ClassDeclaration node) {
    classElement = node.declaredElement;
    super.visitClassDeclaration(node);
    if (classElement.name == 'HtmlElement') {
      final outputElements = _buildOutputs(true);
      for (final outputElement in outputElements) {
        events[outputElement.name] = outputElement;
      }
      final inputElements = _buildInputs();
      for (final inputElement in inputElements) {
        attributes[inputElement.name] = inputElement;
        final originalName = inputElement.originalName;
        if (originalName != null) {
          attributes[originalName] = inputElement;
        }
      }
    } else {
      final specialTagName = specialElementClasses[classElement.name];
      if (specialTagName != null) {
        final tag = specialTagName;
        // TODO any better offset we can do here?
        final tagOffset = classElement.nameOffset + 'HTML'.length;
        final component = _buildComponent(tag, tagOffset);
        components[tag] = component;
      }
    }
    classElement = null;
  }

  @override
  void visitCompilationUnit(ast.CompilationUnit unit) {
    super.visitCompilationUnit(unit);

    missingOutputs.forEach((name, type) {
      final unitElement = unit.declaredElement;
      final namespace = unitElement.library.publicNamespace;
      final eventClass = namespace.get(type) as ClassElement;
      events[name] = MissingOutput(
          name: name, eventType: eventClass.type, source: unitElement.source);
    });
  }

  @override
  void visitConstructorDeclaration(ast.ConstructorDeclaration node) {
    if (node.factoryKeyword != null) {
      super.visitConstructorDeclaration(node);
    }
  }

  @override
  void visitMethodInvocation(ast.MethodInvocation node) {
    final argumentList = node.argumentList;
    ast.Expression tagArgument;
    if (_isCreateElementInvocation(node)) {
      tagArgument = argumentList.arguments.single;
    } else if (_isCreatElementInterop(node)) {
      tagArgument = argumentList.arguments[3];
    }

    if (tagArgument is ast.SimpleStringLiteral) {
      final tag = tagArgument.value;
      final tagOffset = tagArgument.contentsOffset;
      // don't track <template>, angular treats those specially.
      if (tag != "template") {
        final component = _buildComponent(tag, tagOffset);
        components[tag] = component;
      }
    }
  }

  /// Is current node `document.createElement("div")` for some tag?
  bool _isCreateElementInvocation(ast.MethodInvocation node) {
    final target = node.target;
    final argumentList = node.argumentList;
    return target is ast.SimpleIdentifier &&
        target.name == 'document' &&
        node.methodName.name == 'createElement' &&
        argumentList != null &&
        argumentList.arguments.length == 1;
  }

  /// Is current node `JS(..., document, "div")` for some tag?
  bool _isCreatElementInterop(ast.MethodInvocation node) {
    final argumentList = node.argumentList;
    if (node.methodName.name == 'JS' &&
        argumentList != null &&
        argumentList.arguments.length == 4) {
      final documentArgument = argumentList.arguments[2];
      return documentArgument is ast.SimpleIdentifier &&
          documentArgument.name == 'document';
    }
    return false;
  }

  /// Return a new [Component] for the current [classElement].
  Component _buildComponent(String tag, int tagOffset) {
    final inputElements = _buildInputs(tagname: tag);
    final outputElements = _buildOutputs(false);
    return Component(
      classElement,
      inputs: inputElements,
      outputs: outputElements,
      selector: ElementNameSelector(
          SelectorName(tag, SourceRange(tagOffset, tag.length), source)),
      isHtml: true,
      looksLikeTemplate: false,
      templateUrlRange: null,
      ngContents: const [],
      pipes: <Pipe>[],
      templateText: null,
      templateTextRange: null,
      templateUrlSource: null,
      directives: const [],
      exports: const [],
      exportAs: null,
      contentChildrenFields: const [],
      contentChildFields: const [],
      attributes: const [],
    );
  }

  List<Input> _buildInputs({String tagname}) =>
      _captureAspects((inputMap, accessor) {
        final name = fixName(accessor.displayName);
        final prettyName = alternativeInputs[name];
        final originalName = prettyName == null ? null : name;
        if (!inputMap.containsKey(name)) {
          if (accessor.isSetter) {
            inputMap[name] = Input(
                name: prettyName ?? name,
                setter: accessor,
                nameRange:
                    SourceRange(accessor.nameOffset, accessor.nameLength),
                setterType: accessor.variable.type,
                originalName: originalName,
                securityContext: tagname == null
                    ? securitySchema.lookupGlobal(name)
                    : securitySchema.lookup(tagname, name));
          }
        }
      }, tagname == null); // Either grabbing HtmlElement attrs or skipping them

  List<Output> _buildOutputs(bool globalOutputs) =>
      _captureAspects((outputMap, accessor) {
        final domName = accessor.name.toLowerCase();
        if (domName == null) {
          return;
        }

        // Event domnames start with on
        final name = domName.substring("on".length);

        if (!outputMap.containsKey(name)) {
          if (accessor.isGetter) {
            final returnType =
                accessor.type == null ? null : accessor.type.returnType;
            DartType eventType;
            if (returnType != null && returnType is InterfaceType) {
              // TODO allow subtypes of ElementStream? This is a generated file
              // so might not be necessary.
              if (returnType.element.name == 'ElementStream') {
                eventType = returnType.typeArguments[0]; // may be null
                outputMap[name] = Output(
                    name: name,
                    getter: accessor,
                    eventType: eventType,
                    nameRange:
                        SourceRange(accessor.nameOffset, accessor.nameLength));
              }
            }
          }
        }
      }, globalOutputs); // Either grabbing HtmlElement events or skipping them

  List<T> _captureAspects<T>(CaptureAspectFn<T> addAspect, bool globalAspects) {
    final aspectMap = <String, T>{};
    final visitedTypes = <InterfaceType>{};

    void addAspects(InterfaceType type) {
      if (type != null && visitedTypes.add(type)) {
        // The events defined here are handled specially because everything
        // (even directives) can use them. Note, this leaves only a few
        // special elements with outputs such as BodyElement, everything else
        // relies on standardHtmlEvents checked after the outputs.
        if (globalAspects || type.name != 'HtmlElement') {
          type.accessors
              .where((elem) => !elem.isPrivate)
              .forEach((elem) => addAspect(aspectMap, elem));
          type.mixins.forEach(addAspects);
          addAspects(type.superclass);
        }
      }
    }

    addAspects(classElement.type);
    return aspectMap.values.toList();
  }
}

/// Define a "missing" output, which defines a [source] without a [getter].
class MissingOutput extends Output {
  @override
  final Source source;

  MissingOutput(
      {@required String name,
      @required this.source,
      @required DartType eventType,
      SourceRange nameRange})
      : super(
            name: name,
            nameRange: nameRange,
            getter: null,
            eventType: eventType);
}

/// A security context is an angular security concept for sanitizing HTML
/// attributes.
///
/// Example security contexts include binding to iframe urls, `innerHtml`, etc.
///
/// Each context may introduce new sanitized data structures that will be
/// accepted ([safeTypes]) instead of, or in addition to, the normal `dart:html`
/// API type.
///
/// If sanitization is available, then the safe types do not need to be used,
/// but are merely a way of turning of sanitization. When sanitization is not
/// available, the safe types must be used or a security exception will be
/// thrown.
class SecurityContext {
  final List<DartType> safeTypes;
  final bool sanitizationAvailable;

  SecurityContext(this.safeTypes, {this.sanitizationAvailable = true});
}

/// The schema for which attributes require which security contexts.
///
/// Used when getting input information from `dart:html` and building the
/// standard html inputs.
class SecuritySchema {
  static const securitySourcePath = 'package:angular/security.dart';
  static const protoSecuritySourcePath =
      'package:webutil.html.types.proto/html.pb.dart';
  final Map<String, SecurityContext> schema = {};

  SecuritySchema(
      {SecurityContext htmlSecurityContext,
      SecurityContext urlSecurityContext,
      SecurityContext scriptSecurityContext,
      SecurityContext styleSecurityContext,
      SecurityContext resourceUrlSecurityContext}) {
    // This is written to be easily synced to angular's security
    _registerSecuritySchema(
        htmlSecurityContext, ['iframe|srcdoc', '*|innerHTML', '*|outerHTML']);
    _registerSecuritySchema(styleSecurityContext, ['*|style']);
    _registerSecuritySchema(urlSecurityContext, [
      '*|formAction',
      'area|href',
      'area|ping',
      'audio|src',
      'a|href',
      'a|ping',
      'blockquote|cite',
      'body|background',
      'del|cite',
      'form|action',
      'img|src',
      'img|srcset',
      'input|src',
      'ins|cite',
      'q|cite',
      'source|src',
      'source|srcset',
      'video|poster',
      'video|src'
    ]);
    _registerSecuritySchema(resourceUrlSecurityContext, [
      'applet|code',
      'applet|codebase',
      'base|href',
      'embed|src',
      'frame|src',
      'head|profile',
      'html|manifest',
      'iframe|src',
      'link|href',
      'media|src',
      'object|codebase',
      'object|data',
      'script|src',
      'track|src'
    ]);
    // TODO where's script security?
  }

  SecurityContext lookup(String elementName, String name) =>
      schema['$elementName|$name'];

  SecurityContext lookupGlobal(String name) => schema['*|$name'];

  void _registerSecuritySchema(SecurityContext context, List<String> specs) {
    for (final spec in specs) {
      schema[spec] = context;
    }
  }
}

/// References to the resolved angular class models, to do subtype checks etc.
///
/// Certain analyses require knowing when users reference these specific core
/// angular classes (for instance, "pipes must extend PipeTransform"). Resolve
/// those classes before regular analysis, and cache those references here for
/// later use.
class StandardAngular {
  final ClassElement templateRef;
  final ClassElement elementRef;
  final ClassElement pipeTransform;
  final ClassElement component;
  final SecuritySchema securitySchema;

  StandardAngular(
      {this.templateRef,
      this.elementRef,
      this.pipeTransform,
      this.component,
      this.securitySchema});

  factory StandardAngular.fromAnalysis(
      {ResolvedUnitResult angularResult,
      ResolvedUnitResult securityResult,
      ResolvedUnitResult protoSecurityResult}) {
    final ng = angularResult.unit.declaredElement.library.exportNamespace;
    final security =
        securityResult.unit.declaredElement.library.exportNamespace;
    final protoSecurity = protoSecurityResult == null
        ? null
        : protoSecurityResult.unit.declaredElement.library.exportNamespace;

    List<DartType> interfaceTypes(List<Element> elements) => elements
        .whereType<ClassElement>()
        .map((e) => e?.type)
        .where((e) => e != null)
        .toList();

    List<DartType> safeTypes(String id) => interfaceTypes(
        [security.get('Safe$id'), protoSecurity?.get('Safe${id}Proto')]);

    final securitySchema = SecuritySchema(
        htmlSecurityContext: SecurityContext(safeTypes('Html')),
        urlSecurityContext: SecurityContext(safeTypes('Url')),
        styleSecurityContext: SecurityContext(safeTypes('Style')),
        scriptSecurityContext:
            SecurityContext(safeTypes('Script'), sanitizationAvailable: false),
        resourceUrlSecurityContext: SecurityContext(
            interfaceTypes([
              security.get('SafeResourceUrl'),
              protoSecurity?.get('TrustedResourceUrlProto')
            ]),
            sanitizationAvailable: false));

    return StandardAngular(
        elementRef: ng.get("ElementRef") as ClassElement,
        templateRef: ng.get("TemplateRef") as ClassElement,
        pipeTransform: ng.get("PipeTransform") as ClassElement,
        component: ng.get("Component") as ClassElement,
        securitySchema: securitySchema);
  }
}

/// Collection of [Component]s that reference HTML elements, and
/// [Input]s/[Output]s available on all tags.
///
/// Each known html tag is made into a [Component] with a selector that is just
/// a tag name selector for that tag. Their inputs and outputs are specific to
/// that tag when that tag has special attributes.
///
/// The base attributes (such as `onClick`, `hidden`, etc) which are part of the
/// base class of [Element] from `dart:html` are stored as the standard inputs
/// and outputs which can be bound on any component.
class StandardHtml {
  final Map<String, Component> components;
  final Map<String, Input> attributes;
  final Map<String, Output> standardEvents;
  final Map<String, Output> customEvents;

  final ClassElement elementClass;

  final ClassElement htmlElementClass;

  /// Attributes as a Set to remove duplicates.
  ///
  /// In attributes, there can be multiple strings that point to the same
  /// [Input] generated from [alternativeInputs] (below). This will
  /// provide a static source of unique [Input]s.
  final Set<Input> uniqueAttributeElements;

  StandardHtml(this.components, this.attributes, this.standardEvents,
      this.customEvents, this.elementClass, this.htmlElementClass)
      : uniqueAttributeElements = attributes.values.toSet();

  Map<String, Output> get events =>
      Map<String, Output>.from(standardEvents)..addAll(customEvents);
}
