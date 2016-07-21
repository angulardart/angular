import "../../url_parser.dart" show Url;

class MatchedUrl {
  String urlPath;
  List<String> urlParams;
  Map<String, dynamic> allParams;
  List<Url> auxiliary;
  Url rest;
  MatchedUrl(this.urlPath, this.urlParams, this.allParams, this.auxiliary,
      this.rest) {}
}

class GeneratedUrl {
  String urlPath;
  Map<String, dynamic> urlParams;
  GeneratedUrl(this.urlPath, this.urlParams) {}
}

abstract class RoutePath {
  String specificity;
  bool terminal;
  String hash;
  MatchedUrl matchUrl(Url url);
  GeneratedUrl generateUrl(Map<String, dynamic> params);
  String toString();
}
