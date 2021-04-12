@JS()
library angular.src.testability;

import 'dart:async';
import 'dart:html' show Element;
import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:meta/meta.dart';
import 'package:angular/src/core/zone/ng_zone.dart';
import 'package:angular/src/utilities.dart';

import 'js_api.dart';

part 'js_impl.dart';

/// Provides testing hooks also accessible via JavaScript APIs in the browser.
///
/// TODO(b/168535057): Add `dispose` function (to unsubscribe, remove elements).
@sealed
class Testability {
  final NgZone _ngZone;

  Testability(this._ngZone);

  List<void Function(bool didAsyncWork)>? _callWhenStable;

  /// Registers [callback] to be invoked when change detection is completed.
  ///
  /// The parameter, `didAsyncWork`, is `true` when invoked as a result of
  /// change detection being complete, and `false` if, upon registration, the
  /// app was _already_ stable, triggering the [callback].
  ///
  /// This is commonly referred to as _stable_, that-is that the DOM
  /// representation of the app is synchronized with the Dart data and template
  /// models, and no more changes are (currently) epected.
  void whenStable(void Function(bool didAsyncWork) callback) {
    // TODO(b/168535057): Change this to `void Function()` instead.
    _storeCallback(callback);
    _runCallbacksIfStable(false);
  }

  void _storeCallback(void Function(bool didAsyncWork) callback) {
    final callWhenStable = _callWhenStable;
    if (callWhenStable == null) {
      _watchForStability(callback);
    } else {
      callWhenStable.add(callback);
    }
  }

  void _watchForStability(void Function(bool didAsyncWork) callback) {
    _callWhenStable = [callback];
    _ngZone.runOutsideAngular(() {
      _ngZone.onTurnDone.listen((_) {
        // Wait until the end of the event loop before checking stability.
        scheduleMicrotask(() => _runCallbacksIfStable(true));
      });
    });
  }

  /// RWhether the framework is no longer anticipating change detection.
  ///
  /// See [whenStable] for details.
  bool get isStable => !_ngZone.isRunning && !_ngZone.hasPendingMacrotasks;

  void _runCallbacksIfStable(bool didWork) {
    if (!isStable) {
      // Wait until this function is called again (it will be).
    } else {
      // Schedule the callback in a new microtask so this never is synchronous.
      scheduleMicrotask(() => _runCallbacks(didWork));
    }
  }

  void _runCallbacks(bool didWork) {
    final callbacks = _callWhenStable!;
    while (callbacks.isNotEmpty) {
      // TODO(b/168535057): Remove `didWork`.
      callbacks.removeLast()(didWork);
    }
  }
}

/// A global registry of [Testability] instances given an app root element.
class TestabilityRegistry {
  final _appRoots = <Element, Testability>{};

  _TestabilityProxy? _proxy;

  /// Used to eagerly initialize the JS-interop bits before the app is ready.
  ///
  /// TODO(b/168535057): Figure out why this is necessary.
  void initializeEagerly() {
    _proxy ??= _TestabilityProxy()..addToWindow(this);
  }

  /// Associate [appRoot] with the provided [testability] instance.
  void registerApplication(Element appRoot, Testability testability) {
    // TODO(b/168535057): Figure out why eager initialization is necessary.
    initializeEagerly();
    _appRoots[appRoot] = testability;
  }

  /// Returns the registered testability instance for [appRoot], or `null`.
  Testability? testabilityFor(Element appRoot) => _appRoots[appRoot];

  /// Returns all testability instances registered.
  Iterable<Testability> get allTestabilities => _appRoots.values;

  /// Walks the DOM [tree] looking for a registered [Testability] instance.
  ///
  /// TODO(b/168535057): Is this functionality actually necessary?
  Testability? findTestabilityInTree(Element? tree) {
    return _proxy?.findTestabilityInTree(this, tree);
  }
}

/// Provides implementation details for how to export and import the JS APIs.
abstract class _TestabilityProxy {
  const factory _TestabilityProxy() = _JSTestabilityProxy;

  /// Adds [registry] to the current browser context (i.e. `window.*`).
  void addToWindow(TestabilityRegistry registry);

  /// Using available JS APIs, walks ancestor DOM for [element] in [registry].
  ///
  /// Returns `null` if no registered [Testability] instance was found.
  Testability? findTestabilityInTree(
    TestabilityRegistry registry,
    Element? element,
  );
}
