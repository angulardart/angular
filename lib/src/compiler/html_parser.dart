import "package:angular2/src/core/di.dart" show Injectable;
import 'package:source_span/source_span.dart';

import "html_ast.dart"
    show HtmlAst, HtmlAttrAst, HtmlTextAst, HtmlCommentAst, HtmlElementAst;
import "html_lexer.dart" show HtmlToken, HtmlTokenType, tokenizeHtml;
import "html_tags.dart" show getHtmlTagDefinition, getNsPrefix, mergeNsAndName;
import "parse_util.dart" show ParseError;

class HtmlTreeError extends ParseError {
  String elementName;
  static HtmlTreeError create(String elementName, SourceSpan span, String msg) {
    return new HtmlTreeError(elementName, span, msg);
  }

  HtmlTreeError(this.elementName, SourceSpan span, String msg)
      : super(span, msg);
}

class HtmlParseTreeResult {
  List<HtmlAst> rootNodes;
  List<ParseError> errors;
  HtmlParseTreeResult(this.rootNodes, this.errors);
}

@Injectable()
class HtmlParser {
  HtmlParseTreeResult parse(String sourceContent, String sourceUrl,
      [bool parseExpansionForms = false]) {
    var tokensAndErrors =
        tokenizeHtml(sourceContent, sourceUrl, parseExpansionForms);
    var treeAndErrors = new TreeBuilder(tokensAndErrors.tokens,
            new SourceFile(sourceContent, url: sourceUrl))
        .build();
    return new HtmlParseTreeResult(
        treeAndErrors.rootNodes,
        (new List<ParseError>.from(((tokensAndErrors.errors)))
          ..addAll(treeAndErrors.errors)));
  }
}

class TreeBuilder {
  final List<HtmlToken> tokens;
  final SourceFile file;

  num index = -1;
  HtmlToken peek;
  List<HtmlAst> rootNodes = [];
  List<HtmlTreeError> errors = [];
  List<HtmlElementAst> elementStack = [];

  TreeBuilder(this.tokens, this.file) {
    this._advance();
  }

  HtmlParseTreeResult build() {
    while (!identical(this.peek.type, HtmlTokenType.EOF)) {
      if (identical(this.peek.type, HtmlTokenType.TAG_OPEN_START)) {
        this._consumeStartTag(this._advance());
      } else if (identical(this.peek.type, HtmlTokenType.TAG_CLOSE)) {
        this._consumeEndTag(this._advance());
      } else if (identical(this.peek.type, HtmlTokenType.CDATA_START)) {
        this._closeVoidElement();
        this._consumeCdata(this._advance());
      } else if (identical(this.peek.type, HtmlTokenType.COMMENT_START)) {
        this._closeVoidElement();
        this._consumeComment(this._advance());
      } else if (identical(this.peek.type, HtmlTokenType.TEXT) ||
          identical(this.peek.type, HtmlTokenType.RAW_TEXT) ||
          identical(this.peek.type, HtmlTokenType.ESCAPABLE_RAW_TEXT)) {
        this._closeVoidElement();
        this._consumeText(this._advance());
      } else {
        // Skip all other tokens...
        this._advance();
      }
    }
    return new HtmlParseTreeResult(this.rootNodes, this.errors);
  }

  HtmlToken _advance() {
    var prev = this.peek;
    if (this.index < this.tokens.length - 1) {
      // Note: there is always an EOF token at the end
      this.index++;
    }
    this.peek = this.tokens[this.index];
    return prev;
  }

  HtmlToken _advanceIf(HtmlTokenType type) {
    if (identical(this.peek.type, type)) {
      return this._advance();
    }
    return null;
  }

  void _consumeCdata(HtmlToken startToken) {
    this._consumeText(this._advance());
    this._advanceIf(HtmlTokenType.CDATA_END);
  }

  void _consumeComment(HtmlToken token) {
    var text = this._advanceIf(HtmlTokenType.RAW_TEXT);
    this._advanceIf(HtmlTokenType.COMMENT_END);
    var value = text != null ? text.parts[0].trim() : null;
    this._addToParent(new HtmlCommentAst(value, token.sourceSpan));
  }

  void _consumeText(HtmlToken token) {
    var text = token.parts[0];
    if (text.length > 0 && text[0] == "\n") {
      var parent = this._getParentElement();
      if (parent != null &&
          parent.children.length == 0 &&
          getHtmlTagDefinition(parent.name).ignoreFirstLf) {
        text = text.substring(1);
      }
    }
    if (text.length > 0) {
      this._addToParent(new HtmlTextAst(text, token.sourceSpan));
    }
  }

