import 'dart:async';

import '../instruction.dart' show ComponentInstruction;
import '../url_parser.dart' show Url, convertUrlParamsToArray;
import 'route_handlers/route_handler.dart' show RouteHandler;
import 'route_paths/route_path.dart' show GeneratedUrl, RoutePath;

// RouteMatch objects hold information about a match between a rule and a URL
abstract class RouteMatch {}

class PathMatch extends RouteMatch {
  ComponentInstruction instruction;
  Url remaining;
  List<Url> remainingAux;
  PathMatch(this.instruction, this.remaining, this.remainingAux);
}

class RedirectMatch extends RouteMatch {
  List<dynamic> redirectTo;
  var specificity;
  RedirectMatch(this.redirectTo, this.specificity);
}

// Rules are responsible for recognizing URL segments and generating instructions
abstract class AbstractRule {
  String get hash;
  String get path;
  Future<RouteMatch> recognize(Url beginningSegment);
  ComponentInstruction generate(Map<String, dynamic> params);
}

class RedirectRule implements AbstractRule {
  RoutePath _pathRecognizer;
  List<dynamic> redirectTo;
  String hash;
  RedirectRule(this._pathRecognizer, this.redirectTo) {
    this.hash = this._pathRecognizer.hash;
  }
  String get path {
    return this._pathRecognizer.toString();
  }

  set path(val) {
    throw new StateError('you cannot set the path of a RedirectRule directly');
  }

  /// Returns `null` or a `ParsedUrl` representing the new path to match
  Future<RouteMatch> recognize(Url beginningSegment) {
    RouteMatch match;
    if (_pathRecognizer.matchUrl(beginningSegment) != null) {
      match =
          new RedirectMatch(this.redirectTo, this._pathRecognizer.specificity);
    }
    return new Future<RouteMatch>.value(match);
  }

  ComponentInstruction generate(Map<String, dynamic> params) {
    throw new StateError('Tried to generate a redirect.');
  }
}

// represents something like '/foo/:bar'
class RouteRule implements AbstractRule {
  RoutePath _routePath;
  RouteHandler handler;
  final String _routeName;
  String specificity;
  bool terminal;
  String hash;
  final _cache = new Map<String, ComponentInstruction>();
  // TODO: cache component instruction instances by params and by ParsedUrl instance
  RouteRule(this._routePath, this.handler, this._routeName) {
    this.specificity = this._routePath.specificity;
    this.hash = this._routePath.hash;
    this.terminal = this._routePath.terminal;
  }
  String get path {
    return this._routePath.toString();
  }

  set path(val) {
    throw new StateError('you cannot set the path of a RouteRule directly');
  }

  Future<RouteMatch> recognize(Url beginningSegment) {
    var res = this._routePath.matchUrl(beginningSegment);
    if (res == null) {
      return null;
    }
    return this.handler.resolveComponentType().then((_) {
      var componentInstruction = this._getInstruction(
          res.urlPath, res.urlParams, res.allParams as Map<String, String>);
      return new PathMatch(componentInstruction, res.rest, res.auxiliary);
    });
  }

  ComponentInstruction generate(Map<String, dynamic> params) {
    var generated = this._routePath.generateUrl(params);
    var urlPath = generated.urlPath;
    var urlParams = generated.urlParams;
    return this._getInstruction(urlPath, convertUrlParamsToArray(urlParams),
        params as Map<String, String>);
  }

  GeneratedUrl generateComponentPathValues(Map<String, dynamic> params) {
    return this._routePath.generateUrl(params);
  }

  ComponentInstruction _getInstruction(
      String urlPath, List<String> urlParams, Map<String, String> params) {
    if (handler.componentType == null) {
      throw new StateError(
          'Tried to get instruction before the type was loaded.');
    }
    var hashKey = urlPath + '?' + urlParams.join('&');
    if (this._cache.containsKey(hashKey)) {
      return this._cache[hashKey];
    }
    var instruction = new ComponentInstruction(
        urlPath,
        urlParams,
        this.handler.data,
        this.handler.componentType,
        this.terminal,
        this.specificity,
        params,
        this._routeName);
    this._cache[hashKey] = instruction;
    return instruction;
  }
}
