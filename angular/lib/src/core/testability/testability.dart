import 'dart:async';

import 'package:angular/src/core/di.dart' show Injectable;

import '../zone/ng_zone.dart';

/// The Testability service provides testing hooks that can be accessed from
/// the browser and by services such as Protractor. Each bootstrapped Angular
/// application on the page will have an instance of Testability.
@Injectable()
class Testability {
  NgZone _ngZone;
  num _pendingCount = 0;
  bool _isZoneStable = true;

  /// Whether any work was done since the last 'whenStable' callback. This is
  /// useful to detect if this could have potentially destabilized another
  /// component while it is stabilizing.
  bool _didWork = false;

  final List<Function> _callbacks = <Function>[];
  Testability(this._ngZone) {
    _watchAngularEvents();
  }

  void _watchAngularEvents() {
    _ngZone.onTurnStart.listen((_) {
      _didWork = true;
      _isZoneStable = false;
    });
    _ngZone.runOutsideAngular(() {
      _ngZone.onTurnDone.listen((_) {
        NgZone.assertNotInAngularZone();
        scheduleMicrotask(() {
          _isZoneStable = true;
          _runCallbacksIfReady();
        });
      });
    });
  }

  num increasePendingRequestCount() {
    _pendingCount += 1;
    _didWork = true;
    return _pendingCount;
  }

  num decreasePendingRequestCount() {
    _pendingCount -= 1;
    // Check for pending async requests dropping below zero.
    assert(_pendingCount >= 0);
    _runCallbacksIfReady();
    return _pendingCount;
  }

  bool isStable() {
    return _isZoneStable && _pendingCount == 0 && !_ngZone.hasPendingMacrotasks;
  }

  void _runCallbacksIfReady() {
    if (isStable()) {
      // Schedules the call backs in a new frame so that it is always async.
      scheduleMicrotask(() {
        while (_callbacks.isNotEmpty) {
          (_callbacks.removeLast())(_didWork);
        }
        _didWork = false;
      });
    } else {
      // Not Ready
      _didWork = true;
    }
  }

  void whenStable(Function callback) {
    _callbacks.add(callback);
    _runCallbacksIfReady();
  }

  num getPendingRequestCount() {
    return _pendingCount;
  }

  List<dynamic> findBindings(dynamic using, String provider, bool exactMatch) {
    // TODO(juliemr): implement.
    return [];
  }

  List<dynamic> findProviders(dynamic using, String provider, bool exactMatch) {
    // TODO(juliemr): implement.
    return [];
  }
}

/// A global registry of [Testability] instances for specific elements.
@Injectable()
class TestabilityRegistry {
  final _applications = new Map<dynamic, Testability>();
  GetTestability _testabilityGetter = new _NoopGetTestability();

  /// Set the [GetTestability] implementation used by the Angular testing
  /// framework.
  void setTestabilityGetter(GetTestability getter) {
    this._testabilityGetter = getter;
    getter.addToWindow(this);
  }

  void registerApplication(dynamic token, Testability testability) {
    _applications[token] = testability;
  }

  Testability getTestability(dynamic elem) {
    return _applications[elem];
  }

  List<Testability> getAllTestabilities() => _applications.values.toList();

  List<dynamic> getAllRootElements() => _applications.keys.toList();

  Testability findTestabilityInTree(dynamic elem,
      [bool findInAncestors = true]) {
    return _testabilityGetter.findTestabilityInTree(
        this, elem, findInAncestors);
  }
}

/// Adapter interface for retrieving the `Testability` service associated for a
/// particular context.
abstract class GetTestability {
  void addToWindow(TestabilityRegistry registry);
  Testability findTestabilityInTree(
      TestabilityRegistry registry, dynamic elem, bool findInAncestors);
}

class _NoopGetTestability implements GetTestability {
  void addToWindow(TestabilityRegistry registry) {}
  Testability findTestabilityInTree(
      TestabilityRegistry registry, dynamic elem, bool findInAncestors) {
    return null;
  }

  const _NoopGetTestability();
}
