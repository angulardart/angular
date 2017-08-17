import 'dart:async';
import 'dart:math' as math;

import 'package:angular/angular.dart'
    show
        ComponentFactory,
        ComponentResolver,
        Inject,
        Injectable,
        OpaqueToken,
        Optional;
import 'package:angular/src/core/linker/component_resolver.dart';

import 'instruction.dart'
    show
        Instruction,
        ResolvedInstruction,
        RedirectInstruction,
        UnresolvedInstruction,
        DefaultInstruction;
import 'route_config/route_config_decorator.dart'
    show RouteConfig, Route, AuxRoute, RouteDefinition;
import 'route_config/route_config_normalizer.dart'
    show normalizeRouteConfig, assertComponentExists;
import 'rules/route_paths/route_path.dart' show GeneratedUrl;
import 'rules/rule_set.dart' show RuleSet;
import 'rules/rules.dart' show PathMatch, RedirectMatch, RouteMatch;
import 'url_parser.dart' show parser, Url, convertUrlParamsToArray;
import 'utils.dart' show getComponentAnnotations, getComponentType;

var _resolveToNull = new Future<Null>.value(null);
// A LinkItemArray is an array, which describes a set of routes

// The items in the array are found in groups:

// - the first item is the name of the route

// - the next items are:

//   - an object containing parameters

//   - or an array describing an aux route

// export type LinkRouteItem = string | Object;

// export type LinkItem = LinkRouteItem | Array<LinkRouteItem>;

// export type LinkItemArray = Array<LinkItem>;

/// Token used to bind the component with the top-level [RouteConfig]s for the
/// application.
///
/// ### Example ([live demo](http://plnkr.co/edit/iRUP8B5OUbxCWQ3AcIDm))
///
/// ```
/// import {Component} from 'angular2/core';
/// import {
///   ROUTER_DIRECTIVES,
///   ROUTER_PROVIDERS,
///   RouteConfig
/// } from 'angular2/router';
///
/// @Component({directives: [ROUTER_DIRECTIVES]})
/// @RouteConfig([
///  {...},
/// ])
/// class AppCmp {
///   // ...
/// }
///
/// bootstrap(AppCmp, [ROUTER_PROVIDERS]);
/// ```
const OpaqueToken ROUTER_PRIMARY_COMPONENT =
    const OpaqueToken('RouterPrimaryComponent');

/// The RouteRegistry holds route configurations for each component in an
/// Angular app. It is responsible for creating Instructions from URLs, and
/// generating URLs based on route and parameters.
@Injectable()
class RouteRegistry {
  dynamic /* Type | ComponentFactory */ _rootComponent;
  final _rules = new Map<dynamic, RuleSet>();
  final ComponentResolver _resolver;

  RouteRegistry(
    @Inject(ROUTER_PRIMARY_COMPONENT) this._rootComponent, [
    // Users may have overloaded this class.
    @Optional() this._resolver = const ReflectorComponentResolver(),
  ]);

  /// Given a component and a configuration object, add the route to this
  /// registry.
  void config(dynamic parentComponent, RouteDefinition config) {
    config = normalizeRouteConfig(config, this);
    // this is here because Dart type guard reasons
    if (config is Route) {
      assertComponentExists(config.component, config.path);
    } else if (config is AuxRoute) {
      assertComponentExists(config.component, config.path);
    }
    var rules = this._rules[parentComponent];
    if (rules == null) {
      rules = new RuleSet();
      this._rules[parentComponent] = rules;
    }
    var terminal = rules.config(config);
    if (config is Route) {
      if (terminal) {
        assertTerminalComponent(config.component, config.path, _resolver);
      } else {
        this.configFromComponent(config.component);
      }
    }
  }

  /// Reads the annotations of a component and configures the registry based on
  /// them.
  void configFromComponent(dynamic component) {
    if (component is! Type && !(component is ComponentFactory)) {
      return;
    }
    // Don't read the annotations from a type more than once –
    // this prevents an infinite loop if a component routes recursively.
    if (this._rules.containsKey(component)) {
      return;
    }
    var annotations = getComponentAnnotations(component, _resolver);
    if (annotations != null) {
      for (var i = 0; i < annotations.length; i++) {
        var annotation = annotations[i];
        if (annotation is RouteConfig) {
          List<RouteDefinition> routeCfgs = annotation.configs;
          routeCfgs.forEach((config) => this.config(component, config));
        }
      }
    }
  }

  /// Given a URL and a parent component, return the most specific instruction
  /// for navigating the application into the state specified by the url.
  Future<Instruction> recognize(
      String url, List<Instruction> ancestorInstructions) {
    var parsedUrl = parser.parse(url);
    return this._recognize(parsedUrl, []);
  }

