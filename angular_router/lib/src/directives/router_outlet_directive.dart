// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart';

import '../lifecycle.dart';
import '../route_definition.dart';
import '../router/router.dart';
import '../router/router_outlet_token.dart';
import '../router/router_state.dart';
import '../router_hook.dart';

/// Reserves a location in the DOM as an outlet for the AngularDart [Router].
///
/// A router outlet renders part of the current route in a hierarchical fashion;
/// that is, multiple router outlets may be embedded inside of each-other, with
/// each outlet responsible for rendering a part of the URL:
/// ```html
/// <!-- Imagine "/users/bob" is being rendered -->
///
/// <template router-outlet>
///   <!-- view of "UsersShellComponent" -->
///   <template router-outlet>
///     <!-- view of "UserViewComponent" -->
///   </template>
/// </template>
/// ```
@Directive(
  selector: 'router-outlet',
)
class RouterOutlet implements OnInit, OnDestroy {
  final ViewContainerRef _viewContainerRef;
  final Router _router;
  final RouterHook _routerHook;

  // A mapping of {ComponentFactory} -> created {ComponentRef}.
  final _loadedComponents = <ComponentFactory<Object>, ComponentRef<Object>>{};

  // Factory that was used to create the active component.
  ComponentFactory<Object> _activeComponentFactory;

  // Route definitions registered with this outlet.
  List<RouteDefinition> _routes = const [];

  RouterOutlet(
    @Optional() RouterOutletToken token,
    this._viewContainerRef,
    this._router,
    @Optional() this._routerHook,
  ) {
    token?.routerOutlet = this;
  }

  ComponentRef<Object> get _activeComponent {
    return _loadedComponents[_activeComponentFactory];
  }

  /// Registers a list of [routes] to render at this location when matched.
  ///
  /// Note that it's possible for more than one route to match the same path, so
  /// order of definition matters. The router attempts to match routes in order,
  /// so the first route to match will be rendered.
  ///
  /// There are a few notable cases to be aware of when defining routes.
  ///
  ///   * Always place a route that matches `/` last. Otherwise, this route will
  ///     be created every time the router navigates in an attempt to resolve a
  ///     child route of `/`.
  ///
  ///   * Never define a route that matches `/.*`, *and* another route that
  ///     matches `/`. Either remove the route that matches `/`, if they share
  ///     the same parameters; or match `/.+` instead of `/.*`, if they have
  ///     distinct parameters.
  @Input()
  set routes(List<RouteDefinition> routes) {
    if (isDevMode) {
      for (final route in routes) {
        route.assertValid();
      }
      var hasDefault = false;
      for (final route in routes) {
        if (route.useAsDefault) {
          if (hasDefault) {
            throw StateError('Only one route can be used as default');
          }
          hasDefault = true;
        }
      }
    }
    _routes = routes;
  }

  /// Route definitions registered with this outlet.
  List<RouteDefinition> get routes => _routes ?? [];

  @override
  void ngOnInit() {
    _router.registerRootOutlet(this);
  }

  @override
  void ngOnDestroy() {
    for (var loadedComponent in _loadedComponents.values) {
      loadedComponent.destroy();
    }
    _viewContainerRef.clear();
    _router.unregisterRootOutlet(this);
  }

  /// Returns the component created by [componentFactory], prepared for routing.
  ///
  /// If the component is currently active, or reusable, a cached instance will
  /// be returned instead of creating a new one.
  ComponentRef<Object> prepare(ComponentFactory<Object> componentFactory) {
    return _loadedComponents.putIfAbsent(componentFactory, () {
      final componentRef = componentFactory.create(Injector.map({
        RouterOutletToken: RouterOutletToken(),
      }, _viewContainerRef.injector));
      // ignore: deprecated_member_use
      componentRef.changeDetectorRef.detectChanges();
      return componentRef;
    });
  }

  /// Activates and renders the component created by [componentFactory].
  ///
  /// If the component has already been activated and is reusable, a cached
  /// instance will be reused instead of creating a new one.
  Future<Null> activate(
    ComponentFactory<Object> componentFactory,
    RouterState oldState,
    RouterState newState,
  ) async {
    final activeComponent = _activeComponent;
    if (activeComponent != null) {
      final shouldReuse = await _shouldReuse(
        activeComponent.instance,
        oldState,
        newState,
      );
      if (shouldReuse) {
        // If both routes render the same component, don't detach it from DOM.
        if (identical(_activeComponentFactory, componentFactory)) return;
        // Detach the active component, keeping it cached for reuse.
        for (var i = _viewContainerRef.length - 1; i >= 0; --i) {
          _viewContainerRef.detach(i);
        }
      } else {
        // Destroy the active component.
        _loadedComponents.remove(_activeComponentFactory);
        activeComponent.destroy();
        _viewContainerRef.clear();
      }
    }
    // Render the new component in the outlet.
    _activeComponentFactory = componentFactory;
    final component = prepare(componentFactory);
    _viewContainerRef.insert(component.hostView);
    // ignore: deprecated_member_use
    component.changeDetectorRef.detectChanges();
  }

  FutureOr<bool> _shouldReuse(
    Object instance,
    RouterState oldState,
    RouterState newState,
  ) {
    if (instance is CanReuse) {
      return instance.canReuse(oldState, newState);
    }
    if (_routerHook != null) {
      return _routerHook.canReuse(instance, oldState, newState);
    }
    return false;
  }
}
