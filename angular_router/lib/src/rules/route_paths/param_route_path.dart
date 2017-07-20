import '../../url_parser.dart' show Url, RootUrl, convertUrlParamsToArray;
import '../../utils.dart' show TouchMap, normalizeString;
import 'route_path.dart' show RoutePath, GeneratedUrl, MatchedUrl;

/// `ParamRoutePath`s are made up of `PathSegment`s, each of which can
/// match a segment of a URL. Different kind of `PathSegment`s match
/// URL segments in different ways...
abstract class PathSegment {
  String get name;
  String generate(TouchMap params);
  bool match(String path);
  String specificity;
  String hash;
}

/// Identified by a `...` URL segment. This indicates that the
/// Route will continue to be matched by child `Router`s.
class ContinuationPathSegment implements PathSegment {
  String name = '';
  var specificity = '';
  var hash = '...';
  String generate(TouchMap params) {
    return '';
  }

  bool match(String path) {
    return true;
  }
}

/// Identified by a string not starting with a `:` or `*`.
/// Only matches the URL segments that equal the segment path
class StaticPathSegment implements PathSegment {
  String path;
  String name = '';
  var specificity = '2';
  String hash;
  StaticPathSegment(this.path) {
    this.hash = path;
  }
  bool match(String path) {
    return path == this.path;
  }

  String generate(TouchMap params) {
    return this.path;
  }
}

/// Identified by a string starting with `:`. Indicates a segment
/// that can contain a value that will be extracted and provided to
/// a matching `Instruction`.
class DynamicPathSegment implements PathSegment {
  final String name;
  static var paramMatcher = new RegExp(r'^:([^\/]+)$');
  var specificity = '1';
  var hash = ':';
  DynamicPathSegment(this.name);
  bool match(String path) {
    return path.length > 0;
  }

  String generate(TouchMap params) {
    if (!params.map.containsKey(name)) {
      throw new ArgumentError(
          'Route generator for "$name" was not included in parameters passed.');
    }
    return encodeDynamicSegment(normalizeString(params.get(name)));
  }
}

/// Identified by a string starting with `*` Indicates that all the following
/// segments match this route and that the value of these segments should
/// be provided to a matching `Instruction`.
class StarPathSegment implements PathSegment {
  final String name;
  static var wildcardMatcher = new RegExp(r'^\*([^\/]+)$');
  var specificity = '0';
  var hash = '*';
  StarPathSegment(this.name);
  bool match(String path) {
    return true;
  }

  String generate(TouchMap params) {
    return normalizeString(params.get(this.name));
  }
}

/// Parses a URL string using a given matcher DSL, and generates URLs from param
/// maps.
class ParamRoutePath implements RoutePath {
  String routePath;
  String specificity;
  bool terminal = true;
  String hash;
  List<PathSegment> _segments;

  /// Takes a string representing the matcher DSL.
  ParamRoutePath(this.routePath) {
    this._assertValidPath(routePath);
    this._parsePathString(routePath);
    this.specificity = this._calculateSpecificity();
    this.hash = this._calculateHash();
    var lastSegment = this._segments[this._segments.length - 1];
    this.terminal = !(lastSegment is ContinuationPathSegment);
  }
  MatchedUrl matchUrl(Url url) {
    var nextUrlSegment = url;
    Url currentUrlSegment;
    var positionalParams = <String, dynamic>{};
    List<String> captured = [];
    for (var i = 0; i < this._segments.length; i += 1) {
      var pathSegment = this._segments[i];
      currentUrlSegment = nextUrlSegment;
      if (pathSegment is ContinuationPathSegment) {
        break;
      }
      if (currentUrlSegment != null) {
        // The star segment consumes all of the remaining URL, including matrix
        // params.
        if (pathSegment is StarPathSegment) {
          positionalParams[pathSegment.name] = currentUrlSegment.toString();
          captured.add(currentUrlSegment.toString());
          nextUrlSegment = null;
          break;
        }
        captured.add(currentUrlSegment.path);
        if (pathSegment is DynamicPathSegment) {
          positionalParams[pathSegment.name] =
              decodeDynamicSegment(currentUrlSegment.path);
        } else if (!pathSegment.match(currentUrlSegment.path)) {
          return null;
        }
        nextUrlSegment = currentUrlSegment.child;
      } else if (!pathSegment.match('')) {
        return null;
      }
    }
    if (this.terminal && nextUrlSegment != null) {
      return null;
    }
    var urlPath = captured.join('/');
    var auxiliary = <Url>[];
    var urlParams = <String>[];
    var allParams = positionalParams;
    if (currentUrlSegment != null) {
      // If this is the root component, read query params. Otherwise, read
      // matrix params.
      var paramsSegment = url is RootUrl ? url : currentUrlSegment;
      if (paramsSegment.params != null) {
        allParams = new Map<String, dynamic>.from(paramsSegment.params)
          ..addAll(positionalParams);
        urlParams = convertUrlParamsToArray(paramsSegment.params);
      } else {
        allParams = positionalParams;
      }
      auxiliary = currentUrlSegment.auxiliary;
    }
    return new MatchedUrl(
        urlPath, urlParams, allParams, auxiliary, nextUrlSegment);
  }