  /// Recognizes all parent-child routes, but creates unresolved auxiliary
  /// routes.
  Future<Instruction> _recognize(
      Url parsedUrl, List<Instruction> ancestorInstructions,
      [_aux = false]) {
    var parentInstruction =
        ancestorInstructions.isNotEmpty ? ancestorInstructions.last : null;
    var parentComponent = parentInstruction != null
        ? parentInstruction.component.componentType
        : this._rootComponent;
    var rules = this._rules[parentComponent];
    if (rules == null) {
      return new Future<Instruction>.value();
    }
    // Matches some beginning part of the given URL
    List<Future<RouteMatch>> possibleMatches =
        _aux ? rules.recognizeAuxiliary(parsedUrl) : rules.recognize(parsedUrl);
    List<Future<Instruction>> matchPromises = possibleMatches
        .map((Future<RouteMatch> candidate) =>
            candidate.then((RouteMatch candidate) async {
              if (candidate is PathMatch) {
                List<Instruction> auxParentInstructions =
                    ancestorInstructions.length > 0
                        ? [
                            ancestorInstructions.isNotEmpty
                                ? ancestorInstructions.last
                                : null
                          ]
                        : [];
                var auxInstructions = this._auxRoutesToUnresolved(
                    candidate.remainingAux, auxParentInstructions);
                var instruction = new ResolvedInstruction(
                    candidate.instruction, null, auxInstructions);
                if (candidate.instruction?.terminal != false) {
                  return instruction;
                }
                List<Instruction> newAncestorInstructions =
                    (new List.from(ancestorInstructions)
                      ..addAll([instruction]));
                var childInstruction = await this
                    ._recognize(candidate.remaining, newAncestorInstructions);
                if (childInstruction == null) {
                  return null;
                }
                // redirect instructions are already absolute
                if (childInstruction is RedirectInstruction) {
                  return childInstruction;
                }
                instruction.child = childInstruction;
                return instruction;
              }
              if (candidate is RedirectMatch) {
                var instruction = this.generate(candidate.redirectTo,
                    (new List.from(ancestorInstructions)..addAll([null])));
                return new RedirectInstruction(
                    instruction.component,
                    instruction.child,
                    instruction.auxInstruction,
                    candidate.specificity);
              }
              return null;
            }))
        .toList();
    if ((parsedUrl == null || parsedUrl.path == '') &&
        possibleMatches.length == 0) {
      return new Future.value(this.generateDefault(parentComponent));
    }
    return Future.wait<Instruction>(matchPromises).then(mostSpecific);
  }

  Map<String, Instruction> _auxRoutesToUnresolved(
      List<Url> auxRoutes, List<Instruction> parentInstructions) {
    Map<String, Instruction> unresolvedAuxInstructions = {};
    auxRoutes.forEach((Url auxUrl) {
      unresolvedAuxInstructions[auxUrl.path] = new UnresolvedInstruction(() {
        return this._recognize(auxUrl, parentInstructions, true);
      });
    });
    return unresolvedAuxInstructions;
  }

  /// Given a normalized list with component names and params like:
  /// `['user', {id: 3 }]` generates a url with a leading slash relative to the
  /// provided `parentComponent`.
  ///
  /// If the optional param `_aux` is `true`, then we generate starting at an
  /// auxiliary route boundary.
  Instruction generate(
      List<dynamic> linkParams, List<Instruction> ancestorInstructions,
      [_aux = false]) {
    var params = splitAndFlattenLinkParams(linkParams);
    var prevInstruction;
    // The first segment should be either '.' (generate from parent) or ''
    // (generate from root). When we normalize above, we strip all the slashes,
    // './' becomes '.' and '/' becomes ''.
    if (params.first == '') {
      params.removeAt(0);
      prevInstruction = ancestorInstructions.first;
      ancestorInstructions = [];
    } else {
      prevInstruction = ancestorInstructions.length > 0
          ? ancestorInstructions.removeLast()
          : null;
      if (params.first == '.') {
        params.removeAt(0);
      } else if (params.first == '..') {
        while (params.first == '..') {
          if (ancestorInstructions.length <= 0) {
            throw new ArgumentError(
                'Link "$linkParams" has too many "../" segments.');
          }
          prevInstruction = ancestorInstructions.removeLast();
          params = params.sublist(1);
        }
      } else {
        // we must only peak at the link param, and not consume it
        var routeName = params.first;
        var parentComponentType = this._rootComponent;
        var grandparentComponentType;
        if (ancestorInstructions.length > 1) {
          var parentComponentInstruction =
              ancestorInstructions[ancestorInstructions.length - 1];
          var grandComponentInstruction =
              ancestorInstructions[ancestorInstructions.length - 2];
          parentComponentType =
              parentComponentInstruction.component.componentType;
          grandparentComponentType =
              grandComponentInstruction.component.componentType;
        } else if (ancestorInstructions.length == 1) {
          parentComponentType = ancestorInstructions[0].component.componentType;
          grandparentComponentType = this._rootComponent;
        }
        // For a link with no leading `./`, `/`, or `../`, we look for a sibling
        // and child.
        // If both exist, we throw. Otherwise, we prefer whichever exists.
        var childRouteExists = this.hasRoute(routeName, parentComponentType);
        var parentRouteExists = grandparentComponentType != null &&
            this.hasRoute(routeName, grandparentComponentType);
        if (parentRouteExists && childRouteExists) {
          var msg = 'Link "$linkParams" is ambiguous, use "./" or "../" to '
              'disambiguate.';
          throw new StateError(msg);
        }
        if (parentRouteExists) {
          prevInstruction = ancestorInstructions.removeLast();
        }
      }
    }
    if (params[params.length - 1] == '') {
      params.removeLast();
    }
    if (params.length > 0 && params[0] == '') {
      params.removeAt(0);
    }
    if (params.length < 1) {
      var msg = 'Link "$linkParams" must include a route name.';
      throw new ArgumentError(msg);
    }
    var generatedInstruction = this._generate(
        params, ancestorInstructions, prevInstruction, _aux, linkParams);
    // We don't clone the first (root) element.
    for (var i = ancestorInstructions.length - 1; i >= 0; i--) {
      var ancestorInstruction = ancestorInstructions[i];
      if (ancestorInstruction == null) {
        break;
      }
      generatedInstruction =
          ancestorInstruction.replaceChild(generatedInstruction);
    }
    return generatedInstruction;
  }

