import "package:angular2/src/facade/lang.dart"
    show RegExpWrapper, RegExpMatcherWrapper, isBlank;

import "../../url_parser.dart" show Url;
import "route_path.dart" show RoutePath, GeneratedUrl, MatchedUrl;

typedef GeneratedUrl RegexSerializer(Map<String, dynamic> params);

class RegexRoutePath implements RoutePath {
  String _reString;
  RegexSerializer _serializer;
  String hash;
  bool terminal = true;
  String specificity = "2";
  RegExp _regex;
  RegexRoutePath(this._reString, this._serializer) {
    this.hash = this._reString;
    this._regex = RegExpWrapper.create(this._reString);
  }
  MatchedUrl matchUrl(Url url) {
    var urlPath = url.toString();
    Map<String, String> params = {};
    var matcher = RegExpWrapper.matcher(this._regex, urlPath);
    var match = RegExpMatcherWrapper.next(matcher);
    if (isBlank(match)) {
      return null;
    }
    for (var i = 0; i < match.length; i += 1) {
      params[i.toString()] = match[i];
    }
    return new MatchedUrl(urlPath, [], params, [], null);
  }

  GeneratedUrl generateUrl(Map<String, dynamic> params) {
    return this._serializer(params);
  }

  String toString() {
    return this._reString;
  }
}
