import 'package:source_span/source_span.dart';

import 'html_ast.dart';
import 'html_lexer.dart' show HtmlToken, HtmlTokenType, tokenizeHtml;
import 'html_tags.dart' show getHtmlTagDefinition, getNsPrefix, mergeNsAndName;
import 'parse_util.dart' show ParseError;

class HtmlTreeError extends ParseError {
  String elementName;
  static HtmlTreeError create(String elementName, SourceSpan span, String msg) {
    return new HtmlTreeError(elementName, span, msg);
  }

  HtmlTreeError(this.elementName, SourceSpan span, String msg)
      : super(span, msg);
}

class HtmlParseTreeResult {
  final List<HtmlAst> rootNodes;
  final List<ParseError> errors;
  HtmlParseTreeResult(this.rootNodes, this.errors);
}

class HtmlParser {
  HtmlParseTreeResult parse(String sourceContent, String sourceUrl,
      [bool parseExpansionForms = false]) {
    var tokensAndErrors =
        tokenizeHtml(sourceContent, sourceUrl, parseExpansionForms);
    var treeAndErrors = new HtmlTreeBuilder(tokensAndErrors.tokens,
            new SourceFile.fromString(sourceContent, url: sourceUrl))
        .build();
    return new HtmlParseTreeResult(
        treeAndErrors.rootNodes,
        (new List<ParseError>.from(((tokensAndErrors.errors)))
          ..addAll(treeAndErrors.errors)));
  }
}

class HtmlTreeBuilder {
  final List<HtmlToken> tokens;
  final SourceFile file;

  num index = -1;
  HtmlToken peek;
  List<HtmlAst> rootNodes = [];
  List<HtmlTreeError> errors = [];
  List<HtmlElementAst> elementStack = [];

  HtmlTreeBuilder(this.tokens, this.file) {
    _advance();
  }

  HtmlParseTreeResult build() {
    while (peek.type != HtmlTokenType.EOF) {
      switch (peek.type) {
        case HtmlTokenType.TAG_OPEN_START:
          _consumeStartTag(_advance());
          break;
        case HtmlTokenType.TAG_CLOSE:
          _consumeEndTag(_advance());
          break;
        case HtmlTokenType.CDATA_START:
          _closeVoidElement();
          _consumeCdata(_advance());
          break;
        case HtmlTokenType.COMMENT_START:
          _closeVoidElement();
          _consumeComment(_advance());
          break;
        case HtmlTokenType.TEXT:
        case HtmlTokenType.RAW_TEXT:
        case HtmlTokenType.ESCAPABLE_RAW_TEXT:
          _closeVoidElement();
          _consumeText(_advance());
          break;
        default:
          // Skip all other tokens...
          _advance();
          break;
      }
    }
    return new HtmlParseTreeResult(rootNodes, errors);
  }

  HtmlToken _advance() {
    var prev = peek;
    if (index < (tokens.length - 1)) {
      // Note: there is always an EOF token at the end
      index++;
    }
    peek = tokens[index];
    return prev;
  }

  HtmlToken _advanceIf(HtmlTokenType type) {
    if (identical(peek.type, type)) {
      return _advance();
    }
    return null;
  }

  void _consumeCdata(HtmlToken startToken) {
    _consumeText(_advance());
    _advanceIf(HtmlTokenType.CDATA_END);
  }

  void _consumeComment(HtmlToken token) {
    var text = _advanceIf(HtmlTokenType.RAW_TEXT);
    _advanceIf(HtmlTokenType.COMMENT_END);
    var value = text != null ? text.parts[0].trim() : null;
    _addToParent(new HtmlCommentAst(value, token.sourceSpan));
  }

  void _consumeText(HtmlToken token) {
    String text = token.parts[0];
    if (text.isNotEmpty && text[0] == '\n') {
      var parent = _getParentElement();
      if (parent != null &&
          parent.children.isEmpty &&
          getHtmlTagDefinition(parent.name).ignoreFirstLf) {
        text = text.substring(1);
      }
    }
    if (text.isNotEmpty) {
      _addToParent(new HtmlTextAst(text, token.sourceSpan));
    }
  }

  void _closeVoidElement() {
    if (elementStack.isEmpty) return;
    if (getHtmlTagDefinition(elementStack.last.name).isVoid) {
      elementStack.removeLast();
    }
  }

