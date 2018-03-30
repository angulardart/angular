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
  const MinimizeWhitespaceVisitor();

  /// Returns [rootNodes], visited, with whitespace removed.
  List<StandaloneTemplateAst> visitAllRoot(
          List<StandaloneTemplateAst> rootNodes) =>
      visitAll(_visitRemovingWhitespace(rootNodes));

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) {
    if (astNode.childNodes.isNotEmpty) {
      astNode = new ElementAst.from(
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
    if (astNode.childNodes.isNotEmpty) {
      astNode = new EmbeddedTemplateAst.from(
        astNode,
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
    print('>>> visitText($astNode)');
    return new TextAst.from(
      astNode,
      astNode.value.replaceAll(_manualWhitespace, ' '),
    );
  }

  /// Returns [text], with all significant whitespace reduced to a single space.
  static TextAst _collapseWhitespace(
    TextAst text, {
    @required bool trimLeft,
    @required bool trimRight,
  }) {
    // Collapses all adjacent whitespace into a single space.
    var value = text.value.replaceAll(_allWhitespace, ' ');
    if (trimLeft) {
      value = value.trimLeft();
    }
    if (trimRight) {
      value = value.trimRight();
    }
    if (value.isEmpty) {
      return null;
    }
    return new TextAst.from(text, value);
  }

  static final _allWhitespace = new RegExp(r'\s\s+', multiLine: true);
  static const _ngsp = '\uE500';

  // TODO: Add &#32;
  static final _manualWhitespace = new RegExp('$_ngsp', multiLine: true);

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
        if (prevNode is! InterpolationAst &&
            nextNode is! InterpolationAst &&
            currentNodeCasted.value.trim().isEmpty) {
          currentNode = null;
        } else {
          // Otherwise, we collapse whitespace:
          // 1. All adjacent whitespace is collapsed into a single space.
          // 2. Depending on siblings, *also* trimLeft or trimRight.
          currentNode = _collapseWhitespace(
            currentNode,
            trimLeft: prevNode is! InterpolationAst,
            trimRight: nextNode is! InterpolationAst,
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
}
