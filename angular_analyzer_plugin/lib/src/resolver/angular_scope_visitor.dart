import 'package:angular_analyzer_plugin/ast.dart';

/// A resolve visitor that understands & handles angular scopes.
///
/// Probably the most important visitor to understand in how we process angular
/// templates.
///
/// First its important to note how angular scopes are determined by templates;
/// that's how ngFor adds a variable below. Its also important to note that
/// unlike in most languages, angular template semantics lets you use a variable
/// before its declared, ie `<a>{{b}}</a><p #b></p>` so long as they share a
/// scope. This is more similar to fields than to variables, and requires
/// multiple passes to properly analyze.
///
/// Also note that a `template="..."` or `*foo` attribute both ends a scope and
/// begins it: all the bindings in the attribute are from the old (outer) scope,
/// and yet let-vars (ie. `let x of ...`) add to the new (inner) scope.
///
/// This means we need to have a multiple-pass process, and that means we must
/// consistently follow the correct subtle rules of scoping. This visitor will
/// handle that for you.
///
/// See `README.md` for more information.
///
/// Just don't @override visitElementInfo (or do so carefully), and this visitor
/// naturally walks over all the attributes in scope by what you give it. You
/// can also hook into what happens when it hits the elements by overriding:
///
/// * visitBorderScopeTemplateAttribute(templateAttribute)
/// * visitScopeRootElementWithTemplateAttribute(element)
/// * visitBorderScopeTemplateElement(element)
/// * visitScopeRootTemplateElement(element)
/// * visitElementInScope(element)
///
/// Which should allow you to do specialty things, such as what the
/// [PrepareScopeVisitor] does by using out-of-scope properties to affect the
/// in-scope ones.
class AngularScopeVisitor extends AngularAstVisitor {
  bool visitingRoot = true;

  void visitBorderScopeTemplateAttribute(TemplateAttribute attr) {
    // Border to the next scope. The virtual properties belong here, the real
    // element does not
    visitTemplateAttr(attr);
  }

  void visitBorderScopeTemplateElement(ElementInfo element) {
    // the attributes are in this scope, the children aren't
    for (final attr in element.attributes) {
      attr.accept(this);
    }
  }

  @override
  void visitDocumentInfo(DocumentInfo document) {
    visitingRoot = false;
    visitElementInScope(document);
  }

  @override
  void visitElementInfo(ElementInfo element) {
    final isRoot = visitingRoot;
    visitingRoot = false;
    if (element.templateAttribute != null) {
      if (!isRoot) {
        visitBorderScopeTemplateAttribute(element.templateAttribute);
        return;
      } else {
        visitScopeRootElementWithTemplateAttribute(element);
      }
    } else if (element.isTemplate) {
      if (isRoot) {
        visitScopeRootTemplateElement(element);
      } else {
        visitBorderScopeTemplateElement(element);
      }
    } else {
      visitElementInScope(element);
    }
  }

  void visitElementInScope(ElementInfo element) {
    for (final child in element.children) {
      child.accept(this);
    }
  }

  void visitScopeRootElementWithTemplateAttribute(ElementInfo element) {
    final children =
        element.children.where((child) => child is! TemplateAttribute);
    for (final child in children) {
      child.accept(this);
    }
  }

  void visitScopeRootTemplateElement(ElementInfo element) {
    // the children are in this scope, the template itself is borderlands
    for (var child in element.childNodes) {
      child.accept(this);
    }
  }
}
