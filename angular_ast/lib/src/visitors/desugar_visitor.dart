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
class DesugarVisitor implements TemplateAstVisitor<TemplateAst, void> {
  final bool _toolFriendlyAstOrigin;
  final ExceptionHandler exceptionHandler;

  DesugarVisitor({
    bool toolFriendlyAstOrigin = false,
    ExceptionHandler exceptionHandler,
  })  : exceptionHandler = exceptionHandler ?? const ThrowingExceptionHandler(),
        _toolFriendlyAstOrigin = toolFriendlyAstOrigin;

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
  TemplateAst visitContainer(ContainerAst astNode, [_]) {
    _visitChildren(astNode);

    if (astNode.stars.isNotEmpty) {
      return _desugarStar(astNode, astNode.stars);
    }

    return astNode;
  }

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) {
    _visitChildren(astNode);

    if (astNode.bananas.isNotEmpty) {
      _desugarBananas(astNode);
    }

    if (astNode.annotations.isNotEmpty) {
      final i = astNode.annotations.indexWhere((ast) => ast.name == 'deferred');
      if (i != -1) {
        final deferredAst = astNode.annotations.removeAt(i);
        // Fail on invalid use (i.e. on a <template> tag):
        // (https://github.com/dart-lang/angular/issues/1538)
        if (astNode.stars.isNotEmpty) {
          exceptionHandler.handle(AngularParserException(
            NgParserWarningCode.INVALID_DEFERRED_ON_TEMPLATE,
            deferredAst.sourceSpan.start.offset,
            deferredAst.sourceSpan.length,
          ));
        }
        final origin = _toolFriendlyAstOrigin ? deferredAst : null;
        return EmbeddedTemplateAst.from(
          origin,
          childNodes: [astNode],
          hasDeferredComponent: true,
        );
      }
    }

    if (astNode.stars.isNotEmpty) {
      return _desugarStar(astNode, astNode.stars);
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
    if (astNode.annotations.isNotEmpty) {
      final i = astNode.annotations.indexWhere((ast) => ast.name == 'deferred');
      if (i != -1) {
        final deferredAst = astNode.annotations.removeAt(i);
        // Fail on invalid use (i.e. on a <template> tag):
        // (https://github.com/dart-lang/angular/issues/1538)
        exceptionHandler.handle(AngularParserException(
          NgParserWarningCode.INVALID_DEFERRED_ON_TEMPLATE,
          deferredAst.sourceSpan.start.offset,
          deferredAst.sourceSpan.length,
        ));
      }
    }
    _visitChildren(astNode);
    return astNode;
  }

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

  /// Rewrites each banana on [astNode] as an event, property binding pair.
  ///
  /// For example, the banana binding
  ///
  ///     [(foo)]="bar"
  ///
  /// is rewritten as the property binding
  ///
  ///     [foo]="bar"
  ///
  /// and the event binding
  ///
  ///     (fooChange)="bar = $event"
  ///
  /// This clears any banana bindings from [astNode].
  void _desugarBananas(ElementAst astNode) {
    for (var banana in astNode.bananas) {
      if (banana.value == null) continue;
      var origin = _toolFriendlyAstOrigin ? banana : null;
      astNode
        ..events.add(EventAst.from(
          origin,
          '${banana.name}Change',
          '${banana.value} = \$event',
        ))
        ..properties.add(PropertyAst.from(
          origin,
          banana.name,
          banana.value,
        ));
    }
    astNode.bananas.clear();
  }

  TemplateAst _desugarStar(StandaloneTemplateAst astNode, List<StarAst> stars) {
    var starAst = stars[0];
    var origin = _toolFriendlyAstOrigin ? starAst : null;
    var starExpression = starAst.value?.trim();
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
        attributesToAdd.add(AttributeAst.from(origin, directiveName));
      }
      newAst = EmbeddedTemplateAst.from(
        origin,
        childNodes: [
          astNode,
        ],
        attributes: attributesToAdd,
        properties: propertiesToAdd,
        letBindings: letBindingsToAdd,
      );
    } else {
      if (starExpression == null) {
        // In the rare case the *-binding has no RHS expression, add the LHS
        // as an attribute rather than a property. This allows matching a
        // directive with an attribute selector, but no input of the same
        // name.
        attributesToAdd.add(AttributeAst.from(origin, directiveName));
      } else {
        propertiesToAdd.add(PropertyAst.from(
          origin,
          directiveName,
          starExpression,
        ));
      }
      newAst = EmbeddedTemplateAst.from(
        origin,
        childNodes: [
          astNode,
        ],
        attributes: attributesToAdd,
        properties: propertiesToAdd,
      );
    }

    stars.clear();
    return newAst;
  }
}
