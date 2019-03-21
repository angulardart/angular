// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../ast.dart';
import '../visitor.dart';

/// An [TemplateAstVisitor] that does nothing but return the AST node back.
class IdentityTemplateAstVisitor<C>
    implements TemplateAstVisitor<TemplateAst, C> {
  @literal
  const IdentityTemplateAstVisitor();

  @override
  TemplateAst visitAnnotation(AnnotationAst astNode, [_]) => astNode;

  @override
  TemplateAst visitAttribute(AttributeAst astNode, [_]) => astNode;

  @override
  TemplateAst visitBanana(BananaAst astNode, [_]) => astNode;

  @override
  TemplateAst visitCloseElement(CloseElementAst astNode, [_]) => astNode;

  @override
  TemplateAst visitComment(CommentAst astNode, [_]) => astNode;

  @override
  TemplateAst visitContainer(ContainerAst astNode, [_]) => astNode;

  @override
  TemplateAst visitEmbeddedContent(EmbeddedContentAst astNode, [_]) => astNode;

  @override
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) =>
      astNode;

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) => astNode;

  @override
  TemplateAst visitEvent(EventAst astNode, [_]) => astNode;

  @override
  TemplateAst visitExpression(ExpressionAst<Object> astNode, [_]) => astNode;

  @override
  TemplateAst visitInterpolation(InterpolationAst astNode, [_]) => astNode;

  @override
  TemplateAst visitLetBinding(LetBindingAst astNode, [_]) => astNode;

  @override
  TemplateAst visitProperty(PropertyAst astNode, [_]) => astNode;

  @override
  TemplateAst visitReference(ReferenceAst astNode, [_]) => astNode;

  @override
  TemplateAst visitStar(StarAst astNode, [_]) => astNode;

  @override
  TemplateAst visitText(TextAst astNode, [_]) => astNode;
}