  /// Internal helper that does not make any assertions about the beginning of the
  /// link DSL. `ancestorInstructions` are parents that will be cloned.
  /// `prevInstruction` is the existing instruction that would be replaced, but
  /// which might have aux routes that need to be cloned.
  Instruction _generate(List<dynamic> linkParams,
      List<Instruction> ancestorInstructions, Instruction prevInstruction,
      [_aux = false, List<dynamic> _originalLink]) {
    var parentComponentType = this._rootComponent;
    var componentInstruction;
    Map<String, Instruction> auxInstructions = {};
    Instruction parentInstruction =
        ancestorInstructions.isNotEmpty ? ancestorInstructions.last : null;
    if (parentInstruction?.component != null) {
      parentComponentType = parentInstruction.component.componentType;
    }
    if (linkParams.length == 0) {
      var defaultInstruction = this.generateDefault(parentComponentType);
      if (defaultInstruction == null) {
        throw new StateError(
            'Link "$_originalLink" does not resolve to a terminal '
            'instruction.');
      }
      return defaultInstruction;
    }
    // For non-aux routes, we want to reuse the predecessor's existing primary
    // and aux routes and only override routes for which the given link DSL
    // provides.
    if (prevInstruction != null && !_aux) {
      auxInstructions =
          new Map<String, Instruction>.from(prevInstruction.auxInstruction)
            ..addAll(auxInstructions);
      componentInstruction = prevInstruction.component;
    }
    var rules = this._rules[parentComponentType];
    if (rules == null) {
      throw new StateError(
          'Component "${getComponentType(parentComponentType)}" has no route '
          'config.');
    }
    var linkParamIndex = 0;
    Map<String, dynamic> routeParams = {};
    // First, recognize the primary route if one is provided.
    if (linkParamIndex < linkParams.length &&
        linkParams[linkParamIndex] is String) {
      var routeName = linkParams[linkParamIndex];
      if (routeName == '' || routeName == '.' || routeName == '..') {
        throw new ArgumentError(
            '"$routeName/" is only allowed at the beginning of a link DSL.');
      }
      linkParamIndex += 1;
      if (linkParamIndex < linkParams.length) {
        var linkParam = linkParams[linkParamIndex];
        if (linkParam is Map) {
          routeParams = linkParam as Map<String, dynamic>;
          linkParamIndex += 1;
        }
      }
      var routeRecognizer =
          (_aux ? rules.auxRulesByName : rules.rulesByName)[routeName];
      if (routeRecognizer == null) {
        throw new StateError(
            'Component "${getComponentType(parentComponentType)}" has no route '
            'named "$routeName".');
      }
      // Create an "unresolved instruction" for async routes. We'll figure out
      // the rest of the route when we resolve the instruction and perform a
      // navigation.
      if (routeRecognizer.handler.componentType == null) {
        GeneratedUrl generatedUrl =
            routeRecognizer.generateComponentPathValues(routeParams);
        return new UnresolvedInstruction(() {
          return routeRecognizer.handler.resolveComponentType().then((_) {
            return this._generate(linkParams, ancestorInstructions,
                prevInstruction, _aux, _originalLink);
          });
        }, generatedUrl.urlPath,
            convertUrlParamsToArray(generatedUrl.urlParams));
      }
      componentInstruction = _aux
          ? rules.generateAuxiliary(routeName, routeParams)
          : rules.generate(routeName, routeParams);
    }
    // Next, recognize auxiliary instructions.

    // If we have an ancestor instruction, we preserve whatever aux routes are
    // active from it.
    while (linkParamIndex < linkParams.length &&
        linkParams[linkParamIndex] is List) {
      List<Instruction> auxParentInstruction = [parentInstruction];
      var auxInstruction = this._generate(linkParams[linkParamIndex],
          auxParentInstruction, null, true, _originalLink);
      // TODO: this will not work for aux routes with parameters or multiple
      // segments.
      auxInstructions[auxInstruction.component.urlPath] = auxInstruction;
      linkParamIndex += 1;
    }
    var instruction =
        new ResolvedInstruction(componentInstruction, null, auxInstructions);
    // If the component is sync, we can generate resolved child route
    // instructions.

    // If not, we'll resolve the instructions at navigation time.
    if (componentInstruction?.componentType != null) {
      Instruction childInstruction;
      if (componentInstruction.terminal) {
        if (linkParamIndex >= linkParams.length) {}
      } else {
        List<Instruction> childAncestorComponents =
            (new List.from(ancestorInstructions)..addAll([instruction]));
        var remainingLinkParams = linkParams.sublist(linkParamIndex);
        childInstruction = this._generate(remainingLinkParams,
            childAncestorComponents, null, false, _originalLink);
      }
      instruction.child = childInstruction;
    }
    return instruction;
  }

