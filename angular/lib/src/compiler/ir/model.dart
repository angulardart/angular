import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/analyzed_class.dart' as analyzed;
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/i18n/message.dart';
import 'package:angular/src/compiler/security.dart';
import 'package:angular/src/compiler/template_ast.dart';
import 'package:angular/src/compiler/view_compiler/compile_element.dart';
import 'package:angular/src/compiler/view_compiler/compile_view.dart';
import 'package:angular/src/compiler/view_compiler/ir/provider_source.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler_utils.dart'
    show namespaceUris;

import '../expression_parser/ast.dart' as ast;
import '../output/output_ast.dart' as o;

/// Base class for all intermediate representation (IR) data model classes.
abstract class IRNode {
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]);
}

/// Top-level object to encapsulate the IR objects created by the frontend and
/// passed to the backend.
class Library implements IRNode {
  final List<Component> components;
  final List<Directive> directives;

  Library(this.components, this.directives);

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitLibrary(this, context);
}

/// The core reusable UI building blocks for an application.
class Component implements IRNode {
  final String name;
  final ViewEncapsulation encapsulation;

  final List<View> views;

  final List<String> styles;
  final List<String> styleUrls;

  Component(this.name,
      {this.encapsulation = ViewEncapsulation.emulated,
      this.views = const [],
      this.styles = const [],
      this.styleUrls = const []});

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitComponent(this, context);
}

class Directive implements IRNode {
  final String name;

  final List<o.TypeParameter> typeParameters;

  final CompileDirectiveMetadata metadata;

  final List<Binding> hostProperties;

  Directive({
    this.name,
    this.typeParameters,
    this.hostProperties,
    this.metadata,
  });

  /// Whether the directive requires a change detector class to be generated.
  ///
  /// [DirectiveChangeDetector] classes should only be generated if they
  /// reduce the amount of duplicate code. Therefore we check for the presence
  /// of host bindings to move from each call site to a single method.
  bool get requiresDirectiveChangeDetector => hostProperties.isNotEmpty;

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitDirective(this, context);
}

/// Defines template and style encapsulation options available for Component's
/// [View].
///
/// See [View#encapsulation].
enum ViewEncapsulation {
  /// Emulate `Native` scoping of styles by adding an attribute containing
  /// surrogate id to the Host Element and pre-processing the style rules
  /// provided via [View#styles] or [View#stylesUrls], and
  /// adding the new Host Element attribute to all selectors.
  ///
  /// This is the default option.
  emulated,

  /// Don't provide any template or style encapsulation.
  none,
}

abstract class View extends IRNode {
  List<IRNode> get children;

  CompileView compileView;

  // TODO(alorenzen): Replace with IR model classes.
  CompileDirectiveMetadata get cmpMetadata;
  List<TemplateAst> get parsedTemplate;
  List<CompileTypedMetadata> get directiveTypes;
  List<CompilePipeMetadata> get pipes;
}

class ComponentView implements View {
  @override
  final List<IRNode> children;
  @override
  final CompileDirectiveMetadata cmpMetadata;
  @override
  final List<TemplateAst> parsedTemplate;
  @override
  final List<CompileTypedMetadata> directiveTypes;
  @override
  final List<CompilePipeMetadata> pipes;

  @override
  CompileView compileView;

  ComponentView(
      {this.children = const [],
      @required this.cmpMetadata,
      this.parsedTemplate = const [],
      this.directiveTypes = const [],
      this.pipes = const []});

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitComponentView(this, context);
}

class HostView implements View {
  final ComponentView componentView;

  @override
  final CompileDirectiveMetadata cmpMetadata;
  @override
  final List<TemplateAst> parsedTemplate;
  @override
  final List<CompileTypedMetadata> directiveTypes;
  @override
  final List<CompilePipeMetadata> pipes = const [];

  @override
  CompileView compileView;

  HostView(
    this.componentView, {
    @required this.cmpMetadata,
    this.parsedTemplate = const [],
    this.directiveTypes = const [],
  });

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitHostView(this, context);

  @override
  List<IRNode> get children => [componentView];
}

class EmbeddedView implements View {
  @override
  final List<IRNode> children;
  @override
  final List<TemplateAst> parsedTemplate;

