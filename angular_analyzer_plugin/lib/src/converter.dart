import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart' hide SimpleToken;
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/ignoring_error_listener.dart';
import 'package:angular_analyzer_plugin/src/ng_expr_parser.dart';
import 'package:angular_ast/angular_ast.dart';
import 'package:meta/meta.dart';

/// Parse dart expressions/statements/etc that are embedded in a template.
class EmbeddedDartParser {
  static const _let = 'let';
  static const _letDash = '$_let-';
  final Source templateSource;
  final AnalysisErrorListener errorListener;
  final ErrorReporter errorReporter;

  EmbeddedDartParser(
      this.templateSource, this.errorListener, this.errorReporter);

  String capitalize(String str) {
    if (str == null || str.isEmpty) {
      return str;
    }
    // ignore: prefer_interpolation_to_compose_strings
    return str.substring(0, 1).toUpperCase() + str.substring(1);
  }

  /// Parse the given Dart [code] that starts at [offset].
  Expression parseDartExpression(int offset, String code,
      {@required bool detectTrailing}) {
    if (code == null) {
      return null;
    }

    final token = _scanDartCode(offset, code);
    Expression expression;

    // Suppress errors for this, but still parse it for later analysis
    if (code.trim().isEmpty) {
      expression = _parseDartExpressionAtToken(token,
          errorListener: IgnoringErrorListener());
    } else {
      expression = _parseDartExpressionAtToken(token);
    }

    if (detectTrailing && expression.endToken.next.type != TokenType.EOF) {
      final trailingExpressionBegin = expression.endToken.next.offset;
      errorListener.onError(AnalysisError(
          templateSource,
          trailingExpressionBegin,
          offset + code.length - trailingExpressionBegin,
          AngularWarningCode.TRAILING_EXPRESSION));
    }

    return expression;
  }

  /// Parse the given Dart [code] that starts at [offset].
  ///
  /// Also removes and reports dangling closing brackets.
  List<Statement> parseDartStatements(int offset, String code) {
    final allStatements = <Statement>[];
    if (code == null) {
      return allStatements;
    }

    // ignore: parameter_assignments, prefer_interpolation_to_compose_strings
    code = code + ';';

    var token = _scanDartCode(offset, code);

    while (token.type != TokenType.EOF) {
      final currentStatements = _parseDartStatementsAtToken(token);

      if (currentStatements.isNotEmpty) {
        allStatements.addAll(currentStatements);
        token = currentStatements.last.endToken.next;
      }
      if (token.type == TokenType.EOF) {
        break;
      }
      if (token.type == TokenType.CLOSE_CURLY_BRACKET) {
        final startCloseBracket = token.offset;
        while (token.type == TokenType.CLOSE_CURLY_BRACKET) {
          token = token.next;
        }
        final length = token.offset - startCloseBracket;
        errorListener.onError(AnalysisError(templateSource, startCloseBracket,
            length, ParserErrorCode.UNEXPECTED_TOKEN, ["}"]));
        continue;
      } else {
        //Nothing should trigger here, but just in case to prevent infinite loop
        token = token.next;
      }
    }
    return allStatements;
  }

