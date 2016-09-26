import 'package:angular2/src/core/application_tokens.dart'
    show PACKAGE_ROOT_URL;
import 'package:angular2/src/core/di.dart' show Injectable, Inject, Provider;

const _ASSET_SCHEME = 'asset:';

UrlResolver createUrlResolverWithoutPackagePrefix() {
  return new UrlResolver.withUrlPrefix(null);
}

UrlResolver createOfflineCompileUrlResolver() {
  return new UrlResolver.withUrlPrefix(_ASSET_SCHEME);
}

const DEFAULT_PACKAGE_URL_PROVIDER =
    const Provider(PACKAGE_ROOT_URL, useValue: "/packages");

@Injectable()
class UrlResolver {
  /// This will be the location where 'package:' Urls will resolve. Default is
  /// '/packages'
  final String _packagePrefix;

  UrlResolver([@Inject(PACKAGE_ROOT_URL) this._packagePrefix]);

  /// Creates a UrlResolver that will resolve 'package:' Urls to a different
  /// prefixed location.
  const UrlResolver.withUrlPrefix(this._packagePrefix);

  /// Resolves the `url` given the `baseUrl`:
  /// - when the `url` is null, the `baseUrl` is returned,
  /// - if `url` is relative ('path/to/here', './path/to/here'), the resolved url is a combination of
  /// `baseUrl` and `url`,
  /// - if `url` is absolute (it has a scheme: 'http://', 'https://' or start with '/'), the `url` is
  /// returned as is (ignoring the `baseUrl`)
  ///
  /// @param {string} baseUrl
  /// @param {string} url
  /// @returns {string} the resolved URL
  String resolve(String baseUrl, String url) {
    Uri uri = Uri.parse(url);

    if (baseUrl != null && baseUrl.length > 0) {
      Uri baseUri = Uri.parse(baseUrl);
      uri = baseUri.resolveUri(uri);
    }

    var prefix = this._packagePrefix;
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
}

// Inline two functions originally in TS facades due to them not being simple
// enough to inline in the function above.

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

String getUrlScheme(String url) {
  return Uri.parse(url).scheme;
}
