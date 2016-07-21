import "package:angular2/src/compiler/expression_parser/parser.dart"
    show Parser;
import "package:angular2/src/compiler/html_ast.dart"
    show
        HtmlAst,
        HtmlAstVisitor,
        HtmlElementAst,
        HtmlAttrAst,
        HtmlTextAst,
        HtmlCommentAst,
        HtmlExpansionAst,
        HtmlExpansionCaseAst,
        htmlVisitAll;
import "package:angular2/src/compiler/parse_util.dart"
    show ParseSourceSpan, ParseError;
import "package:angular2/src/facade/lang.dart"
    show isPresent, isBlank, StringWrapper;

import "message.dart" show Message;

const I18N_ATTR = "i18n";
const I18N_ATTR_PREFIX = "i18n-";
var CUSTOM_PH_EXP = new RegExp(
    r'\/\/[\s\S]*i18n[\s\S]*\([\s\S]*ph[\s\S]*=[\s\S]*"([\s\S]*?)"[\s\S]*\)');

/**
 * An i18n error.
 */
class I18nError extends ParseError {
  I18nError(ParseSourceSpan span, String msg) : super(span, msg) {
    /* super call moved to initializer */;
  }
}

// Man, this is so ugly!
List<Part> partition(List<HtmlAst> nodes, List<ParseError> errors) {
  var res = <Part>[];
  for (var i = 0; i < nodes.length; ++i) {
    var n = nodes[i];
    var temp = <HtmlAst>[];
    if (_isOpeningComment(n)) {
      var i18n = ((n as HtmlCommentAst)).value.substring(5).trim();
      i++;
      while (!_isClosingComment(nodes[i])) {
        temp.add(nodes[i++]);
        if (identical(i, nodes.length)) {
          errors.add(
              new I18nError(n.sourceSpan, "Missing closing 'i18n' comment."));
          break;
        }
      }
      res.add(new Part(null, null, temp, i18n, true));
    } else if (n is HtmlElementAst) {
      var i18n = _findI18nAttr(n);
      res.add(new Part(n, null, n.children, isPresent(i18n) ? i18n.value : null,
          isPresent(i18n)));
    } else if (n is HtmlTextAst) {
      res.add(new Part(null, n, null, null, false));
    }
  }
  return res;
}

class Part {
  HtmlElementAst rootElement;
  HtmlTextAst rootTextNode;
  List<HtmlAst> children;
  String i18n;
  bool hasI18n;
  Part(this.rootElement, this.rootTextNode, this.children, this.i18n,
      this.hasI18n) {}
  ParseSourceSpan get sourceSpan {
    if (isPresent(this.rootElement))
      return this.rootElement.sourceSpan;
    else if (isPresent(this.rootTextNode))
      return this.rootTextNode.sourceSpan;
    else
      return this.children[0].sourceSpan;
  }

  Message createMessage(Parser parser) {
    return new Message(stringifyNodes(this.children, parser),
        meaning(this.i18n), description(this.i18n));
  }
}

bool _isOpeningComment(HtmlAst n) {
  return n is HtmlCommentAst &&
      isPresent(n.value) &&
      n.value.startsWith("i18n:");
}

bool _isClosingComment(HtmlAst n) {
  return n is HtmlCommentAst && isPresent(n.value) && n.value == "/i18n";
}

HtmlAttrAst _findI18nAttr(HtmlElementAst p) {
  var i18n = p.attrs.where((a) => a.name == I18N_ATTR).toList();
  return i18n.length == 0 ? null : i18n[0];
}

String meaning(String i18n) {
  if (isBlank(i18n) || i18n == "") return null;
  return i18n.split("|")[0];
}

String description(String i18n) {
  if (isBlank(i18n) || i18n == "") return null;
  var parts = i18n.split("|");
  return parts.length > 1 ? parts[1] : null;
}

Message messageFromAttribute(
    Parser parser, HtmlElementAst p, HtmlAttrAst attr) {
  var expectedName = attr.name.substring(5);
  var matching = p.attrs.where((a) => a.name == expectedName).toList();
  if (matching.length > 0) {
    var value =
        removeInterpolation(matching[0].value, matching[0].sourceSpan, parser);
    return new Message(value, meaning(attr.value), description(attr.value));
  } else {
    throw new I18nError(
        p.sourceSpan, '''Missing attribute \'${ expectedName}\'.''');
  }
}

String removeInterpolation(
    String value, ParseSourceSpan source, Parser parser) {
  try {
    var parsed = parser.splitInterpolation(value, source.toString());
    var usedNames = new Map<String, num>();
    if (isPresent(parsed)) {
      var res = "";
      for (var i = 0; i < parsed.strings.length; ++i) {
        res += parsed.strings[i];
        if (i != parsed.strings.length - 1) {
          var customPhName = getPhNameFromBinding(parsed.expressions[i], i);
          customPhName = dedupePhName(usedNames, customPhName);
          res += '''<ph name="${ customPhName}"/>''';
        }
      }
      return res;
    } else {
      return value;
    }
  } catch (e) {
    return value;
  }
}

String getPhNameFromBinding(String input, num index) {
  var customPhMatch = StringWrapper.split(input, CUSTOM_PH_EXP);
  return customPhMatch.length > 1 ? customPhMatch[1] : '''${ index}''';
}

String dedupePhName(Map<String, num> usedNames, String name) {
  var duplicateNameCount = usedNames[name];
  if (isPresent(duplicateNameCount)) {
    usedNames[name] = duplicateNameCount + 1;
    return '''${ name}_${ duplicateNameCount}''';
  } else {
    usedNames[name] = 1;
    return name;
  }
}

String stringifyNodes(List<HtmlAst> nodes, Parser parser) {
  var visitor = new _StringifyVisitor(parser);
  return htmlVisitAll(visitor, nodes).join("");
}

class _StringifyVisitor implements HtmlAstVisitor {
  Parser _parser;
  num _index = 0;
  _StringifyVisitor(this._parser) {}
  dynamic visitElement(HtmlElementAst ast, dynamic context) {
    var name = this._index++;
    var children =
        this._join(htmlVisitAll(this, ast.children) as List<String>, "");
    return '''<ph name="e${ name}">${ children}</ph>''';
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    return null;
  }

  dynamic visitText(HtmlTextAst ast, dynamic context) {
    var index = this._index++;
    var noInterpolation =
        removeInterpolation(ast.value, ast.sourceSpan, this._parser);
    if (noInterpolation != ast.value) {
      return '''<ph name="t${ index}">${ noInterpolation}</ph>''';
    } else {
      return ast.value;
    }
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return "";
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    return null;
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    return null;
  }

  String _join(List<String> strs, String str) {
    return strs.where((s) => s.length > 0).toList().join(str);
  }
}
