import "package:angular2/src/compiler/html_ast.dart"
    show HtmlAst, HtmlElementAst;
import "package:angular2/src/compiler/html_parser.dart" show HtmlParser;
import "package:angular2/src/compiler/parse_util.dart"
    show ParseSourceSpan, ParseError;
import "package:angular2/src/facade/lang.dart"
    show isPresent, isBlank, RegExpWrapper;

import "message.dart" show Message, id;

var _PLACEHOLDER_REGEXP =
    RegExpWrapper.create('''\\<ph(\\s)+name=("(\\w)+")\\/\\>''');
const _ID_ATTR = "id";
const _MSG_ELEMENT = "msg";
const _BUNDLE_ELEMENT = "message-bundle";
String serializeXmb(List<Message> messages) {
  var ms = messages.map((m) => _serializeMessage(m)).toList().join("");
  return '''<message-bundle>${ ms}</message-bundle>''';
}

class XmbDeserializationResult {
  String content;
  Map<String, List<HtmlAst>> messages;
  List<ParseError> errors;
  XmbDeserializationResult(this.content, this.messages, this.errors) {}
}

class XmbDeserializationError extends ParseError {
  XmbDeserializationError(ParseSourceSpan span, String msg) : super(span, msg) {
    /* super call moved to initializer */;
  }
}

XmbDeserializationResult deserializeXmb(String content, String url) {
  var parser = new HtmlParser();
  var normalizedContent = _expandPlaceholder(content.trim());
  var parsed = parser.parse(normalizedContent, url);
  if (parsed.errors.length > 0) {
    return new XmbDeserializationResult(null, {}, parsed.errors);
  }
  if (_checkRootElement(parsed.rootNodes)) {
    return new XmbDeserializationResult(null, {}, [
      new XmbDeserializationError(
          null, '''Missing element "${ _BUNDLE_ELEMENT}"''')
    ]);
  }
  var bundleEl = (parsed.rootNodes[0] as HtmlElementAst);
  var errors = <ParseError>[];
  Map<String, List<HtmlAst>> messages = {};
  _createMessages(bundleEl.children, messages, errors);
  return (errors.length == 0)
      ? new XmbDeserializationResult(normalizedContent, messages, [])
      : new XmbDeserializationResult(null, <String, List<HtmlAst>>{}, errors);
}

bool _checkRootElement(List<HtmlAst> nodes) {
  return nodes.length < 1 ||
      !(nodes[0] is HtmlElementAst) ||
      ((nodes[0] as HtmlElementAst)).name != _BUNDLE_ELEMENT;
}

void _createMessages(List<HtmlAst> nodes, Map<String, List<HtmlAst>> messages,
    List<ParseError> errors) {
  nodes.forEach((item) {
    if (item is HtmlElementAst) {
      HtmlElementAst msg = item;
      if (msg.name != _MSG_ELEMENT) {
        errors.add(new XmbDeserializationError(
            item.sourceSpan, '''Unexpected element "${ msg . name}"'''));
        return;
      }
      var id = _id(msg);
      if (isBlank(id)) {
        errors.add(new XmbDeserializationError(
            item.sourceSpan, '''"${ _ID_ATTR}" attribute is missing'''));
        return;
      }
      messages[id] = msg.children;
    }
  });
}

String _id(HtmlElementAst el) {
  var ids = el.attrs.where((a) => a.name == _ID_ATTR).toList();
  return ids.length > 0 ? ids[0].value : null;
}

String _serializeMessage(Message m) {
  var desc =
      isPresent(m.description) ? ''' desc=\'${ m . description}\'''' : "";
  return '''<msg id=\'${ id ( m )}\'${ desc}>${ m . content}</msg>''';
}

String _expandPlaceholder(String input) {
  return RegExpWrapper.replaceAll(_PLACEHOLDER_REGEXP, input, (match) {
    var nameWithQuotes = match[2];
    return '''<ph name=${ nameWithQuotes}></ph>''';
  });
}
