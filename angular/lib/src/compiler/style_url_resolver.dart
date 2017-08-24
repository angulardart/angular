// Some of the code comes from WebComponents.JS
// https://github.com/webcomponents/webcomponentsjs/blob/master/src/HTMLImports/path.js

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
StyleWithImports extractStyleUrls(String baseUrl, String cssText) {
  var foundUrls = <String>[];
  var modifiedCssText = cssText.replaceAllMapped(_cssImportRe, (m) {
    var url = m[1] ?? m[2];
    if (!isStyleUrlResolvable(url)) {
      // Do not attempt to resolve non-package absolute URLs with URI scheme
      return m[0];
    }
    foundUrls.add(resolveUrl(baseUrl, url));
    return "";
  });
  return new StyleWithImports(modifiedCssText, foundUrls);
}

/// Resolves the `url` given the `baseUrl`:
/// - when the `url` is null, the `baseUrl` is returned,
/// - if `url` is relative ('path/to/here', './path/to/here'), the resolved
///   url is a combination of `baseUrl` and `url`,
/// - if `url` is absolute (it has a scheme: 'http://', 'https://' or start
///   with '/'), the `url` is returned as is (ignoring the `baseUrl`)
///
/// @param {string} baseUrl
/// @param {string} url
/// @returns {string} the resolved URL
String resolveUrl(String baseUrl, String url) {
  Uri uri = Uri.parse(url);
  if (baseUrl != null && baseUrl.length > 0) {
    Uri baseUri = Uri.parse(baseUrl);
    uri = baseUri.resolveUri(uri);
  }
  var prefix = 'packages';
  if (prefix != null && uri.scheme == 'package') {
    if (prefix == _ASSET_SCHEME) {
      var pathSegments = uri.pathSegments.toList()..insert(1, 'lib');
      return new Uri(scheme: 'asset', pathSegments: pathSegments).toString();
    } else {
      prefix = _removeTrailingSlash(prefix);
      var path = _removeLeadingChars(uri.path);
      return '$prefix/$path';
    }
  } else {
    return uri.toString();
  }
}

const _ASSET_SCHEME = 'asset:';

String _removeLeadingChars(String s) {
  if (s?.isNotEmpty == true) {
    var pos = 0;
    for (var i = 0; i < s.length; i++) {
      if (s[i] != '/') break;
      pos++;
    }
    s = s.substring(pos);
  }
  return s;
}

String _removeTrailingSlash(String s) {
  if (s?.isNotEmpty == true) {
    var pos = s.length;
    for (var i = s.length - 1; i >= 0; i--) {
      if (s[i] != '/') break;
      pos--;
    }
    s = s.substring(0, pos);
  }
  return s;
}

var _cssImportRe = new RegExp(r'@import\s+(?:url\()?\s*(?:(?:[' +
    "'" +
    r'"]([^' +
    "'" +
    r'"]*))|([^;\)\s]*))[^;]*;?');
// TODO: can't use /^[^:/?#.]+:/g due to clang-format bug:

//       https://github.com/angular/angular/issues/4596
var _urlWithSchemaRe = new RegExp(r'^([a-zA-Z\-\+\.]+):');