  @override
  final CompileDirectiveMetadata cmpMetadata = null;
  @override
  final List<CompileTypedMetadata> directiveTypes = const [];
  @override
  final List<CompilePipeMetadata> pipes = const [];

  @override
  CompileView compileView;

  EmbeddedView(this.parsedTemplate) : children = const [];

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitEmbeddedView(this, context);
}

/// An element node in the template.
///
/// This may represent an HTML element, such as `<div>`, or a Component
/// instance.
class Element implements IRNode {
  final CompileElement compileElement;
  final List<Binding> inputs;
  final List<Binding> outputs;
  final List<MatchedDirective> matchedDirectives;

  // TODO(b/120624750): Replace with IR model classes.
  final List<TemplateAst> parsedTemplate;

  final List<IRNode> children;

  Element(
    this.compileElement,
    this.inputs,
    this.outputs,
    this.matchedDirectives,
    this.parsedTemplate,
    this.children,
  );

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitElement(this, context);
}

/// A directive which has been matched to an element in the template.
///
/// An instance of this class represents the actual binding in the template,
/// not just the properties declared by the underlying directive.
class MatchedDirective implements IRNode {
  /// Source of the directive in the compiled output.
  ///
  /// Necessary to bind calls to the correct class instance.
  final ProviderSource providerSource;
  final List<Binding> inputs;
  final List<Binding> outputs;
  final Set<Lifecycle> lifecycles;

  /// Whether the underlying directive declares any inputs.
  ///
  /// This will be true even if there are no inputs matched in the template.
  final bool hasInputs;
  final bool hasHostProperties;
  final bool isComponent;
  final bool isOnPush;

  MatchedDirective({
    @required this.providerSource,
    @required this.inputs,
    @required this.outputs,
    @required Set<Lifecycle> lifecycles,
    @required this.hasInputs,
    @required this.hasHostProperties,
    @required this.isComponent,
    @required this.isOnPush,
  }) : lifecycles = lifecycles;

  bool hasLifecycle(Lifecycle lifecycle) => lifecycles.contains(lifecycle);

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitMatchedDirective(this, context);
}

enum Lifecycle {
  afterChanges,
  onInit,
  doCheck,
  afterContentInit,
  afterContentChecked,
  afterViewInit,
  afterViewChecked,
  onDestroy,
}

/// A generic representation of a value binding.
///
/// This is represented as a pairing between the [source], or value being bound,
/// and the [target], or the place where the value is actually bound.
class Binding implements IRNode {
  final BindingSource source;
  final BindingTarget target;

  /// For most bindings, Angular will generate a checkBinding() call before
  /// assigning the source expression to the target.
  ///
  /// For a direct binding, we can skip this check. This assumes that either the
  /// source is immutable, or that the target will handle the dirty checking
  /// itself.
  final bool isDirect;

  Binding({this.source, this.target, this.isDirect = false});

  @override
  R accept<R, C, CO extends C>(IRVisitor<R, C> visitor, [CO context]) =>
      visitor.visitBinding(this, context);
}

abstract class BindingTarget extends IRNode {
  TemplateSecurityContext get securityContext;
  o.OutputType get type;

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
      [CO context]);
}

class TextBinding implements BindingTarget {
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;
  @override
  final o.OutputType type = null;

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitTextBinding(this, context);
}

class HtmlBinding implements BindingTarget {
  // TODO(b/128354029): Determine if this is the currect value in all cases,
  // and then document it.
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;
  @override
  final o.OutputType type = null;

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitHtmlBinding(this, context);
}

class ClassBinding implements BindingTarget {
  /// Name of the class binding, i.e. foo in [class.foo]='bar'.
  ///
  /// If name is null, then we treat this as a [className]='"foo"' or
  /// [attr.class]='foo'.
  final String name;

  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;

  ClassBinding({this.name});

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitClassBinding(this, context);

  /// When a class name is specified, then the [BindingSource] is a boolean to
  /// toggle the class on and off.
  ///
  /// When a class name is specified, then the [BindingSource] is the actual
  /// class string to be set.
  @override
  o.OutputType get type => name == null ? o.STRING_TYPE : o.BOOL_TYPE;
}