  /// Desugar a `template=""` or `*blah=""` attribute into [AttributeInfo]s.
  _VirtualAttributes parseTemplateVirtualAttributes(int offset, String code) {
    final attributes = <AttributeInfo>[];

    var token = _scanDartCode(offset, code);
    String prefix;
    while (token.type != TokenType.EOF) {
      // skip optional comma or semicolons
      if (_isDelimiter(token)) {
        token = token.next;
        continue;
      }
      // maybe a local variable
      if (_isTemplateVarBeginToken(token)) {
        final originalVarOffset = token.offset;
        if (token.type == TokenType.HASH) {
          errorReporter.reportErrorForToken(
              AngularWarningCode.UNEXPECTED_HASH_IN_TEMPLATE, token);
        }

        var originalName = token.lexeme;

        // get the local variable name
        token = token.next;
        var localVarName = "";
        var localVarOffset = token.offset;
        if (!_tokenMatchesIdentifier(token)) {
          errorReporter.reportErrorForToken(
              AngularWarningCode.EXPECTED_IDENTIFIER, token);
        } else {
          localVarOffset = token.offset;
          localVarName = token.lexeme;
          // ignore: prefer_interpolation_to_compose_strings
          originalName +=
              ' ' * (token.offset - originalVarOffset - _let.length) +
                  localVarName;
          token = token.next;
        }

        // get an optional internal variable
        int internalVarOffset;
        String internalVarName;
        if (token.type == TokenType.EQ) {
          token = token.next;
          // get the internal variable
          if (!_tokenMatchesIdentifier(token)) {
            errorReporter.reportErrorForToken(
                AngularWarningCode.EXPECTED_IDENTIFIER, token);
            break;
          }
          internalVarOffset = token.offset;
          internalVarName = token.lexeme;
          token = token.next;
        }
        // declare the local variable
        // Note the care that the varname's offset is preserved in place.
        attributes.add(TextAttribute.synthetic(
            '$_letDash$localVarName',
            localVarOffset - _letDash.length,
            internalVarName,
            internalVarOffset,
            originalName,
            originalVarOffset, []));
        continue;
      }

      // key
      String key;
      final keyBuffer = StringBuffer();
      final keyOffset = token.offset;
      String originalName;
      final originalNameOffset = keyOffset;
      if (_tokenMatchesIdentifier(token)) {
        // scan for a full attribute name
        var lastEnd = token.offset;
        while (token.offset == lastEnd &&
            (_tokenMatchesIdentifier(token) || token.type == TokenType.MINUS)) {
          keyBuffer.write(token.lexeme);
          lastEnd = token.end;
          token = token.next;
        }

        originalName = keyBuffer.toString();

        // add the prefix
        if (prefix == null) {
          prefix = keyBuffer.toString();
          key = keyBuffer.toString();
        } else {
          // ignore: prefer_interpolation_to_compose_strings
          key = prefix + capitalize(keyBuffer.toString());
        }
      } else {
        errorReporter.reportErrorForToken(
            AngularWarningCode.EXPECTED_IDENTIFIER, token);
        break;
      }
      // skip optional ':' or '='
      if (token.type == TokenType.COLON || token.type == TokenType.EQ) {
        token = token.next;
      }
      // expression
      if (!_isTemplateVarBeginToken(token) &&
          !_isDelimiter(token) &&
          token.type != TokenType.EOF) {
        final expression = _parseDartExpressionAtToken(token);
        final start = token.offset - offset;

        token = expression.endToken.next;
        // The tokenizer isn't perfect always. Ensure [end] <= [code.length].
        final end = min(token.offset - offset, code.length);
        final exprCode = code.substring(start, end);
        attributes.add(ExpressionBoundAttribute(
            key,
            keyOffset,
            exprCode,
            expression.offset,
            originalName,
            originalNameOffset,
            expression,
            ExpressionBoundType.input));
      } else {
        // A special kind of TextAttr that signifies its special.
        final binding = EmptyStarBinding(
            key, keyOffset, originalName, originalNameOffset,
            isPrefix: attributes.isEmpty);

        attributes.add(binding);

        // Check for empty `of` and `trackBy` bindings, but NOT empty `ngIf`!
        // NgFor (and other star directives) often result in a harmless, empty
        // first attr. Don't flag it unless it matches an input (like `ngIf`
        // does), which is checked by [SingleScopeResolver].
        if (!binding.isPrefix) {
          errorReporter.reportErrorForOffset(AngularWarningCode.EMPTY_BINDING,
              originalNameOffset, originalName.length, [originalName]);
        }
      }
    }

    return _VirtualAttributes(prefix, attributes);
  }

