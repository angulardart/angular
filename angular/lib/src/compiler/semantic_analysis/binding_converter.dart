import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/expression_parser/ast.dart'
    as expression_ast;
import 'package:angular/src/compiler/expression_parser/ast.dart';
import 'package:angular/src/compiler/html_events.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/output_ast.dart' as o;
import 'package:angular/src/compiler/security.dart';
import 'package:angular/src/compiler/template_ast.dart' as ast;
import 'package:angular/src/compiler/view_compiler/compile_element.dart';
import 'package:angular/src/compiler/view_compiler/ir/provider_source.dart';
import 'package:angular/src/compiler/view_compiler/parse_utils.dart'
    show HandlerType, handlerTypeFromExpression;
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
  CompileElement compileElement,
}) =>
    ast.templateVisitAll(
      _ToBindingVisitor(),
      nodes,
      _IrBindingContext(analyzedClass, directive, compileElement),
    );

/// Converts a single [ast.TemplateAst] node into an [ir.Binding] instance.
ir.Binding convertToBinding(
        ast.TemplateAst node, AnalyzedClass analyzedClass) =>
    node.visit(
      _ToBindingVisitor(),
      _IrBindingContext(analyzedClass, null, null),
    );

/// Converts a host attribute to an [ir.Binding] instance.
///
/// Currently host attributes are represented as a map from [name] to [value].
// TODO(b/130184376): Create a better HostAttribute representation.
ir.Binding convertHostAttributeToBinding(String name,
        expression_ast.ASTWithSource value, AnalyzedClass analyzedClass) =>
    ir.Binding(
        source: ir.BoundExpression(value, null, analyzedClass),
        target: _attributeName(name));

/// Converts a host listener to an [ir.Binding] instance.
///
/// Current host listeners are represented as a map from [name] to [value].
// TODO(b/130184376): Create a better HostListener representation.
ir.Binding convertHostListenerToBinding(
        String eventName, expression_ast.ASTWithSource handlerAst) =>
    ir.Binding(
      source: _handlerFor(
        eventName,
        ast.EventHandler(handlerAst),
        null, // TODO(alorenzen): Add SourceSpan to HostListeners.
        _IrBindingContext(null, null, null),
      ),
      target: isNativeHtmlEvent(eventName)
          ? ir.NativeEvent(eventName)
          : ir.CustomEvent(eventName),
    );

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
            input.memberName, _inputType(context.directive, input)),
        isDirect: _isDirectBinding(context.directive, input.memberName),
      );

  o.OutputType _inputType(
      CompileDirectiveMetadata directive, ast.BoundDirectivePropertyAst input) {
    // TODO(alorenzen): Determine if we actually need this special case.
    if (directive.identifier.name == 'NgIf' && input.memberName == 'ngIf') {
      return o.BOOL_TYPE;
    }
    var inputTypeMeta = directive.inputTypes[input.memberName];
    return inputTypeMeta != null
        ? o.importType(inputTypeMeta, inputTypeMeta.typeArguments)
        : null;
  }

  bool _isDirectBinding(
      CompileDirectiveMetadata directive, String directiveName) {
    // Optimization specifically for NgIf. Since the directive already performs
    // change detection we can directly update it's input.
    // TODO: generalize to SingleInputDirective mixin.
    if (directive.identifier.name == 'NgIf' && directiveName == 'ngIf') {
      return true;
    }
    return false;
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
  ir.Binding visitDirectiveEvent(
          ast.BoundDirectiveEventAst ast, _IrBindingContext context) =>
      ir.Binding(
        source:
            _handlerFor(ast.templateName, ast.handler, ast.sourceSpan, context),
        target: ir.DirectiveOutput(
            ast.memberName, context.directive.analyzedClass.isMockLike),
      );

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
      ir.Binding(
        source: _handlerFor(ast.name, ast.handler, ast.sourceSpan, context),
        target: isNativeHtmlEvent(ast.name)
            ? ir.NativeEvent(ast.name)
            : ir.CustomEvent(ast.name),
      );

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

  /// The target directive for any Input/Output bindings.
  final CompileDirectiveMetadata directive;
  final CompileElement compileElement;

  _IrBindingContext(this.analyzedClass, this.directive, this.compileElement);

  /// Lookup the [ProviderSource] for a [directive] matched on the element in
  /// context.
  ///
  /// This is mainly used for looking up the directive context for a
  /// HostListener.
  ProviderSource directiveInstance(CompileDirectiveMetadata directive) {
    return compileElement?.getDirectiveSource(directive);
  }
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

ir.EventHandler _handlerFor(
  String eventName,
  ast.EventHandler handler,
  SourceSpan sourceSpan,
  _IrBindingContext context,
) {
  var handlerAst = _handlerExpression(handler, context);
  var handlerType = handlerTypeFromExpression(handlerAst.ast);
  var directiveInstance = context.directiveInstance(handler.hostDirective);
  if (handlerType == HandlerType.notSimple) {
    return ir.ComplexEventHandler.forAst(
      handlerAst,
      sourceSpan,
      directiveInstance: directiveInstance,
    );
  } else {
    return ir.SimpleEventHandler(handlerAst, sourceSpan,
        directiveInstance: directiveInstance,
        numArgs: handlerType == HandlerType.simpleNoArgs ? 0 : 1);
  }
}

expression_ast.ASTWithSource _handlerExpression(
    ast.EventHandler handler, _IrBindingContext context) {
  var handlerAst = handler.expression;
  if (!_isTearOff(handlerAst)) {
    return handlerAst;
  }
  return rewriteTearOff(
    handlerAst,
    handler.hostDirective?.analyzedClass ?? context.analyzedClass,
  );
}

bool _isTearOff(ASTWithSource handler) => handler.ast is PropertyRead;