class TabIndexBinding implements BindingTarget {
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;
  @override
  final o.OutputType type = null;

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitTabIndexBinding(this, context);
}

class StyleBinding implements BindingTarget {
  final String name;
  final String unit;

  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.style;
  @override
  final o.OutputType type = null;

  StyleBinding(this.name, this.unit);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitStyleBinding(this, context);
}

class AttributeBinding implements BindingTarget {
  final String namespace;
  final String name;

  final bool isConditional;
  @override
  final TemplateSecurityContext securityContext;
  @override
  final o.OutputType type = null;

  AttributeBinding(
    this.name, {
    String namespace,
    this.isConditional = false,
    @required this.securityContext,
  }) : this.namespace = namespaceUris[namespace];

  bool get hasNamespace => namespace != null;

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitAttributeBinding(this, context);
}

class PropertyBinding implements BindingTarget {
  final String name;
  @override
  final TemplateSecurityContext securityContext;
  @override
  final o.OutputType type = null;

  PropertyBinding(this.name, this.securityContext);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitPropertyBinding(this, context);
}

class InputBinding implements BindingTarget {
  /// The name of the input declared on the directive class.
  ///
  /// For example, "name" in
  ///
  /// ```
  /// class User {
  ///   @Input('userName')
  ///   String name;
  /// }
  /// ```
  final String name;

  @override
  final o.OutputType type;

  @override
  final securityContext = TemplateSecurityContext.none;

  InputBinding(this.name, this.type);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitInputBinding(this, context);
}

abstract class BoundEvent implements BindingTarget {
  final String name;

  BoundEvent(this.name);

  @override
  final securityContext = TemplateSecurityContext.none;
  @override
  final o.OutputType type = null;
}

class NativeEvent extends BoundEvent {
  NativeEvent(String name) : super(name);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitNativeEvent(this, context);
}

class CustomEvent extends BoundEvent {
  CustomEvent(String name) : super(name);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitCustomEvent(this, context);
}

class DirectiveOutput extends BoundEvent {
  final bool isMockLike;

  DirectiveOutput(String name, this.isMockLike) : super(name);

  @override
  R accept<R, C, CO extends C>(BindingTargetVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitDirectiveOutput(this, context);
}

abstract class BindingSource extends IRNode {
  bool get isImmutable;
  bool get isNullable;
  bool get isString;

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
      [CO context]);
}

class BoundI18nMessage implements BindingSource {
  final I18nMessage value;

  @override
  final bool isImmutable = true;
  @override
  final bool isNullable = false;
  @override
  final bool isString = true;

  BoundI18nMessage(this.value);

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitBoundI18nMessage(this, context);
}

abstract class BoundLiteral implements BindingSource {
  @override
  final bool isImmutable = true;

  @override
  final bool isNullable = false;
}

class StringLiteral extends BoundLiteral {
  final String value;

  StringLiteral(this.value);

  @override
  final bool isString = true;

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitStringLiteral(this, context);
}

/// A [BindingSource] which represents a general-purpose expression.
class BoundExpression implements BindingSource {
  final ast.ASTWithSource expression;
  final SourceSpan sourceSpan;
  final analyzed.AnalyzedClass _analyzedClass;

  BoundExpression(this.expression, this.sourceSpan, this._analyzedClass);

  /// Wraps the expression in an `== true` check, in order to support null
  /// values.
  ///
  /// This hack is to allow legacy NgIf behavior on null inputs
  BoundExpression.falseIfNull(ast.ASTWithSource parsedExpression,
      SourceSpan sourceSpan, analyzed.AnalyzedClass scope)
      : this(
            analyzed.isImmutable(parsedExpression.ast, scope)
                ? parsedExpression
                : ast.ASTWithSource.from(
                    parsedExpression,
                    ast.Binary('==', parsedExpression.ast,
                        ast.LiteralPrimitive(true))),
            sourceSpan,
            scope);

  @override
  bool get isImmutable => analyzed.isImmutable(expression.ast, _analyzedClass);

  @override
  bool get isNullable => analyzed.canBeNull(expression.ast);

  @override
  bool get isString => analyzed.isString(expression.ast, _analyzedClass);

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitBoundExpression(this, context);
}