  /// Parse the Dart expression starting at the given [token].
  Expression _parseDartExpressionAtToken(Token token,
      {AnalysisErrorListener errorListener}) {
    errorListener ??= this.errorListener;
    final parser = NgExprParser(templateSource, errorListener);
    return parser.parseExpression(token);
  }

  /// Parse the Dart statement starting at the given [token].
  List<Statement> _parseDartStatementsAtToken(Token token) {
    final parser = Parser.withoutFasta(templateSource, errorListener);
    return parser.parseStatements(token);
  }

  /// Scan the given Dart [code] that starts at [offset].
  Token _scanDartCode(int offset, String code) {
    // Warning: we lexically and unintelligently "accept" `===` for now by
    // replacing it with `==`. This is actually OK for us since we can butcher
    // string literal contents fine, and it won't affect analysis.
    final noTripleEquals =
        code.replaceAll('===', '== ').replaceAll('!==', '!= ');

    // ignore: prefer_interpolation_to_compose_strings
    final text = ' ' * offset + noTripleEquals;
    final reader = CharSequenceReader(text);
    final scanner = Scanner(templateSource, reader, errorListener);
    return scanner.tokenize();
  }

  static bool _isDelimiter(Token token) =>
      token.type == TokenType.COMMA || token.type == TokenType.SEMICOLON;

  static bool _isTemplateVarBeginToken(Token token) =>
      token is KeywordToken && token.keyword == Keyword.VAR ||
      (token.type == TokenType.IDENTIFIER && token.lexeme == 'let') ||
      token.type == TokenType.HASH;

  static bool _tokenMatchesBuiltInIdentifier(Token token) =>
      token is KeywordToken && token.keyword.isBuiltInOrPseudo;

  static bool _tokenMatchesIdentifier(Token token) =>
      token.type == TokenType.IDENTIFIER ||
      _tokenMatchesBuiltInIdentifier(token);
}

/// Convert angular_ast nodes to `lib/ast.dart` nodes.
class HtmlTreeConverter {
  static final _period = '.';
  static final _openBracket = '<';
  static final _openBracketSlash = '</';
  final EmbeddedDartParser dartParser;
  final Source templateSource;
  final AnalysisErrorListener errorListener;

  HtmlTreeConverter(this.dartParser, this.templateSource, this.errorListener);

  DocumentInfo convertFromAstList(List<TemplateAst> asts) {
    final parent = DocumentInfo();
    if (asts.isEmpty) {
      parent.childNodes.add(TextInfo(0, '', parent, []));
    }
    for (final node in asts) {
      final convertedNode =
          node.accept(_HtmlTreeConverterVisitor(this), parent);
      if (convertedNode != null) {
        parent.childNodes.add(convertedNode);
      }
    }
    return parent;
  }

  TemplateAttribute findTemplateAttribute(List<AttributeInfo> attributes) {
    for (final attribute in attributes) {
      if (attribute is TemplateAttribute) {
        return attribute;
      }
    }
    return null;
  }

