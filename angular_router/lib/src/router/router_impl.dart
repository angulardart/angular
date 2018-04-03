// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:angular/angular.dart';

import '../directives/router_outlet_directive.dart';
import '../lifecycle.dart';
import '../location.dart';
import '../route_definition.dart';
import '../router_hook.dart';
import '../url.dart';
import 'navigation_params.dart';
import 'router.dart';
import 'router_outlet_token.dart';
import 'router_state.dart';

/// An implementation of the [Router].
///
/// The Router is a separate abstract class to indicate the public API and hide
/// internal details for the average user.
@Injectable()
class RouterImpl extends Router {
  final StreamController<RouterState> _onRouteActivated =
      new StreamController<RouterState>.broadcast(sync: true);
  final Location _location;
  final RouterHook _routerHook;
  RouterState _activeState;
  Iterable<ComponentRef> _activeComponentRefs = [];
  StreamController<String> _onNavigationStart;
  RouterOutlet _rootOutlet;

  /// Tracks the latest navigation request.
  ///
  /// This is used to synchronize all navigation requests, so that they are run
  /// sequentially, rather than concurrently.
  Future<NavigationResult> _lastNavigation = new Future.value();

  RouterImpl(this._location, @Optional() this._routerHook) {
    Url.isHashStrategy = _location.platformStrategy is HashLocationStrategy;

    _location.subscribe((_) {
      final url = Url.parse(_location.path());
      final fragment = Url.isHashStrategy
          ? url.fragment
          : Url.normalizeHash(_location.hash());
      final navigationParams = new NavigationParams(
          queryParameters: url.queryParameters,
          fragment: fragment,
          updateUrl: false);
      _enqueueNavigation(url.path, navigationParams).then((navigationResult) {
        // If the back navigation was blocked (DeactivateGuard), push the
        // activeState back into the history.
        if (navigationResult == NavigationResult.BLOCKED_BY_GUARD) {
          _location.replaceState(_activeState.toUrl());
        }
      });
    });
  }

  RouterState get current => _activeState;

  @override
  Stream<String> get onNavigationStart {
    _onNavigationStart ??= new StreamController<String>.broadcast(sync: true);
    return _onNavigationStart.stream;
  }

  @override
  Stream<RouterState> get stream => _onRouteActivated.stream;

  @override
  void registerRootOutlet(RouterOutlet routerOutlet) {
    if (_rootOutlet == null) {
      _rootOutlet = routerOutlet;

      Url url = Url.parse(_location.path());
      _enqueueNavigation(
          url.path,
          new NavigationParams(
              queryParameters: url.queryParameters,
              fragment: Url.isHashStrategy
                  ? url.fragment
                  : Url.normalizeHash(_location.hash()),
              updateUrl: false));
    }
  }

  @override
  void unregisterRootOutlet(RouterOutlet routerOutlet) {
    if (_rootOutlet == routerOutlet) {
      _rootOutlet = null;
      _activeState = null;
    }
  }

  /// Navigate to the given url.
  ///
  /// Path is the path without the base href.
  @override
  Future<NavigationResult> navigate(
    String path, [
    NavigationParams navigationParams,
  ]) {
    final absolutePath = _getAbsolutePath(path, _activeState);
    return _enqueueNavigation(absolutePath, navigationParams);
  }

  /// Enqueues the navigation request to begin after all pending ones complete.
  Future<NavigationResult> _enqueueNavigation(
    String path,
    NavigationParams navigationParams,
  ) {
    return _lastNavigation =
        _lastNavigation.then((_) => _navigate(path, navigationParams));
  }

