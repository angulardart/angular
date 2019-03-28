import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/analyzed_class.dart' as analyzed;
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/i18n/message.dart';
import 'package:angular/src/compiler/template_ast.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler_utils.dart'
    show namespaceUris;
import 'package:angular/src/core/security.dart';

import '../expression_parser/ast.dart' as ast;
import '../output/output_ast.dart' as o;

/// Base class for all intermediate representation (IR) data model classes.
abstract class IRNode {
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]);
}

/// Top-level object to encapsulate the IR objects created by the frontend and
/// passed to the backend.
class Library implements IRNode {
  final List<Component> components;
  final List<Directive> directives;

  Library(this.components, this.directives);

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
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
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitComponent(this, context);
}

class Directive implements IRNode {
  final String name;

  final List<o.TypeParameter> typeParameters;

  final CompileDirectiveMetadata metadata;

  /// Whether the directive requires a change detector class to be generated.
  ///
  /// [DirectiveChangeDetector] classes should only be generated if they
  /// reduce the amount of duplicate code. Therefore we check for the presence
  /// of host bindings to move from each call site to a single method.
  final bool requiresDirectiveChangeDetector;

  final bool implementsComponentState;
  final bool implementsOnChanges;

  final Map<String, ast.AST> hostProperties;

  Directive({
    this.name,
    this.typeParameters,
    this.hostProperties,
    this.metadata,
    this.requiresDirectiveChangeDetector,
    this.implementsComponentState,
    this.implementsOnChanges,
  });

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
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

  ComponentView(
      {this.children = const [],
      @required this.cmpMetadata,
      this.parsedTemplate = const [],
      this.directiveTypes = const [],
      this.pipes = const []});

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
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

  HostView(
    this.componentView, {
    @required this.cmpMetadata,
    this.parsedTemplate = const [],
    this.directiveTypes = const [],
  });

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitHostView(this, context);

  @override
  List<IRNode> get children => [componentView];
}

/// A generic representation of a value binding.
///
/// This is represented as a pairing between the [source], or value being bound,
/// and the [target], or the place where the value is actually bound.
class Binding implements IRNode {
  final BindingSource source;
  final BindingTarget target;

  Binding({this.source, this.target});

  @override
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]) =>
      visitor.visitBinding(this, context);
}

abstract class BindingTarget extends IRNode {
  TemplateSecurityContext get securityContext;

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]);
}

class TextBinding implements BindingTarget {
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitTextBinding(this, context);
}

class HtmlBinding implements BindingTarget {
  // TODO(b/128354029): Determine if this is the currect value in all cases,
  // and then document it.
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitHtmlBinding(this, context);
}

class ClassBinding implements BindingTarget {
  /// Name of the class binding, i.e. [class.name]='foo'.
  ///
  /// If name is null, then we treat this as a [className]='"foo"' or
  /// [attr.class]='foo'.
  final String name;

  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;

  ClassBinding({this.name});

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitClassBinding(this, context);
}

class TabIndexBinding implements BindingTarget {
  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.none;

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitTabIndexBinding(this, context);
}

class StyleBinding implements BindingTarget {
  final String name;
  final String unit;

  @override
  final TemplateSecurityContext securityContext = TemplateSecurityContext.style;

  StyleBinding(this.name, this.unit);

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitStyleBinding(this, context);
}

class AttributeBinding implements BindingTarget {
  final String namespace;
  final String name;

  final bool isConditional;
  @override
  final TemplateSecurityContext securityContext;

  AttributeBinding(
    this.name, {
    String namespace,
    this.isConditional = false,
    @required this.securityContext,
  }) : this.namespace = namespaceUris[namespace];

  bool get hasNamespace => namespace != null;

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitAttributeBinding(this, context);
}

class PropertyBinding implements BindingTarget {
  final String name;
  @override
  final TemplateSecurityContext securityContext;

  PropertyBinding(this.name, this.securityContext);

  @override
  R accept<R, C>(BindingTargetVisitor<R, C> visitor, [C context]) =>
      visitor.visitPropertyBinding(this, context);
}

abstract class BindingSource {
  bool get isImmutable;
  bool get isNullable;
  bool get isString;

  R accept<R, C>(BindingSourceVisitor<R, C> visitor, [C context]);
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
  R accept<R, C>(BindingSourceVisitor<R, C> visitor, [C context]) =>
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
  R accept<R, C>(BindingSourceVisitor<R, C> visitor, [C context]) =>
      visitor.visitStringLiteral(this, context);
}

/// A [BindingSource] which represents a general-purpose expression.
class BoundExpression implements BindingSource {
  final ast.AST expression;
  final SourceSpan sourceSpan;
  final analyzed.AnalyzedClass _analyzedClass;

  BoundExpression(this.expression, this.sourceSpan, this._analyzedClass);

  /// Wraps the expression in an `== true` check, in order to support null
  /// values.
  ///
  /// This hack is to allow legacy NgIf behavior on null inputs
  BoundExpression.falseIfNull(ast.AST parsedExpression, SourceSpan sourceSpan,
      analyzed.AnalyzedClass scope)
      : this(
            analyzed.isImmutable(parsedExpression, scope)
                ? parsedExpression
                : ast.Binary(
                    '==', parsedExpression, ast.LiteralPrimitive(true)),
            sourceSpan,
            scope);

  @override
  bool get isImmutable => analyzed.isImmutable(expression, _analyzedClass);

  @override
  bool get isNullable => analyzed.canBeNull(expression);

  @override
  bool get isString => analyzed.isString(expression, _analyzedClass);

  @override
  R accept<R, C>(BindingSourceVisitor<R, C> visitor, [C context]) =>
      visitor.visitBoundExpression(this, context);
}

abstract class BindingTargetVisitor<R, C> {
  R visitTextBinding(TextBinding textBinding, [C context]);
  R visitHtmlBinding(HtmlBinding htmlBinding, [C context]);
  R visitClassBinding(ClassBinding classBinding, [C context]);
  R visitTabIndexBinding(TabIndexBinding tabIndexBinding, [C context]);
  R visitStyleBinding(StyleBinding styleBinding, [C context]);
  R visitAttributeBinding(AttributeBinding attributeBinding, [C context]);
  R visitPropertyBinding(PropertyBinding propertyBinding, [C context]);
}

abstract class BindingSourceVisitor<R, C> {
  R visitBoundI18nMessage(BoundI18nMessage boundI18nMessage, [C context]);
  R visitStringLiteral(StringLiteral stringLiteral, [C context]);
  R visitBoundExpression(BoundExpression boundExpression, [C context]);
}

abstract class IRVisitor<R, C> extends Object
    with BindingTargetVisitor<R, C>, BindingSourceVisitor<R, C> {
  R visitLibrary(Library library, [C context]);

  R visitComponent(Component component, [C context]);
  R visitDirective(Directive directive, C context);

  R visitComponentView(ComponentView componentView, [C context]);
  R visitHostView(HostView hostView, [C context]);

  R visitBinding(Binding binding, [C context]);
}