  List<AttributeInfo> _convertAttributes({
    List<AttributeAst> attributes = const [],
    List<BananaAst> bananas = const [],
    List<EventAst> events = const [],
    List<PropertyAst> properties = const [],
    List<ReferenceAst> references = const [],
    List<StarAst> stars = const [],
    List<LetBindingAst> letBindings = const [],
  }) {
    final returnAttributes = <AttributeInfo>[];

    for (final attribute in attributes) {
      if (attribute is ParsedAttributeAst) {
        if (attribute.name == 'template') {
          returnAttributes.add(_convertTemplateAttribute(attribute));
        } else {
          String value;
          int valueOffset;
          if (attribute.valueToken != null) {
            value = attribute.valueToken.innerValue.lexeme;
            valueOffset = attribute.valueToken.innerValue.offset;
          }
          returnAttributes.add(TextAttribute(
            attribute.name,
            attribute.nameOffset,
            value,
            valueOffset,
            attribute.mustaches == null
                ? []
                : attribute.mustaches.map(_convertMustache).toList(),
          ));
        }
      }
    }

    bananas.map(_convertExpressionBoundAttribute).forEach(returnAttributes.add);
    events.map(_convertStatementsBoundAttribute).forEach(returnAttributes.add);
    properties
        .map(_convertExpressionBoundAttribute)
        .forEach(returnAttributes.add);

    for (final reference in references) {
      if (reference is ParsedReferenceAst) {
        String value;
        int valueOffset;
        if (reference.valueToken != null) {
          value = reference.valueToken.innerValue.lexeme;
          valueOffset = reference.valueToken.innerValue.offset;
        }
        returnAttributes.add(TextAttribute(
            '${reference.prefixToken.lexeme}${reference.nameToken.lexeme}',
            reference.prefixToken.offset,
            value,
            valueOffset, const <Mustache>[]));
      }
    }

    // Guaranteed to be empty for non-template elements.
    for (final letBinding in letBindings) {
      if (letBinding is ParsedLetBindingAst) {
        String value;
        int valueOffset;
        if (letBinding.valueToken != null) {
          value = letBinding.valueToken.innerValue.lexeme;
          valueOffset = letBinding.valueToken.innerValue.offset;
        }
        returnAttributes.add(TextAttribute(
            '${letBinding.prefixToken.lexeme}${letBinding.nameToken.lexeme}',
            letBinding.prefixToken.offset,
            value,
            valueOffset, <Mustache>[]));
      }
    }

    stars.map(_convertTemplateAttribute).forEach(returnAttributes.add);

    return returnAttributes;
  }

  List<NodeInfo> _convertChildren(
      StandaloneTemplateAst node, ElementInfo parent) {
    final children = <NodeInfo>[];
    for (final child in node.childNodes) {
      final childNode = child.accept(_HtmlTreeConverterVisitor(this), parent);
      if (childNode != null) {
        children.add(childNode);
        if (childNode is ElementInfo) {
          parent.childNodesMaxEnd = childNode.childNodesMaxEnd;
        } else {
          parent.childNodesMaxEnd = childNode.offset + childNode.length;
        }
      }
    }
    return children;
  }

  ExpressionBoundAttribute _convertExpressionBoundAttribute(TemplateAst ast) {
    // Default starting.
    var bound = ExpressionBoundType.input;

    final parsed = ast as ParsedDecoratorAst;
    final suffixToken = parsed.suffixToken;
    final nameToken = parsed.nameToken;
    final prefixToken = parsed.prefixToken;

    String origName;
    {
      final _prefix = prefixToken.errorSynthetic ? '' : prefixToken.lexeme;
      final _suffix = (suffixToken == null || suffixToken.errorSynthetic)
          ? ''
          : suffixToken.lexeme;
      origName = '$_prefix${nameToken.lexeme}$_suffix';
    }
    final origNameOffset = prefixToken.offset;

    var propName = nameToken.lexeme;
    var propNameOffset = nameToken.offset;

    if (ast is ParsedPropertyAst) {
      // For some inputs, like `[class.foo]`, the [ast.name] here is actually
      // not a name, but a prefix. If so, use the [ast.postfix] as the [name] of
      // the [ExpressionBoundAttribute] we're creating here, by changing
      // [propName].
      final nameOrPrefix = ast.name;

      if (ast.postfix != null) {
        var usePostfixForName = false;
        var preserveUnitInName = false;

        if (nameOrPrefix == 'class') {
          bound = ExpressionBoundType.clazz;
          usePostfixForName = true;
          preserveUnitInName = true;
        } else if (nameOrPrefix == 'attr') {
          if (ast.unit == 'if') {
            bound = ExpressionBoundType.attrIf;
          } else {
            bound = ExpressionBoundType.attr;
          }
          usePostfixForName = true;
        } else if (nameOrPrefix == 'style') {
          bound = ExpressionBoundType.style;
          usePostfixForName = true;
          preserveUnitInName = ast.unit != null;
        }

        if (usePostfixForName) {
          final _unitName =
              preserveUnitInName && ast.unit != null ? '.${ast.unit}' : '';
          propName = '${ast.postfix}$_unitName';
          propNameOffset = nameToken.offset + ast.name.length + _period.length;
        } else {
          assert(!preserveUnitInName);
        }
      }
    } else {
      bound = ExpressionBoundType.twoWay;
    }

    final value = parsed.valueToken?.innerValue?.lexeme;
    if ((value == null || value.isEmpty) &&
        !prefixToken.errorSynthetic &&
        (suffixToken == null ? true : !suffixToken.errorSynthetic)) {
      errorListener.onError(AnalysisError(
        templateSource,
        origNameOffset,
        origName.length,
        AngularWarningCode.EMPTY_BINDING,
        [origName],
      ));
    }
    final valueOffset = parsed.valueToken?.innerValue?.offset;

    return ExpressionBoundAttribute(
        propName,
        propNameOffset,
        value,
        valueOffset,
        origName,
        origNameOffset,
        dartParser.parseDartExpression(valueOffset, value,
            detectTrailing: true),
        bound);
  }

