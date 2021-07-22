import 'package:source_span/source_span.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/ast.dart'
    as ast;
import 'package:angular_compiler/v1/src/compiler/ir/model.dart' as ir;
import 'package:angular_compiler/v1/src/compiler/output/output_ast.dart' as o;
import 'package:angular_compiler/v1/src/compiler/schema/element_schema_registry.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/binding_converter.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/element_converter.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart';
import 'package:angular_compiler/v1/src/compiler/template_parser.dart';
import 'package:angular_compiler/v1/src/compiler/view_type.dart';

import 'bound_value_converter.dart';
import 'compile_element.dart' show CompileElement;
import 'compile_method.dart' show CompileMethod;
import 'compile_view.dart' show CompileView;
import 'event_binder.dart' show bindRenderOutputs, bindDirectiveOutputs;
import 'lifecycle_binder.dart'
    show
        bindDirectiveAfterChildrenCallbacks,
        bindDirectiveDetectChangesLifecycleCallbacks,
        bindPipeDestroyLifecycleCallbacks;
import 'property_binder.dart'
    show
        bindAndWriteToRenderer,
        bindDirectiveHostProps,
        bindDirectiveInputs,
        bindRenderInputs,
        bindRenderText;

/// Visits view nodes to generate code for bindings.
///
/// Called by ViewCompiler for each top level CompileView and the
/// ViewBinderVisitor recursively for each embedded template.
///
/// HostProperties are bound for Component and Host views, but not embedded
/// views.
void bindView(
  ir.View view,
  ElementSchemaRegistry? schemaRegistry, {
  required bool bindHostProperties,
}) {
  var visitor = _ViewBinderVisitor(view.compileView!);
  templateVisitAll(visitor, view.parsedTemplate, null);
  for (var pipe in view.compileView!.pipes) {
    bindPipeDestroyLifecycleCallbacks(pipe.meta, pipe.instance, pipe.view);
  }

  if (bindHostProperties) {
    _bindViewHostProperties(view.compileView!, schemaRegistry!);
  }
}

/// IMPORTANT: See the comment on [Compile.nodes].
class _ViewBinderVisitor implements TemplateAstVisitor<void, void> {
  final CompileView view;

  /// Index into [CompileView.nodes] that corresponds to the current AST.
  ///
  /// This *must* be incremented in the exact same methods that the visitor in
  /// view_builder.dart appends to [CompileView.nodes].
  int _nodeIndex = 0;
  _ViewBinderVisitor(this.view);

  @override
  void visitBoundText(BoundTextAst ast, _) {
    var node = view.nodes[_nodeIndex++];
    if (node == null) {
      // The node was never added in ViewBuilder since it
      // is dead code.
      return;
    }
    bindRenderText(
        convertToBinding(ast, compileDirectiveMetadata: view.component),
        node,
        view);
  }

  @override
  void visitText(TextAst ast, _) {
    _nodeIndex++;
  }

  @override
  void visitNgContainer(NgContainerAst ast, _) {
    templateVisitAll(this, ast.children, null);
  }

  @override
  void visitElement(ElementAst ast, _) {
    var element = convertElement(
        ast, view.nodes[_nodeIndex++] as CompileElement, view.component);
    var compileElement = element.compileElement!;

    bindRenderInputs(element.inputs, compileElement);
    bindRenderOutputs(element.outputs, compileElement);

    for (var directive in element.matchedDirectives) {
      bindDirectiveInputs(
        directive.inputs,
        directive,
        compileElement,
        isHostComponent: compileElement.view!.viewType == ViewType.host,
      );
      bindDirectiveDetectChangesLifecycleCallbacks(directive, compileElement);
      bindDirectiveHostProps(directive, compileElement);
      bindDirectiveOutputs(
          directive.outputs, directive.providerSource!, compileElement);
    }
    templateVisitAll(this, element.parsedTemplate, null);
    // afterContent and afterView lifecycles need to be called bottom up
    // so that children are notified before parents
    for (var directive in element.matchedDirectives) {
      bindDirectiveAfterChildrenCallbacks(directive, compileElement);
    }
  }

  @override
  void visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    var element = convertEmbeddedTemplate(
        ast, view.nodes[_nodeIndex++] as CompileElement, view.component);
    var compileElement = element.compileElement!;
    for (var directive in element.matchedDirectives) {
      bindDirectiveInputs(directive.inputs, directive, compileElement);
      bindDirectiveDetectChangesLifecycleCallbacks(directive, compileElement);
      bindDirectiveOutputs(
          directive.outputs, directive.providerSource!, compileElement);
      bindDirectiveAfterChildrenCallbacks(directive, compileElement);
    }
    var embeddedView = element.children.first as ir.EmbeddedView;
    bindView(embeddedView, null, bindHostProperties: false);
  }

  @override
  void visitI18nText(I18nTextAst ast, _) {
    _nodeIndex++;
  }

  @override
  void visitEvent(BoundEventAst ast, _) {}

  @override
  void visitNgContent(NgContentAst ast, _) {
    if (ast.reference != null) {
      _nodeIndex++;
    }
  }

  @override
  void visitAttr(AttrAst ast, _) {}

  @override
  void visitDirective(DirectiveAst ast, _) {}

  @override
  void visitReference(ReferenceAst ast, _) {}

  @override
  void visitVariable(VariableAst ast, _) {}

  @override
  void visitDirectiveProperty(BoundDirectivePropertyAst ast, _) {}

  @override
  void visitDirectiveEvent(BoundDirectiveEventAst ast, _) {}

  @override
  void visitElementProperty(BoundElementPropertyAst ast, _) {}

  @override
  void visitProvider(ProviderAst ast, _) {}
}

void _bindViewHostProperties(
    CompileView view, ElementSchemaRegistry schemaRegistry) {
  if (view.viewIndex != 0 || view.viewType != ViewType.component) return;
  var hostProps = view.component.hostProperties;
  var hostProperties = <BoundElementPropertyAst>[];

  var span = SourceSpan(SourceLocation(0), SourceLocation(0), '');
  hostProps.forEach((String propName, ast.AST expression) {
    var elementName = view.component.selector!;
    hostProperties.add(createElementPropertyAst(
      elementName,
      propName,
      BoundExpression(ast.ASTWithSource.missingSource(expression)),
      span,
      schemaRegistry,
    ));
  });

  final method = CompileMethod();
  final compileElement = view.componentView.declarationElement;
  final renderNode = view.componentView.declarationElement.renderNode;
  final converter = BoundValueConverter.forView(view);
  bindAndWriteToRenderer(
    convertAllToBinding(
      hostProperties,
      compileDirectiveMetadata: view.component,
      compileElement: compileElement,
    ),
    converter,
    o.THIS_EXPR,
    renderNode,
    compileElement.isHtmlElement,
    view.nameResolver,
    view.storage,
    method,
  );
  if (method.isNotEmpty) {
    view.detectHostChangesMethod = method;
  }
}
