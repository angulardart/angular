HtmlTagDefinition getHtmlTagDefinition(String tagName) {
  var result = _tagDefinitions[tagName.toLowerCase()];
  return result ?? const HtmlTagDefinition();
}

class HtmlTagDefinition {
  final String implicitNamespacePrefix;
  final bool isVoid;

  const HtmlTagDefinition({this.implicitNamespacePrefix, bool isVoid})
      : this.isVoid = isVoid ?? false;
}
// see http://www.w3.org/TR/html51/syntax.html#optional-tags

// This implementation does not fully conform to the HTML5 spec.
const _tagDefinitions = <String, HtmlTagDefinition>{
  "base": HtmlTagDefinition(isVoid: true),
  "meta": HtmlTagDefinition(isVoid: true),
  "area": HtmlTagDefinition(isVoid: true),
  "embed": HtmlTagDefinition(isVoid: true),
  "link": HtmlTagDefinition(isVoid: true),
  "img": HtmlTagDefinition(isVoid: true),
  "input": HtmlTagDefinition(isVoid: true),
  "param": HtmlTagDefinition(isVoid: true),
  "hr": HtmlTagDefinition(isVoid: true),
  "br": HtmlTagDefinition(isVoid: true),
  "source": HtmlTagDefinition(isVoid: true),
  "track": HtmlTagDefinition(isVoid: true),
  "wbr": HtmlTagDefinition(isVoid: true),
  "col": HtmlTagDefinition(isVoid: true),
  "svg": HtmlTagDefinition(implicitNamespacePrefix: "svg"),
  "math": HtmlTagDefinition(implicitNamespacePrefix: "math"),
};