  StatementsBoundAttribute _convertStatementsBoundAttribute(EventAst eventAst) {
    final ast = eventAst as ParsedEventAst;
    final prefixToken = ast.prefixToken;
    final nameToken = ast.nameToken;
    final suffixToken = ast.suffixToken;

    final prefixComponent =
        prefixToken.errorSynthetic ? '' : prefixToken.lexeme;
    final suffixComponent =
        ((suffixToken == null) || suffixToken.errorSynthetic)
            ? ''
            : suffixToken.lexeme;
    final origName = '$prefixComponent${ast.name}$suffixComponent';
    final origNameOffset = prefixToken.offset;

    final value = ast.value;
    if ((value == null || value.isEmpty) &&
        !prefixToken.errorSynthetic &&
        (suffixToken == null ? true : !suffixToken.errorSynthetic)) {
      errorListener.onError(AnalysisError(templateSource, origNameOffset,
          origName.length, AngularWarningCode.EMPTY_BINDING, [ast.name]));
    }
    final valueOffset = ast.valueOffset;

    final propName = ast.name;
    final propNameOffset = nameToken.offset;

    return StatementsBoundAttribute(
        propName,
        propNameOffset,
        value,
        valueOffset,
        origName,
        origNameOffset,
        ast.reductions,
        dartParser.parseDartStatements(valueOffset, value));
  }

  TemplateAttribute _convertTemplateAttribute(TemplateAst ast) {
    String name;
    String prefix;
    int nameOffset;

    String value;
    int valueOffset;

    String origName;
    int origNameOffset;

    var virtualAttributes = <AttributeInfo>[];

    if (ast is ParsedStarAst) {
      value = ast.value;
      valueOffset = ast.valueOffset;

      origName = '${ast.prefixToken.lexeme}${ast.nameToken.lexeme}';
      origNameOffset = ast.prefixToken.offset;

      name = ast.nameToken.lexeme;
      nameOffset = ast.nameToken.offset;

      String fullAstName;
      if (value != null) {
        final whitespacePad =
            ' ' * (ast.valueToken.innerValue.offset - ast.nameToken.end);
        fullAstName = "${ast.name}$whitespacePad${value ?? ''}";
      } else {
        fullAstName = '${ast.name} ';
      }

      final tuple =
          dartParser.parseTemplateVirtualAttributes(nameOffset, fullAstName);
      virtualAttributes = tuple.attributes;
      prefix = tuple.prefix;
    }
    if (ast is ParsedAttributeAst) {
      value = ast.value;
      valueOffset = ast.valueOffset;

      origName = ast.name;
      origNameOffset = ast.nameOffset;

      name = origName;
      nameOffset = origNameOffset;

      if (value == null || value.isEmpty) {
        errorListener.onError(AnalysisError(templateSource, origNameOffset,
            origName.length, AngularWarningCode.EMPTY_BINDING, [origName]));
      } else {
        virtualAttributes = dartParser
            .parseTemplateVirtualAttributes(valueOffset, value)
            .attributes;
      }
    }

    final templateAttribute = TemplateAttribute(name, nameOffset, value,
        valueOffset, origName, origNameOffset, virtualAttributes,
        prefix: prefix);

    for (final virtualAttribute in virtualAttributes) {
      virtualAttribute.parent = templateAttribute;
    }

    return templateAttribute;
  }

