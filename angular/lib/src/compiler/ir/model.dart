import 'package:meta/meta.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/template_ast.dart';

import '../expression_parser/ast.dart' as ast;
import '../output/output_ast.dart' as o;

/// Base class for all intermediate representation (IR) data model classes.
abstract class IRNode {
  R accept<R, C>(IRVisitor<R, C> visitor, [C context]);
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

abstract class IRVisitor<R, C> {
  R visitComponent(Component component, [C context]);
  R visitDirective(Directive directive, C context);

  R visitComponentView(ComponentView componentView, [C context]);
  R visitHostView(HostView hostView, [C context]);
}
