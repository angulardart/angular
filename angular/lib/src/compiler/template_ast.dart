import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/view_compiler/parse_utils.dart'
    show handlerTypeFromExpression, HandlerType;

import '../core/security.dart';
import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompileTokenMetadata,
        CompileProviderMetadata;
import 'expression_parser/ast.dart' show AST;

/// An Abstract Syntax Tree node representing part of a parsed Angular template.
abstract class TemplateAst {
  /// The source span from which this node was parsed.
  SourceSpan sourceSpan;

  /// Visit this node and possibly transform it.
  dynamic visit(TemplateAstVisitor visitor, dynamic context);
}

/// A segment of text within the template.
class TextAst implements TemplateAst {
  String value;
  num ngContentIndex;
  SourceSpan sourceSpan;
  TextAst(this.value, this.ngContentIndex, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitText(this, context);
  }
}

/// A bound expression within the text of a template.
class BoundTextAst implements TemplateAst {
  AST value;
  num ngContentIndex;
  SourceSpan sourceSpan;
  BoundTextAst(this.value, this.ngContentIndex, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitBoundText(this, context);
  }
}

/// A plain attribute on an element.
class AttrAst implements TemplateAst {
  String name;
  String value;
  SourceSpan sourceSpan;
  AttrAst(this.name, this.value, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitAttr(this, context);
  }
}

/// A binding for an element property (e.g. [property]='expression').
class BoundElementPropertyAst implements TemplateAst {
  String name;
  PropertyBindingType type;
  AST value;
  String unit;
  SourceSpan sourceSpan;
  TemplateSecurityContext securityContext;
  BoundElementPropertyAst(this.name, this.type, this.securityContext,
      this.value, this.unit, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitElementProperty(this, context);
  }
}

/// Public part of ProviderElementContext passed to
/// ElementAst/EmbeddedTemplateAst to drive codegen optimizations.
abstract class ElementProviderUsage {
  bool get requiresViewContainer;
  bool hasNonLocalRequest(ProviderAst providerAst);
}

/// A binding for an element event (e.g. (event)='handler()').
class BoundEventAst implements TemplateAst {
  String name;
  AST handler;
  SourceSpan sourceSpan;
  BoundEventAst(this.name, this.handler, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitEvent(this, context);
  }

  HandlerType get handlerType => handlerTypeFromExpression(handler);
}

/// A reference declaration on an element (e.g. let someName='expression').
class ReferenceAst implements TemplateAst {
  String name;
  CompileTokenMetadata value;
  SourceSpan sourceSpan;
  ReferenceAst(this.name, this.value, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitReference(this, context);
  }
}

/// A variable declaration on a <template> (e.g. var-someName='someLocalName').
class VariableAst implements TemplateAst {
  String name;
  String value;
  SourceSpan sourceSpan;
  VariableAst(this.name, this.value, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitVariable(this, context);
  }
}

/// An element declaration in a template.
class ElementAst implements TemplateAst {
  String name;
  List<AttrAst> attrs;
  List<BoundElementPropertyAst> inputs;
  List<BoundEventAst> outputs;
  List<ReferenceAst> references;
  List<DirectiveAst> directives;
  List<ProviderAst> providers;
  final ElementProviderUsage elementProviderUsage;
  List<TemplateAst> children;
  num ngContentIndex;
  SourceSpan sourceSpan;

  ElementAst(
      this.name,
      this.attrs,
      this.inputs,
      this.outputs,
      this.references,
      this.directives,
      this.providers,
      this.elementProviderUsage,
      this.children,
      this.ngContentIndex,
      this.sourceSpan);

  bool get hasViewContainer =>
      elementProviderUsage?.requiresViewContainer ?? false;

  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitElement(this, context);
  }
}

/// A <template> element included in an Angular template.
class EmbeddedTemplateAst implements TemplateAst {
  List<AttrAst> attrs;
  List<BoundEventAst> outputs;
  List<ReferenceAst> references;
  List<VariableAst> variables;
  List<DirectiveAst> directives;
  List<ProviderAst> providers;
  List<TemplateAst> children;
  final ElementProviderUsage elementProviderUsage;
  final bool hasDeferredComponent;
  num ngContentIndex;
  SourceSpan sourceSpan;

  EmbeddedTemplateAst(
      this.attrs,
      this.outputs,
      this.references,
      this.variables,
      this.directives,
      this.providers,
      this.elementProviderUsage,
      this.children,
      this.ngContentIndex,
      this.sourceSpan,
      {this.hasDeferredComponent: false});

  bool get hasViewContainer => elementProviderUsage.requiresViewContainer;

  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitEmbeddedTemplate(this, context);
  }
}

