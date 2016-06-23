library angular2.src.compiler.view_compiler.view_binder;

import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "../template_ast.dart"
    show
        TemplateAst,
        TemplateAstVisitor,
        NgContentAst,
        EmbeddedTemplateAst,
        ElementAst,
        VariableAst,
        BoundEventAst,
        BoundElementPropertyAst,
        AttrAst,
        BoundTextAst,
        TextAst,
        DirectiveAst,
        BoundDirectivePropertyAst,
        templateVisitAll,
        PropertyBindingType,
        ProviderAst;
import "property_binder.dart"
    show
        bindRenderText,
        bindRenderInputs,
        bindDirectiveInputs,
        bindDirectiveHostProps;
import "event_binder.dart"
    show bindRenderOutputs, collectEventListeners, bindDirectiveOutputs;
import "lifecycle_binder.dart"
    show
        bindDirectiveAfterContentLifecycleCallbacks,
        bindDirectiveAfterViewLifecycleCallbacks,
        bindDirectiveDestroyLifecycleCallbacks,
        bindPipeDestroyLifecycleCallbacks,
        bindDirectiveDetectChangesLifecycleCallbacks;
import "compile_view.dart" show CompileView;
import "compile_element.dart" show CompileElement, CompileNode;

void bindView(CompileView view, List<TemplateAst> parsedTemplate) {
  var visitor = new ViewBinderVisitor(view);
  templateVisitAll(visitor, parsedTemplate);
}

class ViewBinderVisitor implements TemplateAstVisitor {
  CompileView view;
  num _nodeIndex = 0;
  ViewBinderVisitor(this.view) {}
  dynamic visitBoundText(BoundTextAst ast, CompileElement parent) {
    var node = this.view.nodes[this._nodeIndex++];
    bindRenderText(ast, node, this.view);
    return null;
  }

  dynamic visitText(TextAst ast, CompileElement parent) {
    this._nodeIndex++;
    return null;
  }

  dynamic visitNgContent(NgContentAst ast, CompileElement parent) {
    return null;
  }

  dynamic visitElement(ElementAst ast, CompileElement parent) {
    var compileElement = (this.view.nodes[this._nodeIndex++] as CompileElement);
    var eventListeners =
        collectEventListeners(ast.outputs, ast.directives, compileElement);
    bindRenderInputs(ast.inputs, compileElement);
    bindRenderOutputs(eventListeners);
    ListWrapper.forEachWithIndex(ast.directives, (directiveAst, index) {
      var directiveInstance = compileElement.directiveInstances[index];
      bindDirectiveInputs(directiveAst, directiveInstance, compileElement);
      bindDirectiveDetectChangesLifecycleCallbacks(
          directiveAst, directiveInstance, compileElement);
      bindDirectiveHostProps(directiveAst, directiveInstance, compileElement);
      bindDirectiveOutputs(directiveAst, directiveInstance, eventListeners);
    });
    templateVisitAll(this, ast.children, compileElement);
    // afterContent and afterView lifecycles need to be called bottom up

    // so that children are notified before parents
    ListWrapper.forEachWithIndex(ast.directives, (directiveAst, index) {
      var directiveInstance = compileElement.directiveInstances[index];
      bindDirectiveAfterContentLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
      bindDirectiveAfterViewLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
      bindDirectiveDestroyLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
    });
    return null;
  }

  dynamic visitEmbeddedTemplate(
      EmbeddedTemplateAst ast, CompileElement parent) {
    var compileElement = (this.view.nodes[this._nodeIndex++] as CompileElement);
    var eventListeners =
        collectEventListeners(ast.outputs, ast.directives, compileElement);
    ListWrapper.forEachWithIndex(ast.directives, (directiveAst, index) {
      var directiveInstance = compileElement.directiveInstances[index];
      bindDirectiveInputs(directiveAst, directiveInstance, compileElement);
      bindDirectiveDetectChangesLifecycleCallbacks(
          directiveAst, directiveInstance, compileElement);
      bindDirectiveOutputs(directiveAst, directiveInstance, eventListeners);
      bindDirectiveAfterContentLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
      bindDirectiveAfterViewLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
      bindDirectiveDestroyLifecycleCallbacks(
          directiveAst.directive, directiveInstance, compileElement);
    });
    bindView(compileElement.embeddedView, ast.children);
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitEvent(
      BoundEventAst ast, Map<String, BoundEventAst> eventTargetAndNames) {
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic ctx) {
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    return null;
  }
}
