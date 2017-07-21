import '../../url_parser.dart' show Url;
import 'route_path.dart' show RoutePath, GeneratedUrl, MatchedUrl;

typedef GeneratedUrl RegexSerializer(Map<String, dynamic> params);

class RegexRoutePath implements RoutePath {
  String _reString;
  final RegexSerializer _serializer;
  String hash;
  bool terminal = true;
  String specificity = '2';
  RegExp _regex;
  RegexRoutePath(this._reString, this._serializer) {
    this.hash = this._reString;
    this._regex = new RegExp(this._reString);
  }
  MatchedUrl matchUrl(Url url) {
    var urlPath = url.toString();
    Map<String, String> params = {};
    var matcher = this._regex.allMatches(urlPath);
    if (matcher.isEmpty) {
      return null;
    }
    var i = 0;
    for (var match in matcher) {
      params[i.toString()] = match[i];
      i++;
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
