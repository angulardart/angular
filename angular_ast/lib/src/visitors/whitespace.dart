// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    TemplateAst nextNode;
    for (var i = 0, l = childNodes.length; i < l; i++) {
      var currentNode = childNodes[i];

      if (prevNode is! InterpolationAst &&
          nextNode is! InterpolationAst &&
          currentNode is TextAst &&
          currentNode.value.trim().isEmpty) {
        currentNode = childNodes[i] = null;
      }

      prevNode = currentNode;
      nextNode = i < l - 1 ? childNodes[i + 1] : null;
    }

    // Remove any nodes that were removed by processing.
    return childNodes.where((a) => a != null).toList();
  }
}
