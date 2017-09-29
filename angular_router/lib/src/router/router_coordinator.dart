@JS()
library angular_router.router_coordinator;

import 'dart:async';
import 'dart:js';

import 'package:js/js.dart';

import 'navigation_params.dart';
import 'router.dart';
import 'router_impl.dart';

const String _jsVariable = 'routerCoordinator';

// TODO(nxl): Handle ActivateGuards.
// TODO(nxl): Handle DeactivateGuards.
/// A coordinator to handle communication between multiple [Router] instances.
///
/// The RouterCoordinator registers all Routers as an array of JsObjects in a
/// global namespace. This enables all Router instances to access the same
/// RouterCoordinator data. Router instance navigations call
/// RouterCoordinator's [navigate]. This way, a navigation on any Router will
/// be handled on all other Routers.
class RouterCoordinator {
  // Singleton instance of a RouterCoordinator.
  static RouterCoordinator INSTANCE = new RouterCoordinator._();

  final JsArray _routerArray;

  RouterCoordinator._()
      : _routerArray = context[_jsVariable] ?? new JsObject(context['Array']) {
    context[_jsVariable] = _routerArray;
  }

  // Registered routers are given an ID to keep track of which dart [RouterImpl]
  // maps to which _RouterJs.
  int registerRouter(RouterImpl router) {
    _routerArray.add(new _RouterJs(router).jsObject);
    return _routerArray.length - 1;
  }

  Future<NavigationResult> navigate(
      int routerIndex, String path, NavigationParams navigationParams) async {
    List<NavigationResult> navigationResults = new List(_routerArray.length);

    // First navigate the router that called the navigate, then the root,
    // and then the rest.
    navigationResults[routerIndex] =
        await new _RouterJs.fromJs(_routerArray[routerIndex])
            .navigate(path, navigationParams);
    if (routerIndex != 0 && _routerArray.length > 0) {
      navigationResults[0] = await new _RouterJs.fromJs(_routerArray[0])
          .navigate(path, navigationParams);
    }
    for (int i = 1; i < _routerArray.length; i++) {
      if (i != routerIndex) {
        navigationResults[i] = await new _RouterJs.fromJs(_routerArray[i])
            .navigate(path, navigationParams);
      }
    }

    if (navigationResults.contains(NavigationResult.SUCCESS)) {
      return NavigationResult.SUCCESS;
    } else if (navigationResults.contains(NavigationResult.BLOCKED_BY_GUARD)) {
      return NavigationResult.BLOCKED_BY_GUARD;
    }
    return NavigationResult.INVALID_ROUTE;
  }
}

/// A wrapper class to convert and handle a [RouterImpl] as a JsObject.
class _RouterJs {
  JsObject _jsObject;
  JsObject get jsObject => _jsObject;

  // Converts a [RouterImpl] to a JsObject by wrapper the navigate function.
  _RouterJs(RouterImpl router) {
    _jsObject = new JsObject(context['Object']);
    _jsObject['navigate'] = (path, navigationParams, callBack) {
      router
          .navigateRouter(
              path,
              navigationParams == null
                  ? null
                  : new NavigationParams(
                      queryParameters: _objToMap(navigationParams['queryParameters']) ?? const {},
                      fragment: navigationParams['fragment'] ?? '',
                      updateUrl: navigationParams['updateUrl'] ?? true))
          .then((result) => callBack.callMethod('onCompletion', [result]));
    };
  }

  _RouterJs.fromJs(this._jsObject);

  // Wraps the navigate function and handles the callback by returning a Future.
  Future<NavigationResult> navigate(
      String path, NavigationParams navigationParams) {
    Completer<NavigationResult> navigationCompleter = new Completer();
    var callbackJs = new JsObject(context['Object']);
    callbackJs['onCompletion'] =
        (result) => navigationCompleter.complete(result);
    _jsObject.callMethod('navigate', [
      path,
      navigationParams == null
          ? null
          : new _NavigationParamsJs(
              queryParameters: navigationParams.queryParameters,
              fragment: navigationParams.fragment,
              updateUrl: navigationParams.updateUrl),
      callbackJs
    ]);

    return navigationCompleter.future;
  }
}

/// A wrapper class to convert and handle a [NavigationParams] as a JsObject.
@JS()
@anonymous
class _NavigationParamsJs {
  external factory _NavigationParamsJs(
      {Map<String, String> queryParameters, String fragment, bool updateUrl});

  external Map<String, String> get queryParameters;
  external String get fragment;
  external bool get updateUrl;
}

Map _objToMap(o) => o == null ? o : new Map.fromIterable(_jsKeys(o), value: (key) => _jsGetProp(o, key));

@JS('Object.getProperty')
external List<String> _jsGetProp(jsObject, key);

@JS('Object.keys')
external List<String> _jsKeys(jsObject);
