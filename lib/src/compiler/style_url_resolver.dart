// Some of the code comes from WebComponents.JS
// https://github.com/webcomponents/webcomponentsjs/blob/master/src/HTMLImports/path.js

import "package:angular2/src/compiler/url_resolver.dart" show UrlResolver;

class StyleWithImports {
  String style;
  List<String> styleUrls;
  StyleWithImports(this.style, this.styleUrls);
}

bool isStyleUrlResolvable(String url) {
  if (url == null || url.isEmpty || url[0] == "/") return false;
  var schemeMatch = _urlWithSchemaRe.firstMatch(url);
  return schemeMatch == null ||
      schemeMatch[1] == "package" ||
      schemeMatch[1] == "asset";
}

/// Rewrites stylesheets by resolving and removing the @import urls that
/// are either relative or don't have a `package:` scheme
StyleWithImports extractStyleUrls(
    UrlResolver resolver, String baseUrl, String cssText) {
  var foundUrls = <String>[];
  var modifiedCssText = cssText.replaceAllMapped(_cssImportRe, (m) {
    var url = m[1] ?? m[2];
    if (!isStyleUrlResolvable(url)) {
      // Do not attempt to resolve non-package absolute URLs with URI scheme
      return m[0];
    }
    foundUrls.add(resolver.resolve(baseUrl, url));
    return "";
  });
  return new StyleWithImports(modifiedCssText, foundUrls);
}

var _cssImportRe = new RegExp(r'@import\s+(?:url\()?\s*(?:(?:[' +
    "'" +
    r'"]([^' +
    "'" +
    r'"]*))|([^;\)\s]*))[^;]*;?');
// TODO: can't use /^[^:/?#.]+:/g due to clang-format bug:

//       https://github.com/angular/angular/issues/4596
var _urlWithSchemaRe = new RegExp(r'^([a-zA-Z\-\+\.]+):');
