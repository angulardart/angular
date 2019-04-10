import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/expression_parser/ast.dart'
    as expression_ast;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/template_ast.dart' as ast;
import 'package:angular/src/core/security.dart';
import 'package:angular_compiler/cli.dart';

/// Converts a list of [ast.TemplateAst] nodes into [ir.Binding] instances.
///
/// [AnalyzedClass] is eventually expected for all code paths, but we currently
/// do not have it piped through properly.
///
/// [CompileDirectiveMetadata] should be specified with converting directive
/// inputs that need the underlying directive for context.
List<ir.Binding> convertAllToBinding(
  List<ast.TemplateAst> nodes, {
  AnalyzedClass analyzedClass,
  CompileDirectiveMetadata directive,
}) =>
    ast.templateVisitAll(_ToBindingVisitor(), nodes,
        _IrBindingContext(analyzedClass, directive));

/// Converts a single [ast.TemplateAst] node into an [ir.Binding] instance.
ir.Binding convertToBinding(
        ast.TemplateAst node, AnalyzedClass analyzedClass) =>
    node.visit(_ToBindingVisitor(), _IrBindingContext(analyzedClass, null));

/// Converts a host attribute to an [ir.Binding] instance.
///
/// Currently host attributes are represented as a map from [name] to [value].
// TODO(b/130184376): Create a better HostAttribute representation.
ir.Binding convertHostAttributeToBinding(
        String name, expression_ast.AST value, AnalyzedClass analyzedClass) =>
    ir.Binding(
        source: ir.BoundExpression(value, null, analyzedClass),
        target: _attributeName(name));

class _ToBindingVisitor
    implements ast.TemplateAstVisitor<ir.Binding, _IrBindingContext> {
  @override
  ir.Binding visitText(ast.TextAst ast, _IrBindingContext _) =>
      ir.Binding(source: ir.StringLiteral(ast.value), target: ir.TextBinding());

  @override
  ir.Binding visitI18nText(ast.I18nTextAst ast, _IrBindingContext _) =>
      ir.Binding(
          source: ir.BoundI18nMessage(ast.value),
          target: ast.value.containsHtml ? ir.HtmlBinding() : ir.TextBinding());

  @override
  ir.Binding visitBoundText(ast.BoundTextAst ast, _IrBindingContext context) =>
      ir.Binding(
          source: ir.BoundExpression(
              ast.value, ast.sourceSpan, context.analyzedClass),
          target: ir.TextBinding());

  @override
  ir.Binding visitAttr(ast.AttrAst attr, _IrBindingContext _) => ir.Binding(
      source: _attributeValue(attr.value), target: _attributeName(attr.name));

  ir.BindingSource _attributeValue(ast.AttributeValue<Object> attr) {
    if (attr is ast.LiteralAttributeValue) {
      return ir.StringLiteral(attr.value);
    } else if (attr is ast.I18nAttributeValue) {
      return ir.BoundI18nMessage(attr.value);
    }
    throw ArgumentError.value(
        attr, 'attr', 'Unknown ${ast.AttributeValue} type.');
  }

  @override
  ir.Binding visitElementProperty(
          ast.BoundElementPropertyAst ast, _IrBindingContext context) =>
      ir.Binding(
        source:
            _boundValueToIr(ast.value, ast.sourceSpan, context.analyzedClass),
        target: _propertyToIr(ast),
      );

  ir.BindingTarget _propertyToIr(ast.BoundElementPropertyAst boundProp) {
    switch (boundProp.type) {
      case ast.PropertyBindingType.property:
        if (boundProp.name == 'className') {
          return ir.ClassBinding();
        }
        return ir.PropertyBinding(boundProp.name, boundProp.securityContext);
      case ast.PropertyBindingType.attribute:
        if (boundProp.name == 'class') {
          return ir.ClassBinding();
        }
        return ir.AttributeBinding(boundProp.name,
            namespace: boundProp.namespace,
            isConditional: _isConditionalAttribute(boundProp),
            securityContext: boundProp.securityContext);
      case ast.PropertyBindingType.cssClass:
        return ir.ClassBinding(name: boundProp.name);
      case ast.PropertyBindingType.style:
        return ir.StyleBinding(boundProp.name, boundProp.unit);
    }
    throw ArgumentError.value(
        boundProp.type, 'type', 'Unknown ${ast.PropertyBindingType}');
  }

  bool _isConditionalAttribute(ast.BoundElementPropertyAst boundProp) =>
      boundProp.unit == 'if';

  @override
  ir.Binding visitDirectiveProperty(
          ast.BoundDirectivePropertyAst input, _IrBindingContext context) =>
      ir.Binding(
        source: _boundValueToIr(
            input.value, input.sourceSpan, context.analyzedClass),
        target: ir.InputBinding(
            input.directiveName, _inputType(context.directive, input)),
      );

  o.OutputType _inputType(
      CompileDirectiveMetadata directive, ast.BoundDirectivePropertyAst input) {
    // TODO(alorenzen): Determine if we actually need this special case.
    if (directive.identifier.name == 'NgIf' && input.directiveName == 'ngIf') {
      return o.BOOL_TYPE;
    }
    var inputTypeMeta = directive.inputTypes[input.directiveName];
    return inputTypeMeta != null
        ? o.importType(inputTypeMeta, inputTypeMeta.typeArguments)
        : null;
  }

  ir.BindingSource _boundValueToIr(
    ast.BoundValue value,
    SourceSpan sourceSpan,
    AnalyzedClass analyzedClass,
  ) {
    if (value is ast.BoundExpression) {
      return ir.BoundExpression(value.expression, sourceSpan, analyzedClass);
    } else if (value is ast.BoundI18nMessage) {
      return ir.BoundI18nMessage(value.message);
    }
    throw ArgumentError.value(
        value, 'value', 'Unknown ${ast.BoundValue} type.');
  }

  @override
  ir.Binding visitDirective(ast.DirectiveAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitElement(ast.ElementAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitEmbeddedTemplate(
          ast.EmbeddedTemplateAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitEvent(ast.BoundEventAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitNgContainer(
          ast.NgContainerAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitNgContent(ast.NgContentAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitProvider(
          ast.ProviderAst providerAst, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitReference(ast.ReferenceAst ast, _IrBindingContext context) =>
      throw UnimplementedError();

  @override
  ir.Binding visitVariable(ast.VariableAst ast, _IrBindingContext context) =>
      throw UnimplementedError();
}

class _IrBindingContext {
  final AnalyzedClass analyzedClass;
  final CompileDirectiveMetadata directive;

  _IrBindingContext(this.analyzedClass, this.directive);
}

ir.BindingTarget _attributeName(String name) {
  String attrNs;
  if (name.startsWith('@') && name.contains(':')) {
    var nameParts = name.substring(1).split(':');
    attrNs = nameParts[0];
    name = nameParts[1];
  }
  bool isConditional = false;
  if (name.endsWith('.if')) {
    isConditional = true;
    name = name.substring(0, name.length - 3);
  }
  if (name == 'class') {
    _throwIfConditional(isConditional, name);
    return ir.ClassBinding();
  }
  if (name == 'tabindex' || name == 'tabIndex') {
    _throwIfConditional(isConditional, name);
    return ir.TabIndexBinding();
  }
  return ir.AttributeBinding(name,
      namespace: attrNs,
      isConditional: isConditional,
      securityContext: TemplateSecurityContext.none);
}

void _throwIfConditional(bool isConditional, String name) {
  if (isConditional) {
    // TODO(b/128689252): Move to validation phase.
    throw BuildError('$name.if is not supported');
  }
}
