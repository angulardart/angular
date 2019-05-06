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
      StreamController<RouterState>.broadcast(sync: true);
  final Location _location;
  final RouterHook _routerHook;
  RouterState _activeState;
  Iterable<ComponentRef<Object>> _activeComponentRefs = [];
  StreamController<String> _onNavigationStart;
  RouterOutlet _rootOutlet;

  /// Completes when the latest navigation request is complete.
  ///
  /// This is used to synchronize all navigation requests, so that they are run
  /// sequentially, rather than concurrently.
  var _lastNavigation = Future<void>.value();

  RouterImpl(this._location, @Optional() this._routerHook) {
    Url.isHashStrategy = _location.locationStrategy is HashLocationStrategy;

    _location.subscribe((_) {
      final url = Url.parse(_location.path());
      final fragment = Url.isHashStrategy
          ? url.fragment
          : Url.normalizeHash(_location.hash());
      final navigationParams = NavigationParams(
          queryParameters: url.queryParameters,
          fragment: fragment,
          replace: true);
      _enqueueNavigation(url.path, navigationParams).then((navigationResult) {
        // If the back navigation was blocked (DeactivateGuard), push the
        // activeState back into the history.
        if (navigationResult == NavigationResult.BLOCKED_BY_GUARD) {
          _location.go(_activeState.toUrl());
        }
      });
    });
  }

  RouterState get current => _activeState;

  @override
  Stream<String> get onNavigationStart {
    _onNavigationStart ??= StreamController<String>.broadcast(sync: true);
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
          NavigationParams(
              queryParameters: url.queryParameters,
              fragment: Url.isHashStrategy
                  ? url.fragment
                  : Url.normalizeHash(_location.hash()),
              replace: true));
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

  @override
  Future<NavigationResult> navigateByUrl(
    String url, {
    bool reload = false,
    bool replace = false,
  }) {
    final parsed = Url.parse(url);
    return navigate(
        parsed.path,
        NavigationParams(
          fragment: parsed.fragment,
          queryParameters: parsed.queryParameters,
          reload: reload,
          replace: replace,
        ));
  }

  /// Enqueues the navigation request to begin after all pending ones complete.
  Future<NavigationResult> _enqueueNavigation(
    String path,
    NavigationParams navigationParams,
  ) {
    // This is used to forward the navigation result or error to the caller.
    final navigationCompleter = Completer<NavigationResult>.sync();
    // Note how this does not await the result of the last navigation, but
    // rather the act of forwarding the result through a completer. This
    // indirection is an important distinction that allows enqueued navigation
    // requests to be run even if a preceding request throws, since the act of
    // awaiting an errored future rethrows that error.
    _lastNavigation = _lastNavigation.then((_) {
      return _navigate(path, navigationParams)
          .then(navigationCompleter.complete)
          .catchError(navigationCompleter.completeError);
    });
    return navigationCompleter.future;
  }

  /// Navigate this router to the given url.
  ///
  /// Path is the full, absolute URL.
  Future<NavigationResult> _navigate(
    String path,
    NavigationParams navigationParams, {
    bool isRedirect = false,
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
    path = _location.normalizePath(path);
    navigationParams =
        await _routerHook?.navigationParams(path, navigationParams) ??
            navigationParams;
    navigationParams?.assertValid();

    var queryParameters = navigationParams?.queryParameters ?? {};
    var reload = navigationParams != null ? navigationParams.reload : false;
    if (!reload &&
        current != null &&
        path == current.path &&
        (navigationParams?.fragment ?? '') == current.fragment &&
        const MapEquality<String, String>()
            .equals(queryParameters, current.queryParameters)) {
      // In the rare case that a popstate event matches a route that redirects
      // *to* the current route, the current state will already match the
      // redirected state. Normally when the current state and requested state
      // match, navigation returns successfuly without navigating since we don't
      // want to activate the already active route; however, in this case the
      // browser state will be out of sync with the current state due to the
      // popstate event. To synchronize this state without activating the
      // already active route, we simply need to push the redirected state to
      // the browser. Note that we only need to check if the path is different,
      // and not the fragment identifier or query parameters, because a redirect
      // route can only affect the path.
      if (path != _location.path()) {
        _location.replaceState(current.toUrl());
      }
      return NavigationResult.SUCCESS;
    }

    MutableRouterState nextState = await _resolveState(path, navigationParams);
    // In the event that `path` is empty and doesn't match any routes,
    // `_resolveState` will return a state with no routes, instead of null.
    if (nextState == null || nextState.routes.isEmpty) {
      return NavigationResult.INVALID_ROUTE;
    }

    if (nextState.routes.isNotEmpty) {
      final leaf = nextState.routes.last;
      if (leaf is RedirectRouteDefinition) {
        final newPath = _getAbsolutePath(
            leaf.redirectToUrl(nextState.parameters), nextState.build());
        return _navigate(newPath, navigationParams, isRedirect: true);
      }
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
    var state = MutableRouterState()..path = path;
    if (navigationParams != null) {
      state
        ..fragment = navigationParams.fragment
        ..queryParameters = navigationParams.queryParameters;
    }
    return _resolveStateForOutlet(_rootOutlet, state, path)
        .then((matched) => matched ? _attachDefaultChildren(state) : null);
  }

  /// Recursive function to iterate through route tree.
  ///
  /// Should only be called by [_resolveState].
  ///
  /// Returns true if [outlet] has a route definition that matches [path]. The
  /// matching results are written to [state].
  Future<bool> _resolveStateForOutlet(
    RouterOutlet outlet,
    MutableRouterState state,
    String path,
  ) async {
    // If there's no outlet, this is a successful match if there's also no
    // remaining path.
    if (outlet == null) return path.isEmpty;
    for (var route in outlet.routes) {
      var match = route.toRegExp().matchAsPrefix(path);
      if (match == null) continue;
      var incomplete = match.end != path.length;
      state.push(route, match);
      var component = await _componentFactory(state);
      if (component == null) {
        // If the route definition doesn't specify a component to load, we can
        // assume it redirects. Since a redirecting route definition can't
        // have any nested routes, it must match completely.
        if (incomplete) {
          state.pop();
          continue;
        }
        // Found a matching, redirecting route.
        return true;
      }
      var componentRef = outlet.prepare(component);
      var nextOutlet = _nextOutlet(componentRef);
      // If the current route doesn't match the entire path, there must be a
      // nested outlet to complete the match.
      if (incomplete && nextOutlet == null) {
        state.pop();
        continue;
      }
      // Push matching component factory and reference before recursing.
      state
        ..components.add(componentRef)
        ..factories[componentRef] = component;
      // Attempt to match remaining path to nested routes.
      var remainder = path.substring(match.end);
      if (await _resolveStateForOutlet(nextOutlet, state, remainder)) {
        return true;
      }
      // Backtrack and try the next route.
      state
        ..components.removeLast()
        ..factories.remove(componentRef)
        ..pop();
    }
    // At this point no routes matched. This is considered a successful match
    // only if there's also no remaining path to be matched, in which case the
    // outlet can render a default route, if defined.
    return path.isEmpty;
  }

  /// Returns the [ComponentFactory] loaded by the partial [state]'s last route.
  ///
  /// Returns null if the last route is a [RedirectRouteDefinition].
  FutureOr<ComponentFactory<Object>> _componentFactory(
      MutableRouterState state) {
    var route = state.routes.last;
    if (route is ComponentRouteDefinition) {
      return route.component;
    }
    if (route is DeferredRouteDefinition) {
      if (route.prefetcher == null) return route.loader();
      // The prefetcher may return void, so it must be wrapped in a Future so
      // that it can be passed to Future.wait().
      var prefetcherFuture = Future.value(route.prefetcher(state.build()));
      var loaderFuture = route.loader();
      return Future.wait([prefetcherFuture, loaderFuture])
          .then((_) => loaderFuture);
    }
    return null;
  }

  /// Returns the next [RouterOutlet] created by [componentRef], if any.
  RouterOutlet _nextOutlet(ComponentRef<Object> componentRef) =>
      componentRef.injector
          .provideType<RouterOutletToken>(RouterOutletToken)
          .routerOutlet;

  /// Navigates the remaining router tree and adds the default children.
  ///
  /// Takes a [RouterState] and checks the last route. If the last route has
  /// an outlet with a default route, the default route is attached to the
  /// [RouterState]. The process is repeated until there are no more defaults.
  Future<MutableRouterState> _attachDefaultChildren(
      MutableRouterState stateSoFar) async {
    RouterOutlet nextOutlet;
    if (stateSoFar.routes.isEmpty) {
      nextOutlet = _rootOutlet;
    } else if (stateSoFar.routes.last is RedirectRouteDefinition) {
      // If the last route is a redirect, there will be no default children.
      return stateSoFar;
    } else {
      nextOutlet = _nextOutlet(stateSoFar.components.last);
    }
    if (nextOutlet == null) {
      return stateSoFar;
    }

    for (RouteDefinition route in nextOutlet.routes) {
      // There is a default route, so we push it onto the RouterState.
      if (route.useAsDefault) {
        stateSoFar.routes.add(route);

        final component = await _componentFactory(stateSoFar);
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
    if (_routerHook != null && !(await _routerHook.canNavigate())) {
      return false;
    }
    return true;
  }

  /// Returns whether the current state can deactivate.
  ///
  /// The next state is needed since the [CanDeactivate] lifecycle uses the
  /// next state.
  Future<bool> _canDeactivate(MutableRouterState mutableNextState) async {
    RouterState nextState = mutableNextState.build();
    for (ComponentRef<Object> componentRef in _activeComponentRefs) {
      final component = componentRef.instance;
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
    for (ComponentRef<Object> componentRef in mutableNextState.components) {
      final component = componentRef.instance;
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
  Future<void> _activateRouterState(MutableRouterState mutableNextState) async {
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
      currentOutlet = _nextOutlet(componentRef);
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