  Mustache _convertMustache(InterpolationAst mustache) {
    int exprOffset;
    int exprLength;
    Expression parsedExpression;

    if (mustache is ParsedInterpolationAst) {
      exprOffset = mustache.valueToken.offset;
      exprLength = exprOffset + mustache.valueToken.length;
      parsedExpression = dartParser.parseDartExpression(
          mustache.valueToken.offset, mustache.value,
          detectTrailing: !mustache.endToken.errorSynthetic);
    }

    return Mustache(
        mustache.beginToken.offset,
        mustache.endToken.offset + mustache.endToken.length,
        parsedExpression,
        exprOffset,
        exprLength);
  }

  /// Produce an [ElementInfo] from a open & close ast.
  ///
  /// There are four types of "tags" in angular_ast which don't implement a
  /// common interface. But we need to generate source spans for all of them.
  /// We can do this if we have the [node] (we can use its [beginToken]) and its
  /// [closeComplement]. So this takes that info, plus a few other structural
  /// things ([attributes], [parent], [tagName]), to handle all four cases.
  ElementInfo _elementInfoFromNodeAndCloseComplement(
      StandaloneTemplateAst node,
      String tagName,
      List<AttributeInfo> attributes,
      CloseElementAst closeComplement,
      ElementInfo parent) {
    final isTemplate = tagName == 'template';
    SourceRange openingSpan;
    SourceRange openingNameSpan;
    SourceRange closingSpan;
    SourceRange closingNameSpan;

    if (node.isSynthetic && closeComplement != null) {
      // This code assumes that a synthetic node is a close tag with no open
      // tag, ie, a dangling `</div>`.
      openingSpan = _toSourceRange(closeComplement.beginToken.offset, 0);
      openingNameSpan ??= openingSpan;
    } else {
      openingSpan = _toSourceRange(
          node.beginToken.offset, node.endToken.end - node.beginToken.offset);
      openingNameSpan ??= SourceRange(
          node.beginToken.offset + _openBracket.length, tagName.length);
    }

    if (closeComplement != null) {
      if (!closeComplement.isSynthetic) {
        closingSpan = _toSourceRange(closeComplement.beginToken.offset,
            closeComplement.endToken.end - closeComplement.beginToken.offset);
        closingNameSpan = SourceRange(
            closingSpan.offset + _openBracketSlash.length, tagName.length);
      } else {
        // TODO(mfairhurst): generate a closingSpan for synthetic tags too. This
        // can mess up autocomplete if we do it wrong.
      }
    }

    final element = ElementInfo(
      tagName,
      openingSpan,
      closingSpan,
      openingNameSpan,
      closingNameSpan,
      attributes,
      findTemplateAttribute(attributes),
      parent,
      isTemplate: isTemplate,
    );

    for (final attribute in attributes) {
      attribute.parent = element;
    }

    final children = _convertChildren(node, element);
    element.childNodes.addAll(children);

    // For empty tags, ie, `<div></div>`, generate a synthetic text entry
    // between the two tags. This simplifies later autocomplete code.
    if (!element.isSynthetic &&
        element.openingSpanIsClosed &&
        closingSpan != null &&
        (openingSpan.offset + openingSpan.length) == closingSpan.offset) {
      element.childNodes.add(TextInfo(
          openingSpan.offset + openingSpan.length, '', element, [],
          synthetic: true));
    }

    return element;
  }

