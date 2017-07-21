import 'dart:async';

import '../instruction.dart' show ComponentInstruction;
import '../route_config/route_config_decorator.dart'
    show Route, AsyncRoute, AuxRoute, Redirect, RouteDefinition;
import '../rules/route_paths/regex_route_path.dart' show RegexSerializer;
import '../url_parser.dart' show Url;
import 'route_handlers/async_route_handler.dart' show AsyncRouteHandler;
import 'route_handlers/sync_route_handler.dart' show SyncRouteHandler;
import 'route_paths/param_route_path.dart' show ParamRoutePath;
import 'route_paths/regex_route_path.dart' show RegexRoutePath;
import 'route_paths/route_path.dart' show RoutePath;
import 'rules.dart'
    show AbstractRule, RouteRule, RedirectRule, RouteMatch, PathMatch;

/// A `RuleSet` is responsible for recognizing routes for a particular component.
/// It is consumed by `RouteRegistry`, which knows how to recognize an entire hierarchy of
/// components.
class RuleSet {
  var rulesByName = new Map<String, RouteRule>();
  // map from name to rule
  var auxRulesByName = new Map<String, RouteRule>();
  // map from starting path to rule
  var auxRulesByPath = new Map<String, RouteRule>();
  // TODO: optimize this into a trie
  List<AbstractRule> rules = [];
  // the rule to use automatically when recognizing or generating from this rule set
  RouteRule defaultRule;

  /// Configure additional rules in this rule set from a route definition
  bool config(RouteDefinition config) {
    var handler;
    if (config.name != null && config.name[0].toUpperCase() != config.name[0]) {
      var suggestedName =
          config.name[0].toUpperCase() + config.name.substring(1);
      throw new ArgumentError(
          'Route "${config.path}" with name "${config.name}" does not '
          'begin with an uppercase letter. Route names should be CamelCase '
          'like "$suggestedName".');
    }
    if (config is AuxRoute) {
      handler = new SyncRouteHandler(
          config.component, config.data as Map<String, dynamic>);
      var routePath = this._getRoutePath(config);
      var auxRule = new RouteRule(routePath, handler, config.name);
      this.auxRulesByPath[routePath.toString()] = auxRule;
      if (config.name != null) {
        this.auxRulesByName[config.name] = auxRule;
      }
      return auxRule.terminal;
    }
    var useAsDefault = false;
    if (config is Redirect) {
      var routePath = this._getRoutePath(config);
      var redirector = new RedirectRule(routePath, config.redirectTo);
      this._assertNoHashCollision(redirector.hash, config.path);
      this.rules.add(redirector);
      return true;
    }
    if (config is Route) {
      handler = new SyncRouteHandler(
          config.component, config.data as Map<String, dynamic>);
      useAsDefault = config.useAsDefault != null && config.useAsDefault;
    } else if (config is AsyncRoute) {
      handler = new AsyncRouteHandler(
          config.loader, config.data as Map<String, dynamic>);
      useAsDefault = config.useAsDefault != null && config.useAsDefault;
    }
    var routePath = this._getRoutePath(config);
    var newRule = new RouteRule(routePath, handler, config.name);
    this._assertNoHashCollision(newRule.hash, config.path);
    if (useAsDefault) {
      if (defaultRule != null) {
        throw new StateError('Only one route can be default');
      }
      this.defaultRule = newRule;
    }
    this.rules.add(newRule);
    if (config.name != null) {
      this.rulesByName[config.name] = newRule;
    }
    return newRule.terminal;
  }

  /// Given a URL, returns a list of `RouteMatch`es, which are partial
  /// recognitions for some route.
  List<Future<RouteMatch>> recognize(Url urlParse) {
    var solutions = <Future<RouteMatch>>[];
    this.rules.forEach((AbstractRule routeRecognizer) {
      var pathMatch = routeRecognizer.recognize(urlParse);
      if (pathMatch != null) {
        solutions.add(pathMatch);
      }
    });
    // Handle cases where we are routing just to an aux route.
    if (solutions.length == 0 &&
        urlParse != null &&
        urlParse.auxiliary.length > 0) {
      return [new Future.value(new PathMatch(null, null, urlParse.auxiliary))];
    }
    return solutions;
  }

  List<Future<RouteMatch>> recognizeAuxiliary(Url urlParse) {
    RouteRule routeRecognizer = this.auxRulesByPath[urlParse.path];
    if (routeRecognizer != null) {
      return [routeRecognizer.recognize(urlParse)];
    }
    return [new Future.value(null)];
  }

  bool hasRoute(String name) {
    return this.rulesByName.containsKey(name);
  }

  bool componentLoaded(String name) {
    return hasRoute(name) && rulesByName[name].handler.componentType != null;
  }

  Future<dynamic> loadComponent(String name) {
    return this.rulesByName[name].handler.resolveComponentType();
  }

  ComponentInstruction generate(String name, Map<String, dynamic> params) {
    RouteRule rule = this.rulesByName[name];
    return rule?.generate(params);
  }

  ComponentInstruction generateAuxiliary(
      String name, Map<String, dynamic> params) {
    RouteRule rule = this.auxRulesByName[name];
    return rule?.generate(params);
  }

  void _assertNoHashCollision(String hash, path) {
    this.rules.forEach((rule) {
      if (hash == rule.hash) {
        throw new ArgumentError(
            'Configuration "$path" conflicts with existing route '
            '"${rule.path}"');
      }
    });
  }

  RoutePath _getRoutePath(RouteDefinition config) {
    if (config.regex != null) {
      if (config.serializer is Function) {
        return new RegexRoutePath(
            config.regex, config.serializer as RegexSerializer);
      } else {
        throw new ArgumentError(
            'Route provides a regex property, "${config.regex}", but no '
            'serializer property');
      }
    }
    if (config.path != null) {
      // Auxiliary routes do not have a slash at the start.
      var path = (config is AuxRoute && config.path.startsWith('/'))
          ? config.path.substring(1)
          : config.path;
      return new ParamRoutePath(path);
    }
    throw new ArgumentError(
        'Route must provide either a path or regex property');
  }
}