  GeneratedUrl generateUrl(Map<String, dynamic> params) {
    var paramTokens = new TouchMap(params);
    var path = [];
    for (var i = 0; i < this._segments.length; i++) {
      var segment = this._segments[i];
      if (!(segment is ContinuationPathSegment)) {
        var generated = segment.generate(paramTokens);
        if (generated != null || !(segment is StarPathSegment)) {
          path.add(generated);
        }
      }
    }
    var urlPath = path.join('/');
    var nonPositionalParams = paramTokens.getUnused();
    var urlParams = nonPositionalParams;
    return new GeneratedUrl(urlPath, urlParams);
  }

  String toString() {
    return this.routePath;
  }

  void _parsePathString(String routePath) {
    // Normalize route as not starting with a '/'. Recognition will also
    // normalize.
    if (routePath.startsWith('/')) {
      routePath = routePath.substring(1);
    }
    var segmentStrings = routePath.split('/');
    this._segments = [];
    var limit = segmentStrings.length - 1;
    for (var i = 0; i <= limit; i++) {
      var segment = segmentStrings[i], match;
      if ((match = DynamicPathSegment.paramMatcher.firstMatch(segment)) !=
          null) {
        this._segments.add(new DynamicPathSegment(match[1]));
      } else if ((match =
              StarPathSegment.wildcardMatcher.firstMatch(segment)) !=
          null) {
        this._segments.add(new StarPathSegment(match[1]));
      } else if (segment == '...') {
        if (i < limit) {
          throw new ArgumentError(
              'Unexpected "..." before the end of the path for "$routePath".');
        }
        this._segments.add(new ContinuationPathSegment());
      } else {
        this._segments.add(new StaticPathSegment(segment));
      }
    }
  }

  String _calculateSpecificity() {
    // The 'specificity' of a path is used to determine which route is used when
    // multiple routes match a URL. Static segments (like '/foo') are the most
    // specific, followed by dynamic segments (like '/:id'). Star segments
    // add no specificity. Segments at the start of the path are more specific
    // than proceeding ones.
    //
    // The code below uses place values to combine the different types of
    // segments into a single string that we can sort later. Each static segment
    // is marked as a specificity of '2,' each dynamic segment is worth '1'
    // specificity, and stars are worth '0' specificity.
    var i, length = this._segments.length, specificity;
    if (length == 0) {
      // a single slash (or 'empty segment' is as specific as a static segment
      specificity += '2';
    } else {
      specificity = '';
      for (i = 0; i < length; i++) {
        specificity += this._segments[i].specificity;
      }
    }
    return specificity;
  }

  String _calculateHash() {
    // this function is used to determine whether a route config path like
    // `/foo/:id` collides with `/foo/:name`.
    var i, length = this._segments.length;
    var hashParts = [];
    for (i = 0; i < length; i++) {
      hashParts.add(this._segments[i].hash);
    }
    return hashParts.join('/');
  }

  void _assertValidPath(String path) {
    if (path.contains('#')) {
      throw new ArgumentError(
          'Path "$path" should not include "#". Use "HashLocationStrategy" '
          'instead.');
    }
    var illegalCharacter = ParamRoutePath.RESERVED_CHARS.firstMatch(path);
    if (illegalCharacter != null) {
      throw new ArgumentError(
          'Path "$path" contains "${ illegalCharacter [ 0 ]}" which is not '
          'allowed in a route config.');
    }
  }

  static final RESERVED_CHARS = new RegExp('//|\\(|\\)|;|\\?|=');
}

final RegExp REGEXP_PERCENT = new RegExp(r'%');
final RegExp REGEXP_SLASH = new RegExp(r'\/');
final RegExp REGEXP_OPEN_PARENT = new RegExp(r'\(');
final RegExp REGEXP_CLOSE_PARENT = new RegExp(r'\)');
final RegExp REGEXP_SEMICOLON = new RegExp(r';');
String encodeDynamicSegment(String value) {
  if (value == null) {
    return null;
  }
  value = value.replaceAll(REGEXP_PERCENT, '%25');
  value = value.replaceAll(REGEXP_SLASH, '%2F');
  value = value.replaceAll(REGEXP_OPEN_PARENT, '%28');
  value = value.replaceAll(REGEXP_CLOSE_PARENT, '%29');
  value = value.replaceAll(REGEXP_SEMICOLON, '%3B');
  return value;
}

var REGEXP_ENC_SEMICOLON = new RegExp(r'%3B', caseSensitive: false);
var REGEXP_ENC_CLOSE_PARENT = new RegExp(r'%29', caseSensitive: false);
var REGEXP_ENC_OPEN_PARENT = new RegExp(r'%28', caseSensitive: false);
var REGEXP_ENC_SLASH = new RegExp(r'%2F', caseSensitive: false);
var REGEXP_ENC_PERCENT = new RegExp(r'%25', caseSensitive: false);
String decodeDynamicSegment(String value) {
  if (value == null) {
    return null;
  }
  value = value.replaceAll(REGEXP_ENC_SEMICOLON, ';');
  value = value.replaceAll(REGEXP_ENC_CLOSE_PARENT, ')');
  value = value.replaceAll(REGEXP_ENC_OPEN_PARENT, '(');
  value = value.replaceAll(REGEXP_ENC_SLASH, '/');
  value = value.replaceAll(REGEXP_ENC_PERCENT, '%');
  return value;
}