abstract class EventHandler implements BindingSource {
  /// Returns an [EventHandler] that merges this and [handler] together.
  ///
  /// The returned [EventHandler] may or may not be a new instance, based on the
  /// implementation of subclasses.
  EventHandler merge(EventHandler handler);

  @override
  final bool isImmutable = false;
  @override
  final bool isNullable = false;
  @override
  final bool isString = false;
}

/// An [EventHandler] that is a single method call with 0 or 1 arguments.
///
/// The single argument is the `$event` emitted by the event source.
///
/// In generated code, this can be expressed as a "tear-off" expression.
class SimpleEventHandler extends EventHandler {
  final ast.ASTWithSource handler;
  final SourceSpan sourceSpan;
  final ProviderSource directiveInstance;

  final int numArgs;

  SimpleEventHandler(this.handler, this.sourceSpan,
      {this.directiveInstance, this.numArgs});

  @override
  EventHandler merge(EventHandler handler) =>
      ComplexEventHandler._([this, handler]);

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitSimpleEventHandler(this, context);
}

/// An [EventHandler] that cannot be expressed as a [SimpleEventHandler].
///
/// This might be a be a single method call with multiple arguments, or an
/// argument other than the $event parameter. It may be an expression other than
/// a method call. It may also be multiple statements that have been merged
/// together.
///
/// In generated code, this requires a generated method to wrap the event
/// handlers.
class ComplexEventHandler extends EventHandler {
  final List<EventHandler> handlers;

  ComplexEventHandler._(this.handlers);

  ComplexEventHandler.forAst(ast.ASTWithSource handler, SourceSpan sourceSpan,
      {ProviderSource directiveInstance})
      : this._([
          SimpleEventHandler(
            handler,
            sourceSpan,
            directiveInstance: directiveInstance,
          )
        ]);

  @override
  EventHandler merge(EventHandler handler) {
    handlers.add(handler);
    return this;
  }

  @override
  R accept<R, C, CO extends C>(BindingSourceVisitor<R, C> visitor,
          [CO context]) =>
      visitor.visitComplexEventHandler(this, context);
}

abstract class BindingTargetVisitor<R, C> {
  R visitTextBinding(TextBinding textBinding, [C context]);
  R visitHtmlBinding(HtmlBinding htmlBinding, [C context]);
  R visitClassBinding(ClassBinding classBinding, [C context]);
  R visitTabIndexBinding(TabIndexBinding tabIndexBinding, [C context]);
  R visitStyleBinding(StyleBinding styleBinding, [C context]);
  R visitAttributeBinding(AttributeBinding attributeBinding, [C context]);
  R visitPropertyBinding(PropertyBinding propertyBinding, [C context]);
  R visitInputBinding(InputBinding inputBinding, [C context]);
  R visitNativeEvent(NativeEvent nativeEvent, [C context]);
  R visitCustomEvent(CustomEvent customEvent, [C context]);
  R visitDirectiveOutput(DirectiveOutput directiveOutput, [C context]);
}

abstract class BindingSourceVisitor<R, C> {
  R visitBoundI18nMessage(BoundI18nMessage boundI18nMessage, [C context]);
  R visitStringLiteral(StringLiteral stringLiteral, [C context]);
  R visitBoundExpression(BoundExpression boundExpression, [C context]);
  R visitSimpleEventHandler(SimpleEventHandler simpleEventHandler, [C context]);
  R visitComplexEventHandler(ComplexEventHandler complexEventHandler,
      [C context]);
}

abstract class IRVisitor<R, C> extends Object
    with BindingTargetVisitor<R, C>, BindingSourceVisitor<R, C> {
  R visitLibrary(Library library, [C context]);

  R visitComponent(Component component, [C context]);
  R visitDirective(Directive directive, C context);

  R visitComponentView(ComponentView componentView, [C context]);
  R visitHostView(HostView hostView, [C context]);
  R visitEmbeddedView(EmbeddedView embeddedView, [C context]);

  R visitElement(Element element, [C context]);
  R visitMatchedDirective(MatchedDirective matchedDirective, [C context]);

  R visitBinding(Binding binding, [C context]);
}
