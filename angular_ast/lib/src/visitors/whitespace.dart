// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../ast.dart';
import 'recursive.dart';

/// Applies whitespace reduction to implement (`preserveWhitespace: false`).
///
/// Use [visitAllRoot] to process root nodes:
/// ```dart
/// var nodes = parse(template, sourceUrl: url);
/// nodes = const MinimizeWhitespaceVisitor().visitAllRoot(nodes);
/// ```
class MinimizeWhitespaceVisitor extends RecursiveTemplateAstVisitor<bool> {
  static bool _bailOutToPreserveWhitespace(StandaloneTemplateAst astNode) {
    List<AnnotationAst> annotations = const [];
    // TOOD(https://github.com/dart-lang/angular/issues/1460): Refactor.
    if (astNode is ContainerAst) {
      annotations = astNode.annotations;
    } else if (astNode is ElementAst) {
      if (astNode.name == 'pre') {
        // Don't modify whitespace of preformatted text.
        return true;
      }
      annotations = astNode.annotations;
    } else if (astNode is EmbeddedTemplateAst) {
      annotations = astNode.annotations;
    }
    for (final annotation in annotations) {
      if (annotation.name == 'preserveWhitespace') {
        return true;
      }
    }
    return false;
  }

  const MinimizeWhitespaceVisitor();

  /// Returns [rootNodes], visited, with whitespace removed.
  List<StandaloneTemplateAst> visitAllRoot(
          List<StandaloneTemplateAst> rootNodes) =>
      visitAll(_visitRemovingWhitespace(rootNodes));

