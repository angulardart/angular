import 'package:angular_ast/src/ast.dart';
import 'package:angular_ast/src/visitor.dart';

class ThrowingTemplateAstVisitor<R, C> implements TemplateAstVisitor<R, C> {
  @override
  R visitAnnotation(AnnotationAst astNode, [C context]) {
    throw UnsupportedError('visiting AnnotationAst not supported');
  }

  @override
  R visitAttribute(AttributeAst astNode, [C context]) {
    throw UnsupportedError('visiting AttributeAst not supported');
  }

  @override
  R visitBanana(BananaAst astNode, [C context]) {
    throw UnsupportedError('visiting BananaAst not supported');
  }

  @override
  R visitCloseElement(CloseElementAst astNode, [C context]) {
    throw UnsupportedError('visiting CloseElementAst not supported');
  }

  @override
  R visitComment(CommentAst astNode, [C context]) {
    throw UnsupportedError('visiting CommentAst not supported');
  }

  @override
  R visitEvent(EventAst astNode, [C context]) {
    throw UnsupportedError('visiting EventAst not supported');
  }

  @override
  R visitExpression(ExpressionAst<Object> astNode, [C context]) {
    throw UnsupportedError('visiting ExpressionAst not supported');
  }

  @override
  R visitLetBinding(LetBindingAst astNode, [C context]) {
    throw UnsupportedError('visiting LetBindingAst not supported');
  }

  @override
  R visitProperty(PropertyAst astNode, [C context]) {
    throw UnsupportedError('visiting PropertyAst not supported');
  }

  @override
  R visitReference(ReferenceAst astNode, [C context]) {
    throw UnsupportedError('visiting ReferenceAst not supported');
  }

  @override
  R visitStar(StarAst astNode, [C context]) {
    throw UnsupportedError('visiting StarAst not supported');
  }

  @override
  visitContainer(ContainerAst astNode, [C context]) {
    throw UnsupportedError('visiting ContainerAst not supported');
  }

  @override
  visitElement(ElementAst astNode, [C context]) {
    throw UnsupportedError('visiting ElementAst not supported');
  }

  @override
  visitEmbeddedContent(EmbeddedContentAst astNode, [C context]) {
    throw UnsupportedError('visiting EmbeddedContentAst not supported');
  }

  @override
  visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [C context]) {
    throw UnsupportedError('visiting EmbeddedTemplateAst not supported');
  }

  @override
  visitInterpolation(InterpolationAst astNode, [C context]) {
    throw UnsupportedError('visiting InterpolationAst not supported');
  }

  @override
  visitText(TextAst astNode, [C context]) {
    throw UnsupportedError('visiting TextAst not supported');
  }
}
