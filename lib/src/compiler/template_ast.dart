import 'package:source_span/source_span.dart';

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

/// A binding for an element event (e.g. (event)='handler()').
class BoundEventAst implements TemplateAst {
  String name;
  AST handler;
  SourceSpan sourceSpan;
  BoundEventAst(this.name, this.handler, this.sourceSpan);
  dynamic visit(TemplateAstVisitor visitor, dynamic context) {
    return visitor.visitEvent(this, context);
  }
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
  bool hasViewContainer;
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
      this.hasViewContainer,
      this.children,
      this.ngContentIndex,
      this.sourceSpan);
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
  bool hasViewContainer;
  List<TemplateAst> children;
  num ngContentIndex;
  SourceSpan sourceSpan;
  EmbeddedTemplateAst(
      this.attrs,
      this.outputs,
      this.references,
      this.variables,
      this.directives,
      this.providers,
      this.hasViewContainer,
      this.children,
      this.ngContentIndex,
      this.sourceSpan);
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
  bool eager;
  List<CompileProviderMetadata> providers;
  ProviderAstType providerType;
  SourceSpan sourceSpan;
  ProviderAst(this.token, this.multiProvider, this.eager, this.providers,
      this.providerType, this.sourceSpan);
  // No visit method in the visitor for now...
  dynamic visit(TemplateAstVisitor visitor, dynamic context) => null;
}

enum ProviderAstType {
  PublicService,
  PrivateService,
  Component,
  Directive,
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
List<dynamic> templateVisitAll(
    TemplateAstVisitor visitor, List<TemplateAst> asts,
    [dynamic context = null]) {
  var result = [];
  asts.forEach((ast) {
    var astResult = ast.visit(visitor, context);
    if (astResult != null) {
      result.add(astResult);
    }
  });
  return result;
}