  @override
  TemplateAst visitContainer(ContainerAst astNode, [_]) {
    if (_bailOutToPreserveWhitespace(astNode)) {
      return astNode;
    }
    if (astNode.childNodes.isNotEmpty) {
      astNode = ContainerAst.from(
        astNode,
        annotations: astNode.annotations,
        childNodes: _visitRemovingWhitespace(astNode.childNodes),
        stars: astNode.stars,
      );
    }
    return super.visitContainer(astNode, true);
  }

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) {
    if (_bailOutToPreserveWhitespace(astNode)) {
      return astNode;
    }
    if (astNode.childNodes.isNotEmpty) {
      astNode = ElementAst.from(
        astNode,
        astNode.name,
        astNode.closeComplement,
        attributes: astNode.attributes,
        childNodes: _visitRemovingWhitespace(astNode.childNodes),
        events: astNode.events,
        properties: astNode.properties,
        references: astNode.references,
        bananas: astNode.bananas,
        stars: astNode.stars,
        annotations: astNode.annotations,
      );
    }
    return super.visitElement(astNode, true);
  }

  @override
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) {
    if (_bailOutToPreserveWhitespace(astNode)) {
      return astNode;
    }
    if (astNode.childNodes.isNotEmpty) {
      astNode = EmbeddedTemplateAst.from(
        astNode,
        annotations: astNode.annotations,
        attributes: astNode.attributes,
        childNodes: _visitRemovingWhitespace(astNode.childNodes),
        events: astNode.events,
        properties: astNode.properties,
        references: astNode.references,
        letBindings: astNode.letBindings,
        hasDeferredComponent: astNode.hasDeferredComponent,
      );
    }
    return super.visitEmbeddedTemplate(astNode, true);
  }

  @override
  TemplateAst visitText(TextAst astNode, [_]) {
    return TextAst.from(
      astNode,
      astNode.value.replaceAll(_ngsp, ' '),
    );
  }

  /// Returns [text], with all significant whitespace reduced to a single space.
  static TextAst _collapseWhitespace(
    TextAst text, {
    @required bool trimLeft,
    @required bool trimRight,
  }) {
    // Collapses all adjacent whitespace into a single space.
    const preserveNbsp = '\uE501';
    var value = text.value.replaceAll(_nbsp, preserveNbsp);
    value = value.replaceAll(_allWhitespace, ' ');
    if (trimLeft) {
      value = value.trimLeft();
    }
    if (trimRight) {
      value = value.trimRight();
    }
    value = value.replaceAll(preserveNbsp, _nbsp);
    if (value.isEmpty) {
      return null;
    }
    return TextAst.from(text, value);
  }

  static final _allWhitespace = RegExp(r'\s\s+', multiLine: true);
  static const _nbsp = '\u00A0';
  static const _ngsp = '\uE500';

  List<StandaloneTemplateAst> _visitRemovingWhitespace(
    List<StandaloneTemplateAst> childNodes,
  ) {
    // 1. Remove whitespace-only text nodes where previous/after nodes are
    //    not an InterpolationAst, but are anything else. For example, in the
    //    following case:
    //
    // <div>
    //   <span>Hello World</span>
    // </div>
    //
    // ... we should collapse to "<div><span>Hello World</span></div>".
    TemplateAst prevNode;
    TemplateAst nextNode = childNodes.length > 1 ? childNodes[1] : null;
    for (var i = 0, l = childNodes.length; i < l; i++) {
      var currentNode = childNodes[i];

      if (currentNode is TextAst) {
        // This is because the re-assignment (currentNode =) below disables the
        // type promotion, but we want everywhere in this if (...) { ... } block
        // to assume it is a TextAst at this point.
        final TextAst currentNodeCasted = currentNode;

        // Node i, where i - 1 and i + 1 are not interpolations, we can
        // completely remove the (text) node. For example, this would take
        // `<span>\n</span>` and return `<span></span>`.
        if (_shouldCollapseAdjacentTo(prevNode, lastNode: true) &&
            _shouldCollapseAdjacentTo(nextNode, lastNode: false) &&
            currentNodeCasted.value.trim().isEmpty &&
            !currentNodeCasted.value.contains(_nbsp)) {
          currentNode = null;
        } else {
          // Otherwise, we collapse whitespace:
          // 1. All adjacent whitespace is collapsed into a single space.
          // 2. Depending on siblings, *also* trimLeft or trimRight.
          currentNode = _collapseWhitespace(
            currentNode,
            trimLeft: _shouldCollapseAdjacentTo(prevNode, lastNode: true),
            trimRight: _shouldCollapseAdjacentTo(nextNode, lastNode: false),
          );
        }

        childNodes[i] = currentNode;
      }

      prevNode = currentNode;
      nextNode = i < l - 2 ? childNodes[i + 2] : null;
    }

    // Remove any nodes that were removed by processing.
    return childNodes.where((a) => a != null).toList();
  }

  // https://developer.mozilla.org/en-US/docs/Web/HTML/Inline_elements
  static final _commonInlineElements = <String>{
    'a',
    'abbr',
    'acronym',
    'b',
    'bdo',
    'big',
    'br',
    'button',
    'cite',
    'code',
    'dfn',
    'em',
    'i',
    'img',
    'input',
    'kbd',
    'label',
    'map',
    'object',
    'q',
    'samp',
    'script',
    'select',
    'small',
    'span',
    'strong',
    'sub',
    'sup',
    'textarea',
    'time',
    'tt',
    'var',
  };

  /// Returns whether [tagName] is normally an `display: inline` element.
  ///
  /// This helps to make the right (default) decision around whitespace.
  static bool _isPotentiallyInline(ElementAst astNode) =>
      _commonInlineElements.contains(astNode.name.toLowerCase());

  /// Whether [astNode] should be treated as insignficant to nearby whitespace.
  static bool _shouldCollapseAdjacentTo(
    TemplateAst astNode, {
    bool lastNode = false,
  }) =>
      // Always collpase adjacent to a non-element-like node.
      astNode is! StandaloneTemplateAst ||
      // Sometimes collapse adjacent to another element if not inline.
      astNode is ElementAst && !_isPotentiallyInline(astNode) ||
      // Sometimes collapse adjacent to a template or container node.
      _shouldCollapseWrapperNode(astNode, lastNode: lastNode);

  // Determining how to collapse next to a template/container is more complex.
  //
  // If the <template> wraps HTML DOM, i.e. <div *ngIf>, we should just use the
  // immediate wrapped DOM node as the indicator of collapsing. <div *ngIf>
  // should be treated just like a <div>.
  //
  // Otherwise, return `false` and assume it could be a source of inline nodes.
  static bool _shouldCollapseWrapperNode(
    StandaloneTemplateAst astNode, {
    bool lastNode = false,
  }) {
    if (astNode is! ContainerAst && astNode is! EmbeddedTemplateAst) {
      return false;
    }
    final nodes = astNode.childNodes;
    if (nodes.isNotEmpty) {
      var checkChild = lastNode ? nodes.last : nodes.first;
      // Cover the corner case of:
      // <template [ngIf]>
      //   <span>Hello</span>
      // </template>
      //
      // The immediate child of <template> (in either direction) is a TextAst,
      // but it is just whitespace, so we want to consider the next relevant
      // node.
      //
      // TODO(matanl): Refactor this entire function after feature submitted.
      if (checkChild is TextAst && checkChild.value.trim().isEmpty) {
        if (nodes.length == 1) {
          // Another corner-corner case:
          //
          // <template [ngIf]>
          //   <div>
          //     Dynamic Content:
          //     <template>
          //     </template>
          //   </div>
          // </template>
          //
          // We want to assume the inner-template will be modified dynamically
          // at runtime (content inserted), so we assume inline instead of
          // assuming block, hence returning false.
          return false;
        }
        checkChild = lastNode ? nodes[nodes.length - 2] : nodes[1];
      }
      return _shouldCollapseAdjacentTo(checkChild);
    }
    return false;
  }
}
