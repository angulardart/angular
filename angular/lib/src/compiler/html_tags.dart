class HtmlTagDefinition {
  final String implicitNamespacePrefix;
  final bool isVoid;

  const HtmlTagDefinition({this.implicitNamespacePrefix, bool isVoid})
      : this.isVoid = isVoid ?? false;
}
// see http://www.w3.org/TR/html51/syntax.html#optional-tags

// This implementation does not fully conform to the HTML5 spec.
const _tagDefinitions = const <String, HtmlTagDefinition>{
  "base": const HtmlTagDefinition(isVoid: true),
  "meta": const HtmlTagDefinition(isVoid: true),
  "area": const HtmlTagDefinition(isVoid: true),
  "embed": const HtmlTagDefinition(isVoid: true),
  "link": const HtmlTagDefinition(isVoid: true),
  "img": const HtmlTagDefinition(isVoid: true),
  "input": const HtmlTagDefinition(isVoid: true),
  "param": const HtmlTagDefinition(isVoid: true),
  "hr": const HtmlTagDefinition(isVoid: true),
  "br": const HtmlTagDefinition(isVoid: true),
  "source": const HtmlTagDefinition(isVoid: true),
  "track": const HtmlTagDefinition(isVoid: true),
  "wbr": const HtmlTagDefinition(isVoid: true),
  "col": const HtmlTagDefinition(isVoid: true),
  "svg": const HtmlTagDefinition(implicitNamespacePrefix: "svg"),
  "math": const HtmlTagDefinition(implicitNamespacePrefix: "math"),
};
HtmlTagDefinition getHtmlTagDefinition(String tagName) {
  var result = _tagDefinitions[tagName.toLowerCase()];
  return result ?? const HtmlTagDefinition();
}

final _nsPrefixRegExp = new RegExp(r'^@([^:]+):(.+)');
List<String> splitNsName(String elementName) {
  if (elementName[0] != "@") {
    return [null, elementName];
  }
  var match = _nsPrefixRegExp.firstMatch(elementName);
  return [match[1], match[2]];
}

String mergeNsAndName(String prefix, String localName) {
  return prefix != null ? '@$prefix:$localName' : localName;
}