  /// Navigate this router to the given url.
  ///
  /// Path is the full, absolute URL.
  Future<NavigationResult> _navigate(
    String path,
    NavigationParams navigationParams, {
    bool isRedirect: false,
  }) async {
    if (!isRedirect) {
      // Don't check `CanNavigate` or trigger `onNavigationStart` on redirect.
      if (!await _canNavigate()) {
        return NavigationResult.BLOCKED_BY_GUARD;
      } else {
        _onNavigationStart?.add(path);
      }
    }

    navigationParams?.assertValid();
    path = await _routerHook?.navigationPath(path, navigationParams) ?? path;
    path = Url.normalizePath(path);
    navigationParams =
        await _routerHook?.navigationParams(path, navigationParams) ??
            navigationParams;
    navigationParams?.assertValid();

    var queryParameters = (navigationParams?.queryParameters ?? {});
    var reload = navigationParams != null ? navigationParams.reload : false;
    if (!reload &&
        current != null &&
        path == current.path &&
        (navigationParams?.fragment ?? '') == current.fragment &&
        const MapEquality().equals(queryParameters, current.queryParameters)) {
      return NavigationResult.SUCCESS;
    }

    MutableRouterState nextState = await _resolveState(path, navigationParams);
    if (nextState == null) {
      return NavigationResult.INVALID_ROUTE;
    }

    if (nextState.routes.isNotEmpty &&
        nextState.routes.last is RedirectRouteDefinition) {
      var redirectUrl =
          (nextState.routes.last as RedirectRouteDefinition).redirectTo;
      return _navigate(
        _getAbsolutePath(redirectUrl, nextState.build()),
        navigationParams == null
            ? null
            : new NavigationParams(
                fragment: navigationParams.fragment,
                queryParameters: navigationParams.queryParameters),
        isRedirect: true,
      );
    }

    if (!await _canDeactivate(nextState)) {
      return NavigationResult.BLOCKED_BY_GUARD;
    }
    if (!await _canActivate(nextState)) {
      return NavigationResult.BLOCKED_BY_GUARD;
    }

    await _activateRouterState(nextState);
    if (navigationParams == null || navigationParams.updateUrl) {
      final url = nextState.build().toUrl();
      if (navigationParams != null && navigationParams.replace) {
        _location.replaceState(url);
      } else {
        _location.go(url);
      }
    }

    return NavigationResult.SUCCESS;
  }

  /// Takes a relative or absolute path and converts it to an absolute path.
  ///
  /// ie: ./new -> /the/current/path/new
  String _getAbsolutePath(String path, RouterState state) {
    if (path.startsWith('./')) {
      var currentRoutes = state.routes.take(state.routes.length - 1);
      String currentPath = currentRoutes.fold(
          '', (soFar, route) => soFar + route.toUrl(state.parameters));

      return Location.joinWithSlash(currentPath, path.substring(2));
    }

    return path;
  }

  /// Translates a navigation request to the MutableRouterState.
  Future<MutableRouterState> _resolveState(
    String path,
    NavigationParams navigationParams,
  ) {
    return _resolveStateForOutlet(_rootOutlet, path).then((routerState) {
      if (routerState != null) {
        routerState.path = path;
        if (navigationParams != null) {
          routerState.fragment = navigationParams.fragment;
          routerState.queryParameters = navigationParams.queryParameters;
        }
        return _attachDefaultChildren(routerState);
      }
    });
  }

  /// Recursive function to iterate through route tree.
  ///
  /// Should only be called by [_resolveState].
  Future<MutableRouterState> _resolveStateForOutlet(
      RouterOutlet outlet, String path) async {
    if (outlet == null) {
      if (path == '') {
        return new MutableRouterState();
      }
      return null;
    }

    for (RouteDefinition route in outlet.routes) {
      Match match = route.toRegExp().matchAsPrefix(path);
      if (match != null) {
        MutableRouterState routerState;
        final component = await _getTypeFromRoute(route);
        ComponentRef componentRef =
            component != null ? outlet.prepare(component) : null;

        // TODO(nxl): Handle wildcard paths.
        // Only the prefix matched and the route is not a wildcard path.
        if (match.end != path.length) {
          // The route has no component and cannot have children. Continue
          // to search the next route.
          if (componentRef == null) {
            continue;
          }

          RouterOutlet nextOutlet =
              componentRef.injector.get(RouterOutletToken).routerOutlet;
          // The route's component has no outlet. Continue search.
          if (nextOutlet == null) {
            continue;
          }
        }

        if (componentRef != null) {
          RouterOutlet nextOutlet =
              componentRef.injector.get(RouterOutletToken).routerOutlet;
          routerState = await _resolveStateForOutlet(
              nextOutlet, path.substring(match.end));
        }
        if (routerState == null) {
          if (match.end != path.length) {
            continue;
          }

          routerState = new MutableRouterState();
        }

        routerState.routes.insert(0, route);

        if (component != null) {
          routerState
            ..factories[componentRef] = component
            ..components.insert(0, componentRef);
        }

        Iterable<String> parameters = route.parameters;
        // Append current matches params
        int index = 1;
        for (String parameter in parameters) {
          routerState.parameters[parameter] =
              Uri.decodeComponent(match[index++]);
        }

        return routerState;
      }
    }

    if (path == '') {
      return new MutableRouterState();
    }

    return null;
  }

  /// Gets a type from a [RouteDefinition].
  ///
  /// Checks if the route is a valid component route and returns the component
  /// type. If the route is not a valid component route, returns null.
  FutureOr<ComponentFactory> _getTypeFromRoute(RouteDefinition route) {
    if (route is ComponentRouteDefinition) {
      return route.component;
    }
    if (route is DeferredRouteDefinition) {
      return route.loader();
    }
    return null;
  }

