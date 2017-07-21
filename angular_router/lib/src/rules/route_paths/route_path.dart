import '../../url_parser.dart' show Url;

class MatchedUrl {
  final String urlPath;
  final List<String> urlParams;
  final Map<String, dynamic> allParams;
  final List<Url> auxiliary;
  final Url rest;
  MatchedUrl(
      this.urlPath, this.urlParams, this.allParams, this.auxiliary, this.rest);
}

class GeneratedUrl {
  final String urlPath;
  final Map<String, dynamic> urlParams;
  GeneratedUrl(this.urlPath, this.urlParams);
}

abstract class RoutePath {
  String specificity;
  bool terminal;
  String hash;
  MatchedUrl matchUrl(Url url);
  GeneratedUrl generateUrl(Map<String, dynamic> params);
  String toString();
}