/// A directive property with a bound value (e.g. *ngIf='condition').
class BoundDirectivePropertyAst implements TemplateAst {
  String directiveName;
  String templateName;
  AST value;
  SourceSpan sourceSpan;
  BoundDirectivePropertyAst(
      this.directiveName, this.templateName, this.value, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitDirectiveProperty(this, context);
  }
}

/// A directive declared on an element.
class DirectiveAst implements TemplateAst {
  CompileDirectiveMetadata directive;
  List<BoundDirectivePropertyAst> inputs;
  List<BoundElementPropertyAst> hostProperties;
  List<BoundEventAst> hostEvents;
  SourceSpan sourceSpan;
  DirectiveAst(this.directive, this.inputs, this.hostProperties,
      this.hostEvents, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitDirective(this, context);
  }
}

/// A provider declared on an element.
class ProviderAst implements TemplateAst {
  CompileTokenMetadata token;
  bool multiProvider;

  /// Whether provider should be eagerly created at build time.
  ///
  /// Otherwise the AppView will provide a getter for the provider to lazily
  /// access the provider and return it.
  bool eager;

  /// False if provider doesn't support injection into dynamically loaded
  /// children.
  ///
  /// Typically TemplateRef, NgIf don't need to be injected into dynamic
  /// children and this flag allows injectorGetInternal to create more
  /// optimal code by skipping these.
  bool dynamicallyReachable;

  /// Whether the provider is visible for injection.
  ///
  /// If false, no code is generated to return this provider from an injector,
  /// nor will the instance be used as a parameter to satisfy local
  /// dependencies.
  bool visibleForInjection;

  List<CompileProviderMetadata> providers;
  ProviderAstType providerType;
  SourceSpan sourceSpan;

  ProviderAst(
    this.token,
    this.multiProvider,
    this.providers,
    this.providerType,
    this.sourceSpan, {
    this.eager,
    this.dynamicallyReachable: true,
    this.visibleForInjection: true,
  });

  // No visit method in the visitor for now...
  dynamic visit(TemplateAstVisitor visitor, dynamic context) => null;

  /// Returns true if the provider is used by a constructor in a child
  /// CompileView or queried which requires non local access.
  ///
  /// It is a signal to view builder to create a public field inside AppView
  /// to allow other AppView(s) or change detector access to this provider.
  bool get hasNonLocalRequests => throw new UnimplementedError();
}

enum ProviderAstType {
  /// Public providers (Directive.providers) that can be reached across views.
  PublicService,

  /// Provide providers (Directive.viewProviders) that are visible within
  /// template only.
  PrivateService,

  /// A provider that represents the Component type.
  Component,

  /// A provider that represents a Directive type.
  Directive,

  /// A provider for a functional directive only visible within a template.
  FunctionalDirective,

  /// Provider that is used by compiled code itself such as TemplateRef.
  Builtin
}

/// Position where content is to be projected (instance of <ng-content> in
/// a template).
class NgContentAst implements TemplateAst {
  num index;
  num ngContentIndex;
  SourceSpan sourceSpan;
  NgContentAst(this.index, this.ngContentIndex, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitNgContent(this, context);
  }
}

/// Enumeration of types of property bindings.
enum PropertyBindingType {
  /// A normal binding to a property (e.g. [property]='expression').
  Property,

  /// A binding to an element attribute (e.g. [attr.name]='expression').
  Attribute,

  /// A binding to a CSS class (e.g. [class.name]='condition').
  Class,

  /// A binding to a style rule (e.g. [style.rule]='expression').
  Style
}

/// A visitor for [TemplateAst] trees that will process each node.
abstract class TemplateAstVisitor {
  dynamic visitNgContent(NgContentAst ast, dynamic context);
  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context);
  dynamic visitElement(ElementAst ast, dynamic context);
  dynamic visitReference(ReferenceAst ast, dynamic context);
  dynamic visitVariable(VariableAst ast, dynamic context);
  dynamic visitEvent(BoundEventAst ast, dynamic context);
  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context);
  dynamic visitAttr(AttrAst ast, dynamic context);
  dynamic visitBoundText(BoundTextAst ast, dynamic context);
  dynamic visitText(TextAst ast, dynamic context);
  dynamic visitDirective(DirectiveAst ast, dynamic context);
  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context);
}

/// Visit every node in a list of [TemplateAst]s with the given
/// [TemplateAstVisitor].
List templateVisitAll(TemplateAstVisitor visitor, List<TemplateAst> asts,
    [dynamic context]) {
  var result = [];
  for (TemplateAst ast in asts) {
    var astResult = ast.visit(visitor, context);
    if (astResult != null) {
      result.add(astResult);
    }
  }
  return result;
}
