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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RouterOutlet implements OnInit, OnDestroy {
  final ViewContainerRef _viewContainerRef;
  final Router _router;
  final bool isRootOutlet;
  final RouterHook _routerHook;

  // A mapping of {ComponentFactory} -> created {ComponentRef}.
  final _loadedComponents = <ComponentFactory, ComponentRef>{};

  // Factory that was used to create the active component.
  ComponentFactory _activeComponentFactory;

  // Route definitions registered with this outlet.
  List<RouteDefinition> _routes = const [];

  RouterOutlet(
    @Optional() @SkipSelf() RouterOutlet parentOutlet,
    @Optional() RouterOutletToken token,
    this._viewContainerRef,
    this._router,
    @Optional() this._routerHook,
  )
      : isRootOutlet = parentOutlet == null {
    token?.routerOutlet = this;
  }

  ComponentRef get _activeComponent {
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
            throw new StateError('Only one route can be used as default');
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
    if (isRootOutlet) {
      _router.registerRootOutlet(this);
    }
  }

  @override
  void ngOnDestroy() {
    for (var loadedComponent in _loadedComponents.values) {
      loadedComponent.destroy();
    }
    _viewContainerRef.clear();
    if (isRootOutlet) {
      _router.unregisterRootOutlet(this);
    }
  }

  Future<ComponentFactory> _coerceFactory(Object typeOrFactory) async {
    if (typeOrFactory is ComponentFactory) {
      return typeOrFactory;
    }
    throw new ArgumentError('Invalid type: $typeOrFactory.');
  }

  /// Instantiates a component [typeOrFactory] to prepare it for rendering.
  ///
  /// Internally maintains a cache of created components.
  Future<ComponentRef> prepare(ComponentFactory component) async {
    return _loadedComponents.putIfAbsent(component, () {
      final componentRef = component.create(new Injector.map({
        RouterOutletToken: new RouterOutletToken(),
      }, _viewContainerRef.injector));
      componentRef.changeDetectorRef.detectChanges();
      return componentRef;
    });
  }

  /// Activates and renders [component] within the outlet.
  ///
  /// Show a component of the given type into the outlet. If that type of
  /// component hasn't already been created, creates one.
  Future<Null> activate(
    Object typeOrFactory,
    RouterState oldState,
    RouterState newState,
  ) async {
    // Canonical factory for creating an instance of the component.
    final component = await _coerceFactory(typeOrFactory);
    var activeInstance = _activeComponent;

    if (activeInstance != null) {
      if (!await _shouldReuse(activeInstance.instance, oldState, newState)) {
        _loadedComponents.remove(_activeComponentFactory);
        activeInstance.destroy();
        // Clear will the detach and destroy all views.
        _viewContainerRef.clear();
      } else {
        for (int i = _viewContainerRef.length - 1; i >= 0; i--) {
          _viewContainerRef.detach(i);
        }
      }
    }

    // Clear and re-insert the component view.
    _activeComponentFactory = component;
    activeInstance = await prepare(component);
    _viewContainerRef.insert(activeInstance.hostView);
    activeInstance.changeDetectorRef.detectChanges();
  }

  Future<bool> _shouldReuse(
    Object instance,
    RouterState oldState,
    RouterState newState,
  ) async {
    if (instance is CanReuse) {
      return await instance.canReuse(oldState, newState);
    }
    if (_routerHook != null) {
      return await _routerHook.canReuse(instance, oldState, newState);
    }

    return false;
  }
}