  void _closeVoidElement() {
    if (this.elementStack.length > 0) {
      var el = elementStack.isNotEmpty ? elementStack.last : null;
      if (getHtmlTagDefinition(el.name).isVoid) {
        this.elementStack.removeLast();
      }
    }
  }

  void _consumeStartTag(HtmlToken startTagToken) {
    var prefix = startTagToken.parts[0];
    var name = startTagToken.parts[1];
    var attrs = <HtmlAttrAst>[];
    while (identical(this.peek.type, HtmlTokenType.ATTR_NAME)) {
      attrs.add(this._consumeAttr(this._advance()));
    }
    var fullName = getElementFullName(prefix, name, this._getParentElement());
    var selfClosing = false;
    // Note: There could have been a tokenizer error

    // so that we don't get a token for the end tag...
    if (identical(this.peek.type, HtmlTokenType.TAG_OPEN_END_VOID)) {
      this._advance();
      selfClosing = true;
      if (getNsPrefix(fullName) == null &&
          !getHtmlTagDefinition(fullName).isVoid) {
        this.errors.add(HtmlTreeError.create(fullName, startTagToken.sourceSpan,
            '''Only void and foreign elements can be self closed "${ startTagToken . parts [ 1 ]}"'''));
      }
    } else if (identical(this.peek.type, HtmlTokenType.TAG_OPEN_END)) {
      this._advance();
      selfClosing = false;
    }
    var end = this.peek.sourceSpan.start;
    var span = new SourceSpan(startTagToken.sourceSpan.start, end,
        file.getText(startTagToken.sourceSpan.start.offset, end.offset));
    var el = new HtmlElementAst(fullName, attrs, [], span, span, null);
    this._pushElement(el);
    if (selfClosing) {
      this._popElement(fullName);
      el.endSourceSpan = span;
    }
  }

  void _pushElement(HtmlElementAst el) {
    if (this.elementStack.length > 0) {
      var parentEl = elementStack.isNotEmpty ? elementStack.last : null;
      if (getHtmlTagDefinition(parentEl.name).isClosedByChild(el.name)) {
        this.elementStack.removeLast();
      }
    }
    var tagDef = getHtmlTagDefinition(el.name);
    var parentEl = this._getParentElement();
    if (tagDef.requireExtraParent(parentEl != null ? parentEl.name : null)) {
      var newParent = new HtmlElementAst(tagDef.parentToAdd, [], [el],
          el.sourceSpan, el.startSourceSpan, el.endSourceSpan);
      this._addToParent(newParent);
      this.elementStack.add(newParent);
      this.elementStack.add(el);
    } else {
      this._addToParent(el);
      this.elementStack.add(el);
    }
  }

  void _consumeEndTag(HtmlToken endTagToken) {
    var fullName = getElementFullName(
        endTagToken.parts[0], endTagToken.parts[1], this._getParentElement());
    this._getParentElement().endSourceSpan = endTagToken.sourceSpan;
    if (getHtmlTagDefinition(fullName).isVoid) {
      this.errors.add(HtmlTreeError.create(fullName, endTagToken.sourceSpan,
          '''Void elements do not have end tags "${ endTagToken . parts [ 1 ]}"'''));
    } else if (!this._popElement(fullName)) {
      this.errors.add(HtmlTreeError.create(fullName, endTagToken.sourceSpan,
          '''Unexpected closing tag "${ endTagToken . parts [ 1 ]}"'''));
    }
  }

  bool _popElement(String fullName) {
    for (var stackIndex = this.elementStack.length - 1;
        stackIndex >= 0;
        stackIndex--) {
      var el = this.elementStack[stackIndex];
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
    var value = "";
    if (identical(this.peek.type, HtmlTokenType.ATTR_VALUE)) {
      var valueToken = this._advance();
      value = valueToken.parts[0];
      end = valueToken.sourceSpan.end;
    }
    return new HtmlAttrAst(
        fullName,
        value,
        new SourceSpan(attrName.sourceSpan.start, end,
            file.getText(attrName.sourceSpan.start.offset, end.offset)));
  }

  HtmlElementAst _getParentElement() {
    return this.elementStack.length > 0 ? elementStack.last : null;
  }

  void _addToParent(HtmlAst node) {
    var parent = this._getParentElement();
    if (parent != null) {
      parent.children.add(node);
    } else {
      this.rootNodes.add(node);
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
  return stack.length > 0 && identical(stack[stack.length - 1], element);
}
