library angular2.src.router.rules.rules;

import "dart:async";
import "package:angular2/src/facade/lang.dart" show isPresent, isBlank;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/promise.dart" show PromiseWrapper;
import "package:angular2/src/facade/collection.dart" show Map;
import "route_handlers/route_handler.dart" show RouteHandler;
import "../url_parser.dart" show Url, convertUrlParamsToArray;
import "../instruction.dart" show ComponentInstruction;
import "route_paths/route_path.dart" show RoutePath;
import "route_paths/route_path.dart" show GeneratedUrl;

// RouteMatch objects hold information about a match between a rule and a URL
abstract class RouteMatch {}

class PathMatch extends RouteMatch {
  ComponentInstruction instruction;
  Url remaining;
  List<Url> remainingAux;
  PathMatch(this.instruction, this.remaining, this.remainingAux) : super() {
    /* super call moved to initializer */;
  }
}

class RedirectMatch extends RouteMatch {
  List<dynamic> redirectTo;
  var specificity;
  RedirectMatch(this.redirectTo, this.specificity) : super() {
    /* super call moved to initializer */;
  }
}

// Rules are responsible for recognizing URL segments and generating instructions
abstract class AbstractRule {
  String hash;
  String path;
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
  get path {
    return this._pathRecognizer.toString();
  }

  set path(val) {
    throw new BaseException(
        "you cannot set the path of a RedirectRule directly");
  }

  /**
   * Returns `null` or a `ParsedUrl` representing the new path to match
   */
  Future<RouteMatch> recognize(Url beginningSegment) {
    var match = null;
    if (isPresent(this._pathRecognizer.matchUrl(beginningSegment))) {
      match =
          new RedirectMatch(this.redirectTo, this._pathRecognizer.specificity);
    }
    return PromiseWrapper.resolve(match);
  }

  ComponentInstruction generate(Map<String, dynamic> params) {
    throw new BaseException('''Tried to generate a redirect.''');
  }
}

// represents something like '/foo/:bar'
class RouteRule implements AbstractRule {
  RoutePath _routePath;
  RouteHandler handler;
  String _routeName;
  String specificity;
  bool terminal;
  String hash;
  Map<String, ComponentInstruction> _cache =
      new Map<String, ComponentInstruction>();
  // TODO: cache component instruction instances by params and by ParsedUrl instance
  RouteRule(this._routePath, this.handler, this._routeName) {
    this.specificity = this._routePath.specificity;
    this.hash = this._routePath.hash;
    this.terminal = this._routePath.terminal;
  }
  get path {
    return this._routePath.toString();
  }

  set path(val) {
    throw new BaseException("you cannot set the path of a RouteRule directly");
  }

  Future<RouteMatch> recognize(Url beginningSegment) {
    var res = this._routePath.matchUrl(beginningSegment);
    if (isBlank(res)) {
      return null;
    }
    return this.handler.resolveComponentType().then((_) {
      var componentInstruction =
          this._getInstruction(res.urlPath, res.urlParams, res.allParams);
      return new PathMatch(componentInstruction, res.rest, res.auxiliary);
    });
  }

  ComponentInstruction generate(Map<String, dynamic> params) {
    var generated = this._routePath.generateUrl(params);
    var urlPath = generated.urlPath;
    var urlParams = generated.urlParams;
    return this
        ._getInstruction(urlPath, convertUrlParamsToArray(urlParams), params);
  }

  GeneratedUrl generateComponentPathValues(Map<String, dynamic> params) {
    return this._routePath.generateUrl(params);
  }

  ComponentInstruction _getInstruction(
      String urlPath, List<String> urlParams, Map<String, dynamic> params) {
    if (isBlank(this.handler.componentType)) {
      throw new BaseException(
          '''Tried to get instruction before the type was loaded.''');
    }
    var hashKey = urlPath + "?" + urlParams.join("&");
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
