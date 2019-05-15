// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../visitor.dart';

/// Provides a human-readable view of a template AST tree.
class HumanizingTemplateAstVisitor
    extends TemplateAstVisitor<String, StringBuffer> {
  const HumanizingTemplateAstVisitor();

  @override
  String visitAnnotation(AnnotationAst astNode, [_]) => '@${astNode.name}';

  @override
  String visitAttribute(AttributeAst astNode, [_]) {
    if (astNode.value != null) {
      return '${astNode.name}="${astNode.value}"';
    } else {
      return '${astNode.name}';
    }
  }

  @override
  String visitBanana(BananaAst astNode, [_]) {
    var name = '[(${astNode.name})]';
    if (astNode.value != null) {
      return '$name="${astNode.value}"';
    } else {
      return name;
    }
  }

  @override
  String visitCloseElement(CloseElementAst astNode, [StringBuffer context]) {
    context ??= StringBuffer();
    context..write('</')..write(astNode.name)..write('>');
    return context.toString();
  }

  @override
  String visitComment(CommentAst astNode, [_]) {
    return '<!--${astNode.value}-->';
  }

  @override
  String visitContainer(ContainerAst astNode, [StringBuffer context]) {
    context ??= StringBuffer();
    context.write('<ng-container');
    if (astNode.annotations.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.annotations.map(visitAnnotation), ' ');
    }
    if (astNode.stars.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.stars.map(visitStar), ' ');
    }
    context.write('>');
    if (astNode.childNodes.isNotEmpty) {
      context.writeAll(astNode.childNodes.map((c) => c.accept(this)));
    }
    context.write('</ng-container>');
    return context.toString();
  }

  @override
  String visitElement(ElementAst astNode, [StringBuffer context]) {
    context ??= StringBuffer();
    context..write('<')..write(astNode.name);
    if (astNode.annotations.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.annotations.map(visitAnnotation), ' ');
    }
    if (astNode.attributes.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.attributes.map(visitAttribute), ' ');
    }
    if (astNode.events.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.events.map(visitEvent), ' ');
    }
    if (astNode.properties.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.properties.map(visitProperty), ' ');
    }
    if (astNode.references.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.references.map(visitReference), ' ');
    }
    if (astNode.bananas.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.bananas.map(visitBanana), ' ');
    }
    if (astNode.stars.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.stars.map(visitStar), ' ');
    }

    if (astNode.isSynthetic) {
      context.write(astNode.isVoidElement ? '/>' : '>');
    } else {
      context.write(astNode.endToken.lexeme);
    }

    if (astNode.childNodes.isNotEmpty) {
      context.writeAll(astNode.childNodes.map((c) => c.accept(this)));
    }
    if (astNode.closeComplement != null) {
      context.write(visitCloseElement(astNode.closeComplement));
    }
    return context.toString();
  }

  @override
  String visitEmbeddedContent(
    EmbeddedContentAst astNode, [
    StringBuffer context,
  ]) {
    context ??= StringBuffer();
    if (astNode.selector != null) {
      context.write('<ng-content select="${astNode.selector}">');
    } else {
      context.write('<ng-content>');
    }
    context.write('</ng-content>');
    return context.toString();
  }

  @override
  String visitEmbeddedTemplate(
    EmbeddedTemplateAst astNode, [
    StringBuffer context,
  ]) {
    context ??= StringBuffer();
    context.write('<template');
    if (astNode.annotations.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.annotations.map(visitAnnotation), ' ');
    }
    if (astNode.attributes.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.attributes.map(visitAttribute), ' ');
    }
    if (astNode.properties.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.properties.map(visitProperty), ' ');
    }
    if (astNode.references.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.references.map(visitReference), ' ');
    }
    if (astNode.letBindings.isNotEmpty) {
      context
        ..write(' ')
        ..writeAll(astNode.letBindings.map(visitLetBinding), ' ');
    }
    context.write('>');
    if (astNode.childNodes.isNotEmpty) {
      context.writeAll(astNode.childNodes.map((c) => c.accept(this)));
    }
    context.write('</template>');
    return context.toString();
  }

  @override
  String visitEvent(EventAst astNode, [StringBuffer context]) {
    context ??= StringBuffer();
    context.write('(${astNode.name}');
    if (astNode.reductions.isNotEmpty) {
      context.write('.${astNode.reductions.join(".")}');
    }
    context.write(')');
    if (astNode.value != null) {
      context.write('="${astNode.value}"');
    }
    return context.toString();
  }

  @override
  String visitExpression(ExpressionAst<Object> astNode, [_]) {
    // TODO: Restore once we have a working expression parser in this package.
    return '';
  }

  @override
  String visitInterpolation(InterpolationAst astNode, [_]) {
    return '{{${astNode.value}}}';
  }

  @override
  String visitLetBinding(LetBindingAst astNode, [_]) {
    if (astNode.value == null) {
      return 'let-${astNode.name}';
    }
    return 'let-${astNode.name}="${astNode.value}"';
  }

  @override
  String visitProperty(PropertyAst astNode, [StringBuffer context]) {
    context ??= StringBuffer();
    context.write('[${astNode.name}');
    if (astNode.postfix != null) {
      context.write('.${astNode.postfix}');
    }
    if (astNode.unit != null) {
      context.write('.${astNode.unit}');
    }
    context.write(']');
    if (astNode.value != null) {
      context.write('="${astNode.value}"');
    }
    return context.toString();
  }

  @override
  String visitReference(ReferenceAst astNode, [_]) {
    var identifier = '#${astNode.identifier}';
    if (astNode.variable != null) {
      return '$identifier="${astNode.variable}"';
    } else {
      return identifier;
    }
  }

  @override
  String visitStar(StarAst astNode, [_]) {
    var name = '*${astNode.name}';
    if (astNode.value != null) {
      return '$name="${astNode.value}"';
    } else {
      return name;
    }
  }

  @override
  String visitText(TextAst astNode, [_]) => astNode.value;
}
