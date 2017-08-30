List<String> convertUrlParamsToArray(Map<String, dynamic> urlParams) {
  var paramsArray = <String>[];
  if (urlParams == null) {
    return [];
  }
  urlParams.forEach((key, value) {
    paramsArray.add((identical(value, true)) ? key : key + '=' + value);
  });
  return paramsArray;
}

// Convert an object of url parameters into a string that can be used in an URL
String serializeParams(Map<String, dynamic> urlParams, [joiner = '&']) {
  return convertUrlParamsToArray(urlParams).join(joiner);
}

/// This class represents a parsed URL
class Url {
  String path;
  Url child;
  List<Url> auxiliary;
  Map<String, dynamic> params;
  Url(this.path,
      [this.child = null, this.auxiliary = const [], this.params = const {}]);
  String toString() {
    return this.path +
        this._matrixParamsToString() +
        this._auxToString() +
        this._childString();
  }

  String segmentToString() {
    return this.path + this._matrixParamsToString();
  }

  String _auxToString() {
    return this.auxiliary.length > 0
        ? ('(' +
            this
                .auxiliary
                .map((sibling) => sibling.toString())
                .toList()
                .join('//') +
            ')')
        : '';
  }

  String _matrixParamsToString() {
    var paramString = serializeParams(this.params, ';');
    if (paramString.length > 0) {
      return ';' + paramString;
    }
    return '';
  }

  String _childString() {
    return this.child != null ? ('/' + this.child.toString()) : '';
  }
}

class RootUrl extends Url {
  RootUrl(String path,
      [Url child = null,
      List<Url> auxiliary = const [],
      Map<String, dynamic> params = null])
      : super(path, child, auxiliary, params);
  String toString() {
    return this.path +
        this._auxToString() +
        this._childString() +
        this._queryParamsToString();
  }

  String segmentToString() {
    return this.path + this._queryParamsToString();
  }

  String _queryParamsToString() =>
      params == null ? '' : '?${serializeParams(params)}';
}

Url pathSegmentsToUrl(List<String> pathSegments) {
  var url = new Url(pathSegments[pathSegments.length - 1]);
  for (var i = pathSegments.length - 2; i >= 0; i -= 1) {
    url = new Url(pathSegments[i], url);
  }
  return url;
}

final RegExp SEGMENT_RE = new RegExp('^[^\\/\\(\\)\\?;=&#]+');
String matchUrlSegment(String str) {
  var match = SEGMENT_RE.firstMatch(str);
  return match != null ? match[0] : '';
}

final RegExp QUERY_PARAM_KEY_RE = new RegExp('^[^\\(\\);=&#]+');
String matchUrlQueryParamKey(String str) {
  var match = QUERY_PARAM_KEY_RE.firstMatch(str);
  return match != null ? match[0] : '';
}

final RegExp QUERY_PARAM_VALUE_RE = new RegExp('^[^\\(\\);&#]+');
String matchUrlQueryParamValue(String str) {
  var match = QUERY_PARAM_VALUE_RE.firstMatch(str);
  return match != null ? match[0] : '';
}

class UrlParser {
  String _remaining;
  bool peekStartsWith(String str) {
    return this._remaining.startsWith(str);
  }

  void capture(String str) {
    if (!this._remaining.startsWith(str)) {
      throw new StateError('Expected "$str".');
    }
    this._remaining = this._remaining.substring(str.length);
  }

  Url parse(String url) {
    this._remaining = url;
    if (url == '' || url == '/') {
      return new Url('');
    }
    return this.parseRoot();
  }

  // segment + (aux segments) + (query params)
  RootUrl parseRoot() {
    if (this.peekStartsWith('/')) {
      this.capture('/');
    }
    var path = matchUrlSegment(this._remaining);
    this.capture(path);
    List<Url> aux = [];
    if (this.peekStartsWith('(')) {
      aux = this.parseAuxiliaryRoutes();
    }
    if (this.peekStartsWith(';')) {
      // TODO: should these params just be dropped?
      this.parseMatrixParams();
    }
    var child;
    if (this.peekStartsWith('/') && !this.peekStartsWith('//')) {
      this.capture('/');
      child = this.parseSegment();
    }
    Map<String, dynamic> queryParams;
    if (this.peekStartsWith('?')) {
      queryParams = this.parseQueryParams();
    }
    return new RootUrl(path, child, aux, queryParams);
  }

  // segment + (matrix params) + (aux segments)
  Url parseSegment() {
    if (this._remaining.length == 0) {
      return null;
    }
    if (this.peekStartsWith('/')) {
      this.capture('/');
    }
    var path = matchUrlSegment(this._remaining);
    this.capture(path);
    Map<String, dynamic> matrixParams;
    if (this.peekStartsWith(';')) {
      matrixParams = this.parseMatrixParams();
    }
    List<Url> aux = [];
    if (this.peekStartsWith('(')) {
      aux = this.parseAuxiliaryRoutes();
    }
    Url child;
    if (this.peekStartsWith('/') && !this.peekStartsWith('//')) {
      this.capture('/');
      child = this.parseSegment();
    }
    return new Url(path, child, aux, matrixParams);
  }

  Map<String, dynamic> parseQueryParams() {
    Map<String, dynamic> params = {};
    this.capture('?');
    this.parseQueryParam(params);
    while (this._remaining.length > 0 && this.peekStartsWith('&')) {
      this.capture('&');
      this.parseQueryParam(params);
    }
    return params;
  }

  Map<String, dynamic> parseMatrixParams() {
    Map<String, dynamic> params = {};
    while (this._remaining.length > 0 && this.peekStartsWith(';')) {
      this.capture(';');
      this.parseParam(params);
    }
    return params;
  }

  void parseParam(Map<String, dynamic> params) {
    var key = matchUrlQueryParamKey(this._remaining);
    if (key == null) {
      return;
    }
    this.capture(key);
    dynamic value = true;
    if (this.peekStartsWith('=')) {
      this.capture('=');
      var valueMatch = matchUrlSegment(this._remaining);
      if (valueMatch != null) {
        value = valueMatch;
        this.capture(value);
      }
    }
    params[key] = value;
  }

  void parseQueryParam(Map<String, dynamic> params) {
    var key = matchUrlSegment(this._remaining);
    if (key == null) {
      return;
    }
    this.capture(key);
    dynamic value = true;
    if (this.peekStartsWith('=')) {
      this.capture('=');
      var valueMatch = matchUrlQueryParamValue(this._remaining);
      if (valueMatch != null) {
        value = valueMatch;
        this.capture(value);
      }
    }
    params[key] = value;
  }

  List<Url> parseAuxiliaryRoutes() {
    List<Url> routes = [];
    this.capture('(');
    while (!this.peekStartsWith(')') && this._remaining.length > 0) {
      routes.add(this.parseSegment());
      if (this.peekStartsWith('//')) {
        this.capture('//');
      }
    }
    this.capture(')');
    return routes;
  }
}

var parser = new UrlParser();