  void _consumeStartTag(HtmlToken startTagToken) {
    var prefix = startTagToken.parts[0];
    var name = startTagToken.parts[1];
    var attrs = <HtmlAttrAst>[];
    while (identical(peek.type, HtmlTokenType.ATTR_NAME)) {
      attrs.add(_consumeAttr(_advance()));
    }
    var fullName = getElementFullName(prefix, name, _getParentElement());
    var selfClosing = false;
    // Note: There could have been a tokenizer error

    // so that we don't get a token for the end tag...
    if (identical(peek.type, HtmlTokenType.TAG_OPEN_END_VOID)) {
      _advance();
      selfClosing = true;
      if (getNsPrefix(fullName) == null &&
          !getHtmlTagDefinition(fullName).isVoid) {
        errors.add(HtmlTreeError.create(
            fullName,
            startTagToken.sourceSpan,
            'Only void and foreign elements can be self closed '
            '"${startTagToken.parts[1]}"'));
      }
    } else if (identical(peek.type, HtmlTokenType.TAG_OPEN_END)) {
      _advance();
      selfClosing = false;
    }
    var end = peek.sourceSpan.start;
    var span = new SourceSpan(startTagToken.sourceSpan.start, end,
        file.getText(startTagToken.sourceSpan.start.offset, end.offset));
    var el = new HtmlElementAst(fullName, attrs, [], span, span, null);
    _pushElement(el);
    if (selfClosing) {
      _popElement(fullName);
      el.endSourceSpan = span;
    }
  }

  void _pushElement(HtmlElementAst el) {
    if (elementStack.isNotEmpty) {
      var parentEl = elementStack.last;
      if (getHtmlTagDefinition(parentEl.name).isClosedByChild(el.name)) {
        elementStack.removeLast();
      }
    }
    var tagDef = getHtmlTagDefinition(el.name);
    var parentEl = _getParentElement();
    // If root we do not have to wrap elements such as tr/td.
    if (parentEl != null && tagDef.requireExtraParent(parentEl.name)) {
      var newParent = new HtmlElementAst(tagDef.parentToAdd, [], [el],
          el.sourceSpan, el.startSourceSpan, el.endSourceSpan);
      _addToParent(newParent);
      elementStack.add(newParent);
      elementStack.add(el);
    } else {
      _addToParent(el);
      elementStack.add(el);
    }
  }

  void _consumeEndTag(HtmlToken endTagToken) {
    var fullName = getElementFullName(
        endTagToken.parts[0], endTagToken.parts[1], _getParentElement());
    _getParentElement().endSourceSpan = endTagToken.sourceSpan;
    if (getHtmlTagDefinition(fullName).isVoid) {
      errors.add(HtmlTreeError.create(fullName, endTagToken.sourceSpan,
          'Void elements do not have end tags "${endTagToken.parts[1]}"'));
    } else if (!_popElement(fullName)) {
      errors.add(HtmlTreeError.create(fullName, endTagToken.sourceSpan,
          'Unexpected closing tag "${endTagToken.parts[1]}"'));
    }
  }

  bool _popElement(String fullName) {
    for (var stackIndex = elementStack.length - 1;
        stackIndex >= 0;
        stackIndex--) {
      var el = elementStack[stackIndex];
      if (el.name == fullName) {
        elementStack.removeRange(stackIndex, elementStack.length);
        return true;
      }
      if (!getHtmlTagDefinition(el.name).closedByParent) {
        return false;
      }
    }
    return false;
  }

  HtmlAttrAst _consumeAttr(HtmlToken attrName) {
    var fullName = mergeNsAndName(attrName.parts[0], attrName.parts[1]);
    var end = attrName.sourceSpan.end;
    var value = '';
    var hasValue = false;
    if (peek.type == HtmlTokenType.ATTR_VALUE) {
      var valueToken = _advance();
      value = valueToken.parts[0];
      end = valueToken.sourceSpan.end;
      hasValue = true;
    }
    return new HtmlAttrAst(
      fullName,
      value,
      new SourceSpan(attrName.sourceSpan.start, end,
          file.getText(attrName.sourceSpan.start.offset, end.offset)),
      hasValue,
    );
  }

  HtmlElementAst _getParentElement() {
    return elementStack.isNotEmpty ? elementStack.last : null;
  }

  void _addToParent(HtmlAst node) {
    var parent = _getParentElement();
    if (parent != null) {
      parent.children.add(node);
    } else {
      rootNodes.add(node);
    }
  }
}

String getElementFullName(
    String prefix, String localName, HtmlElementAst parentElement) {
  if (prefix == null) {
    prefix = getHtmlTagDefinition(localName).implicitNamespacePrefix;
    if (prefix == null && parentElement != null) {
      prefix = getNsPrefix(parentElement.name);
    }
  }
  return mergeNsAndName(prefix, localName);
}

bool lastOnStack(List<dynamic> stack, dynamic element) {
  return stack.isNotEmpty && identical(stack[stack.length - 1], element);
}
