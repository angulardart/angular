import '../ast.dart';
import '../exception_handler/exception_handler.dart';
import '../expression/micro.dart';
import '../visitor.dart';

/// Desugars complex nodes such as `[(banana)]` into simpler forms.
///
/// Ignores non-desugrable nodes. This visitor mutates and returns the AST where
/// the original node can be accessed by [SyntheticTemplateAst.origin].
class DesugarVisitor extends IdentityTemplateAstVisitor<void>
    implements TemplateAstVisitor<TemplateAst, void> {
  final ExceptionHandler exceptionHandler;

  /// Create a new visitor.
  DesugarVisitor({
    ExceptionHandler? exceptionHandler,
  }) : exceptionHandler = exceptionHandler ?? const ThrowingExceptionHandler();

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
    _visitChildren(astNode);
    return astNode;
  }

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
      astNode
        ..events.add(EventAst.from(
          banana,
          '${banana.name}Change',
          '${banana.value} = \$event',
        ))
        ..properties.add(PropertyAst.from(
          banana,
          banana.name,
          banana.value!,
        ));
    }
    astNode.bananas.clear();
  }

  TemplateAst _desugarStar(StandaloneTemplateAst astNode, List<StarAst> stars) {
    var starAst = stars[0];
    var origin = starAst;
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
          sourceUrl: astNode.sourceUrl!,
          origin: origin,
        );
      } on AngularParserException catch (e) {
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