  bool hasRoute(String name, dynamic parentComponent) {
    var rules = this._rules[parentComponent];
    if (rules == null) {
      return false;
    }
    return rules.hasRoute(name);
  }

  Instruction generateDefault(
      dynamic /* Type | ComponentFactory */ componentCursor) {
    if (componentCursor == null) {
      return null;
    }
    var rules = this._rules[componentCursor];
    if (rules?.defaultRule == null) {
      return null;
    }
    var defaultChild;
    if (rules.defaultRule.handler.componentType != null) {
      var componentInstruction = rules.defaultRule.generate({});
      if (!rules.defaultRule.terminal) {
        defaultChild =
            this.generateDefault(rules.defaultRule.handler.componentType);
      }
      return new DefaultInstruction(componentInstruction, defaultChild);
    }
    return new UnresolvedInstruction(() {
      return rules.defaultRule.handler
          .resolveComponentType()
          .then((_) => this.generateDefault(componentCursor));
    });
  }
}

/// Given: ['/a/b', {c: 2}]
/// Returns: ['', 'a', 'b', {c: 2}]
List<dynamic> splitAndFlattenLinkParams(List<dynamic> linkParams) {
  var accumulation = [];
  linkParams.forEach((dynamic item) {
    if (item is String) {
      accumulation = (new List.from(accumulation)..addAll(item.split('/')));
    } else {
      accumulation.add(item);
    }
  });
  return accumulation;
}

/// Given a list of instructions, returns the most specific instruction
Instruction mostSpecific(List<Instruction> instructions) {
  instructions =
      instructions.where((instruction) => instruction != null).toList();
  if (instructions.length == 0) {
    return null;
  }
  if (instructions.length == 1) {
    return instructions[0];
  }
  var first = instructions[0];
  var rest = instructions.sublist(1);
  return rest.fold(first, (Instruction instruction, Instruction contender) {
    if (compareSpecificityStrings(
            contender.specificity, instruction.specificity) ==
        -1) {
      return contender;
    }
    return instruction;
  });
}

/// Expects strings to be in the form of "[0-2]+".
/// Returns -1 if string A should be sorted above string B, 1 if it should be
/// sorted after, or 0 if they are the same.
num compareSpecificityStrings(String a, String b) {
  var l = math.min(a.length, b.length);
  for (var i = 0; i < l; i += 1) {
    var ai = a.codeUnitAt(i);
    var bi = b.codeUnitAt(i);
    var difference = bi - ai;
    if (difference != 0) {
      return difference;
    }
  }
  return a.length - b.length;
}

void assertTerminalComponent(component, path, ComponentResolver resolver) {
  if (component is! Type && !(component is ComponentFactory)) {
    return;
  }
  var annotations = getComponentAnnotations(component, resolver);
  if (annotations != null) {
    for (var i = 0; i < annotations.length; i++) {
      var annotation = annotations[i];
      if (annotation is RouteConfig) {
        throw new ArgumentError(
            'Child routes are not allowed for "$path". Use "..." on the '
            'parent\'s route path.');
      }
    }
  }
}
