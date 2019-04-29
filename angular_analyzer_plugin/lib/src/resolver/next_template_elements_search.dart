import 'package:angular_analyzer_plugin/ast.dart';

/// Find the immediately nested scopes within an [ElementInfo].
///
/// ```html
/// <div> <!-- begin visiting here -->
///   <div *ngIf="bar">
///     <!-- Immediate inner scope 1, added to [results]. -->
///
///     <div *ngIf="baz">
///       <!-- Non-immediate inner scope, skipped. -->
///     </div>
///   </div>
///
///   <template>
///     <!-- Immediate inner scope 2, added to [results]. -->
///   </template>
///
///   <div>
///     <!-- Not a new scope. Keep searching. -->
///
///     <div *ngIf="baz">
///       <!-- Immediate inner scope 3, added to [results]. -->
///     </div>
///   </div>
///
/// </div>
/// ```
///
/// Note that we specially track where we begin the search. Otherwise in the
/// following example, our search would simply return the root node.
///
/// ```html
/// <div *ngIf="foo"> <!-- begin visiting here -->
///   <!-- ... -->
/// </div>
/// ```
class NextTemplateElementsSearch extends AngularAstVisitor {
  bool visitingRoot = true;

  final results = <ElementInfo>[];

  @override
  void visitDocumentInfo(DocumentInfo document) {
    visitingRoot = false;
    for (final child in document.childNodes) {
      child.accept(this);
    }
  }

  @override
  void visitElementInfo(ElementInfo element) {
    if (element.isOrHasTemplateAttribute && !visitingRoot) {
      results.add(element);
      return;
    }

    visitingRoot = false;
    for (final child in element.childNodes) {
      child.accept(this);
    }
  }
}
