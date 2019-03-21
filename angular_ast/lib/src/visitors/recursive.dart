// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../ast.dart';
import '../visitor.dart';

/// An [TemplateAstVisitor] that recursively visits all children of an AST node,
/// in addition to itself.
///
/// Note that methods may modify values.
class RecursiveTemplateAstVisitor<C>
    implements TemplateAstVisitor<TemplateAst, C> {
  @literal
  const RecursiveTemplateAstVisitor();

  /// Visits a collection of [TemplateAst] nodes, returning all of those that
  /// are not null.
  List<T> visitAll<T extends TemplateAst>(Iterable<T> astNodes, [C context]) {
    if (astNodes == null) return null;

    final results = <T>[];
    for (final astNode in astNodes) {
      var value = visit(astNode, context);
      if (value != null) {
        results.add(value);
      }
    }
    return results;
  }

  /// Visits a single [TemplateAst] node, capturing the type.
  T visit<T extends TemplateAst>(T astNode, [C context]) =>
      astNode?.accept(this, context) as T;

  @override
  TemplateAst visitAnnotation(AnnotationAst astNode, [_]) => astNode;

  @override
  @mustCallSuper
  TemplateAst visitAttribute(AttributeAst astNode, [C context]) =>
      AttributeAst.from(
        astNode,
        astNode.name,
        astNode.value,
        visitAll(astNode.mustaches, context),
      );

  @override
  TemplateAst visitBanana(BananaAst astNode, [_]) => astNode;

  @override
  TemplateAst visitCloseElement(CloseElementAst astNode, [_]) => astNode;

  @override
  TemplateAst visitComment(CommentAst astNode, [_]) => astNode;

  @override
  @mustCallSuper
  TemplateAst visitContainer(ContainerAst astNode, [C context]) =>
      ContainerAst.from(
        astNode,
        annotations: visitAll(astNode.annotations, context),
        childNodes: visitAll(astNode.childNodes, context),
        stars: visitAll(astNode.stars, context),
      );

  @override
  TemplateAst visitEmbeddedContent(EmbeddedContentAst astNode, [_]) => astNode;

  @override
  @mustCallSuper
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [C context]) =>
      EmbeddedTemplateAst.from(
        astNode,
        annotations: visitAll(astNode.annotations, context),
        attributes: visitAll(astNode.attributes, context),
        childNodes: visitAll(astNode.childNodes, context),
        events: visitAll(astNode.events, context),
        properties: visitAll(astNode.properties, context),
        references: visitAll(astNode.references, context),
        letBindings: visitAll(astNode.letBindings, context),
        hasDeferredComponent: astNode.hasDeferredComponent,
      );

  @override
  @mustCallSuper
  TemplateAst visitElement(ElementAst astNode, [C context]) => ElementAst.from(
        astNode,
        astNode.name,
        visit(astNode.closeComplement),
        attributes: visitAll(astNode.attributes, context),
        childNodes: visitAll(astNode.childNodes, context),
        events: visitAll(astNode.events, context),
        properties: visitAll(astNode.properties, context),
        references: visitAll(astNode.references, context),
        bananas: visitAll(astNode.bananas, context),
        stars: visitAll(astNode.stars, context),
        annotations: visitAll(astNode.annotations, context),
      );

  @override
  @mustCallSuper
  TemplateAst visitEvent(EventAst astNode, [C context]) => EventAst.from(
        astNode,
        astNode.name,
        astNode.value,
        visit(astNode.expression),
        astNode.reductions,
      );

  @override
  TemplateAst visitExpression(ExpressionAst<Object> astNode, [_]) => astNode;

  @override
  @mustCallSuper
  TemplateAst visitInterpolation(InterpolationAst astNode, [_]) =>
      InterpolationAst.from(
        astNode,
        astNode.value,
        visit(astNode.expression),
      );

  @override
  TemplateAst visitLetBinding(LetBindingAst astNode, [_]) => astNode;

  @override
  @mustCallSuper
  TemplateAst visitProperty(PropertyAst astNode, [_]) => PropertyAst.from(
        astNode,
        astNode.name,
        astNode.value,
        visit(astNode.expression),
        astNode.postfix,
        astNode.unit,
      );

  @override
  TemplateAst visitReference(ReferenceAst astNode, [_]) => astNode;

  @override
  TemplateAst visitStar(StarAst astNode, [_]) => astNode;

  @override
  TemplateAst visitText(TextAst astNode, [_]) => astNode;
}
