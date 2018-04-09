// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../exception_handler/exception_handler.dart';
import '../expression/micro.dart';
import '../visitor.dart';

/// A visitor that desugars banana and template nodes
/// within a given AST. Ignores non-desugarable nodes.
/// This modifies the structure, and the original version of
/// each desugared node can be accessed by 'origin'.
class DesugarVisitor implements TemplateAstVisitor<TemplateAst, String> {
  final bool _toolFriendlyAstOrigin;
  final ExceptionHandler exceptionHandler;

  DesugarVisitor({
    bool toolFriendlyAstOrigin: false,
    ExceptionHandler exceptionHandler,
  })  : exceptionHandler = exceptionHandler ?? new ThrowingExceptionHandler(),
        _toolFriendlyAstOrigin = toolFriendlyAstOrigin;

  @override
  TemplateAst visitAnnotation(AnnotationAst astNode, [_]) => astNode;

  @override
  TemplateAst visitAttribute(AttributeAst astNode, [_]) => astNode;

  @override
  TemplateAst visitBanana(BananaAst astNode, [String flag]) {
    var origin = _toolFriendlyAstOrigin ? astNode : null;

    var appendedValue = (flag == 'event') ? ' = \$event' : '';
    if (astNode.value != null) {
      if (flag == 'event') {
        return new EventAst.from(
          origin,
          astNode.name + 'Change',
          astNode.value + appendedValue,
        );
      }
      if (flag == 'property') {
        return new PropertyAst.from(
          origin,
          astNode.name,
          astNode.value,
        );
      }
    }

    return astNode;
  }

  @override
  TemplateAst visitCloseElement(CloseElementAst astNode, [_]) => astNode;

  @override
  TemplateAst visitComment(CommentAst astNode, [_]) => astNode;

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) {
    _visitChildren(astNode);

    if (astNode.bananas.isNotEmpty) {
      for (BananaAst bananaAst in astNode.bananas) {
        var toAddEvent = visitBanana(bananaAst, 'event');
        astNode.events.add(toAddEvent);

        var toAddProperty = visitBanana(bananaAst, 'property');
        astNode.properties.add(toAddProperty);
      }
      astNode.bananas.clear();
    }

    if (astNode.stars.isNotEmpty) {
      var starAst = astNode.stars[0];
      var origin = _toolFriendlyAstOrigin ? starAst : null;
      var starExpression = starAst.value;
      var expressionOffset =
          (starAst as ParsedStarAst).valueToken?.innerValue?.offset;
      var directiveName = starAst.name;
      EmbeddedTemplateAst newAst;
      var attributesToAdd = <AttributeAst>[];
      var propertiesToAdd = <PropertyAst>[];
      var letBindingsToAdd = <LetBindingAst>[];

      if (isMicroExpression(starExpression)) {
        NgMicroAst micro;
        try {
          micro = parseMicroExpression(
            directiveName,
            starExpression,
            expressionOffset,
            sourceUrl: astNode.sourceUrl,
            origin: origin,
          );
        } catch (e) {
          exceptionHandler.handle(e);
          return astNode;
        }
        if (micro != null) {
          propertiesToAdd.addAll(micro.properties);
          letBindingsToAdd.addAll(micro.letBindings);
        }
        // If the micro-syntax did not produce a binding to the left-hand side
        // property, add it as an attribute in case a directive selector
        // depends on it.
        if (!propertiesToAdd.any((p) => p.name == directiveName)) {
          attributesToAdd.add(new AttributeAst.from(origin, directiveName));
        }
        newAst = new EmbeddedTemplateAst.from(
          origin,
          childNodes: [
            astNode,
          ],
          attributes: attributesToAdd,
          properties: propertiesToAdd,
          letBindings: letBindingsToAdd,
        );
      } else {
        propertiesToAdd.add(new PropertyAst.from(
          origin,
          directiveName,
          starExpression,
        ));
        newAst = new EmbeddedTemplateAst.from(
          origin,
          childNodes: [
            astNode,
          ],
          properties: propertiesToAdd,
        );
      }

      astNode.stars.clear();
      return newAst;
    }

    if (astNode.annotations.isNotEmpty) {
      var annotationAst = astNode.annotations[0];
      var origin = _toolFriendlyAstOrigin ? annotationAst : null;
      var directiveName = annotationAst.name;
      if (directiveName == 'deferred') {
        astNode.annotations.clear();
        return new EmbeddedTemplateAst.from(origin,
            childNodes: [astNode], hasDeferredComponent: true);
      }
    }

    return astNode;
  }

  void _visitChildren(TemplateAst astNode) {
    if (astNode.childNodes.isEmpty) return;
    var newChildren = <StandaloneTemplateAst>[];
    astNode.childNodes.forEach((child) {
      newChildren.add(child.accept(this) as StandaloneTemplateAst);
    });
    astNode.childNodes.clear();
    astNode.childNodes.addAll(newChildren);
  }

  @override
  TemplateAst visitEmbeddedContent(EmbeddedContentAst astNode, [_]) => astNode;

  @override
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) {
    _visitChildren(astNode);
    return astNode;
  }

  @override
  TemplateAst visitEvent(EventAst astNode, [_]) => astNode;

  @override
  TemplateAst visitExpression(ExpressionAst astNode, [_]) => astNode;

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