  SourceRange _toSourceRange(int offset, int length) =>
      SourceRange(offset, length);
}

/// A private visitor used by [HtmlTreeConverter] to begin conversion.
class _HtmlTreeConverterVisitor
    extends ThrowingTemplateAstVisitor<NodeInfo, ElementInfo> {
  final HtmlTreeConverter _converter;

  _HtmlTreeConverterVisitor(this._converter);

  @override
  NodeInfo visitContainer(ContainerAst astNode, [ElementInfo parent]) {
    final attributes = _converter._convertAttributes(
      stars: astNode.stars,
    )..sort((a, b) => a.offset.compareTo(b.offset));

    return _converter._elementInfoFromNodeAndCloseComplement(
      astNode,
      'ng-container',
      attributes,
      astNode.closeComplement,
      parent,
    );
  }

  @override
  NodeInfo visitElement(ElementAst astNode, [ElementInfo parent]) {
    final attributes = _converter._convertAttributes(
      attributes: astNode.attributes,
      bananas: astNode.bananas,
      events: astNode.events,
      properties: astNode.properties,
      references: astNode.references,
      stars: astNode.stars,
    )..sort((a, b) => a.offset.compareTo(b.offset));

    return _converter._elementInfoFromNodeAndCloseComplement(
      astNode,
      astNode.name,
      attributes,
      astNode.closeComplement,
      parent,
    );
  }

  @override
  NodeInfo visitEmbeddedContent(EmbeddedContentAst astNode,
      [ElementInfo parent]) {
    final attributes = <AttributeInfo>[];

    if (astNode is ParsedEmbeddedContentAst) {
      final valueToken = astNode.selectorValueToken;
      if (astNode.selectToken != null) {
        attributes.add(TextAttribute(
          'select',
          astNode.selectToken.offset,
          valueToken?.innerValue?.lexeme,
          valueToken?.innerValue?.offset,
          [],
        ));
      }
    }

    return _converter._elementInfoFromNodeAndCloseComplement(
      astNode,
      'ng-content',
      attributes,
      astNode.closeComplement,
      parent,
    );
  }

  @override
  NodeInfo visitEmbeddedTemplate(EmbeddedTemplateAst astNode,
      [ElementInfo parent]) {
    final attributes = _converter._convertAttributes(
      attributes: astNode.attributes,
      events: astNode.events,
      properties: astNode.properties,
      references: astNode.references,
      letBindings: astNode.letBindings,
    );

    return _converter._elementInfoFromNodeAndCloseComplement(
      astNode,
      'template',
      attributes,
      astNode.closeComplement,
      parent,
    );
  }

  @override
  NodeInfo visitInterpolation(InterpolationAst astNode, [ElementInfo parent]) {
    final offset = astNode.sourceSpan.start.offset;
    final text = '{{${astNode.value}}}';
    return TextInfo(
        offset, text, parent, [_converter._convertMustache(astNode)]);
  }

  @override
  NodeInfo visitText(TextAst astNode, [ElementInfo parent]) {
    final offset = astNode.sourceSpan.start.offset;
    final text = astNode.value;
    return TextInfo(offset, text, parent, const <Mustache>[]);
  }

  @override
  NodeInfo visitComment(CommentAst astNode, [ElementInfo parent]) {
    return null;
  }
}

class IgnorableHtmlInternalException implements Exception {
  String msg;
  IgnorableHtmlInternalException(this.msg);

  @override
  String toString() => "IgnorableHtmlInternalException: $msg";
}

class _VirtualAttributes {
  final String prefix;
  final List<AttributeInfo> attributes;
  _VirtualAttributes(this.prefix, this.attributes);
}
