class StyleWithImports {
  final String style;
  final List<String> styleUrls;
  StyleWithImports(this.style, this.styleUrls);
}

/// Whether [url] resides within the current package or a dependency.
bool isStyleUrlResolvable(String url) {
  if (url == null || url.isEmpty || url[0] == '/') return false;
  var schemeMatch = _urlWithSchemaRe.firstMatch(url);
  return schemeMatch == null ||
      schemeMatch[1] == 'package' ||
      schemeMatch[1] == 'asset';
}

/// Rewrites style sheets by resolving and removing the @import urls that
/// are either relative or don't have a `package:` scheme
StyleWithImports extractStyleUrls(String baseUrl, String cssText) {
  Uri baseUri;
  var foundUrls = <String>[];
  var modifiedCssText = cssText.replaceAllMapped(_cssImportRe, (m) {
    var url = m[1] ?? m[2];
    if (!isStyleUrlResolvable(url)) {
      // Do not attempt to resolve non-package absolute URLs with URI scheme
      return m[0];
    }
    baseUri ??= Uri.parse(baseUrl);
    foundUrls.add(baseUri.resolve(url).toString());
    return '';
  });
  return StyleWithImports(modifiedCssText, foundUrls);
}

final _cssImportRe = RegExp(r'@import\s+(?:url\()?\s*(?:(?:[' +
    "'" +
    r'"]([^' +
    "'" +
    r'"]*))|([^;\)\s]*))[^;]*;?');
final _urlWithSchemaRe = RegExp('^([^:/?#]+):');