  /// Navigates the remaining router tree and adds the default children.
  ///
  /// Takes a [RouterState] and checks the last route. If the last route has
  /// an outlet with a default route, the default route is attached to the
  /// [RouterState]. The process is repeated until there are no more defaults.
  Future<MutableRouterState> _attachDefaultChildren(
      MutableRouterState stateSoFar) async {
    RouterOutlet nextOutlet;
    if (stateSoFar.routes.length == 0) {
      nextOutlet = _rootOutlet;
    } else {
      // If the last route is a not component route, there will be no default
      // children.
      final component = await _getTypeFromRoute(stateSoFar.routes.last);
      if (component == null) {
        return stateSoFar;
      }

      nextOutlet = stateSoFar.components.last.injector
          .get(RouterOutletToken)
          .routerOutlet;
    }
    if (nextOutlet == null) {
      return stateSoFar;
    }

    for (RouteDefinition route in nextOutlet.routes) {
      // There is a default route, so we push it onto the RouterState.
      if (route.useAsDefault) {
        stateSoFar.routes.add(route);

        final component = await _getTypeFromRoute(stateSoFar.routes.last);
        // The default route has a component, and we need to check for defaults
        // on the child route.
        if (component != null) {
          final instance = nextOutlet.prepare(component);
          stateSoFar
            ..factories[instance] = component
            ..components.add(instance);
          return _attachDefaultChildren(stateSoFar);
        }

        return stateSoFar;
      }
    }

    return stateSoFar;
  }

  /// Returns whether the router can navigate.
  Future<bool> _canNavigate() async {
    for (var componentRef in _activeComponentRefs) {
      final component = componentRef.instance;
      if (component is CanNavigate && !await component.canNavigate()) {
        return false;
      }
    }
    return true;
  }

  /// Returns whether the current state can deactivate.
  ///
  /// The next state is needed since the [CanDeactivate] lifecycle uses the
  /// next state.
  Future<bool> _canDeactivate(MutableRouterState mutableNextState) async {
    RouterState nextState = mutableNextState.build();
    for (ComponentRef componentRef in _activeComponentRefs) {
      Object component = componentRef.instance;
      if (component is CanDeactivate &&
          !(await component.canDeactivate(_activeState, nextState))) {
        return false;
      }
      if (_routerHook != null &&
          !(await _routerHook.canDeactivate(
              component, _activeState, nextState))) {
        return false;
      }
    }

    return true;
  }

  /// Returns whether the next state can activate.
  Future<bool> _canActivate(MutableRouterState mutableNextState) async {
    RouterState nextState = mutableNextState.build();
    for (ComponentRef componentRef in mutableNextState.components) {
      Object component = componentRef.instance;
      if (component is CanActivate &&
          !(await component.canActivate(_activeState, nextState))) {
        return false;
      }
      if (_routerHook != null &&
          !(await _routerHook.canActivate(
              component, _activeState, nextState))) {
        return false;
      }
    }

    return true;
  }

  /// Activates a [RouterState] in the matched [RouterOutlet]s.
  Future _activateRouterState(MutableRouterState mutableNextState) async {
    final nextState = mutableNextState.build();

    for (final componentRef in _activeComponentRefs) {
      final component = componentRef.instance;
      if (component is OnDeactivate) {
        component.onDeactivate(_activeState, nextState);
      }
    }

    var currentOutlet = _rootOutlet;
    for (var i = 0, len = mutableNextState.components.length; i < len; ++i) {
      // Get the ComponentRef created during route resolution.
      final resolvedComponentRef = mutableNextState.components[i];
      final componentFactory = mutableNextState.factories[resolvedComponentRef];
      // Grab the cached ComponentRef in case the outlet recreated it.
      await currentOutlet.activate(componentFactory, _activeState, nextState);
      final componentRef = currentOutlet.prepare(componentFactory);
      if (!identical(componentRef, resolvedComponentRef)) {
        // Replace the resolved ComponentRef with the active ComponentRef so
        // that lifecycle methods are invoked on the correct instance.
        mutableNextState.components[i] = componentRef;
      }
      currentOutlet = componentRef.injector.get(RouterOutletToken).routerOutlet;
      final component = componentRef.instance;
      if (component is OnActivate) {
        component.onActivate(_activeState, nextState);
      }
    }

    _onRouteActivated.add(nextState);
    _activeState = nextState;
    _activeComponentRefs = mutableNextState.components;
  }
}
