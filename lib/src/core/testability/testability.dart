import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/async.dart" show ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show MapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show scheduleMicroTask;

import "../zone/ng_zone.dart" show NgZone;

/**
 * The Testability service provides testing hooks that can be accessed from
 * the browser and by services such as Protractor. Each bootstrapped Angular
 * application on the page will have an instance of Testability.
 */
@Injectable()
class Testability {
  NgZone _ngZone;
  /** @internal */
  num _pendingCount = 0;
  /** @internal */
  bool _isZoneStable = true;
  /**
   * Whether any work was done since the last 'whenStable' callback. This is
   * useful to detect if this could have potentially destabilized another
   * component while it is stabilizing.
   * @internal
   */
  bool _didWork = false;
  /** @internal */
  List<Function> _callbacks = [];
  Testability(this._ngZone) {
    this._watchAngularEvents();
  }
  /** @internal */
  void _watchAngularEvents() {
    ObservableWrapper.subscribe(this._ngZone.onUnstable, (_) {
      this._didWork = true;
      this._isZoneStable = false;
    });
    this._ngZone.runOutsideAngular(() {
      ObservableWrapper.subscribe(this._ngZone.onStable, (_) {
        NgZone.assertNotInAngularZone();
        scheduleMicroTask(() {
          this._isZoneStable = true;
          this._runCallbacksIfReady();
        });
      });
    });
  }

  num increasePendingRequestCount() {
    this._pendingCount += 1;
    this._didWork = true;
    return this._pendingCount;
  }

  num decreasePendingRequestCount() {
    this._pendingCount -= 1;
    if (this._pendingCount < 0) {
      throw new BaseException("pending async requests below zero");
    }
    this._runCallbacksIfReady();
    return this._pendingCount;
  }

  bool isStable() {
    return this._isZoneStable &&
        this._pendingCount == 0 &&
        !this._ngZone.hasPendingMacrotasks;
  }

  /** @internal */
  void _runCallbacksIfReady() {
    if (this.isStable()) {
      // Schedules the call backs in a new frame so that it is always async.
      scheduleMicroTask(() {
        while (!identical(this._callbacks.length, 0)) {
          (this._callbacks.removeLast())(this._didWork);
        }
        this._didWork = false;
      });
    } else {
      // Not Ready
      this._didWork = true;
    }
  }

  void whenStable(Function callback) {
    this._callbacks.add(callback);
    this._runCallbacksIfReady();
  }

  num getPendingRequestCount() {
    return this._pendingCount;
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

/**
 * A global registry of [Testability] instances for specific elements.
 */
@Injectable()
class TestabilityRegistry {
  /** @internal */
  var _applications = new Map<dynamic, Testability>();
  GetTestability _testabilityGetter = new _NoopGetTestability();
  /**
   * Set the [GetTestability] implementation used by the Angular testing framework.
   */
  void setTestabilityGetter(GetTestability getter) {
    this._testabilityGetter = getter;
    getter.addToWindow(this);
  }

  registerApplication(dynamic token, Testability testability) {
    this._applications[token] = testability;
  }

  Testability getTestability(dynamic elem) {
    return this._applications[elem];
  }

  List<Testability> getAllTestabilities() {
    return MapWrapper.values(this._applications);
  }

  List<dynamic> getAllRootElements() {
    return MapWrapper.keys(this._applications);
  }

  Testability findTestabilityInTree(dynamic elem,
      [bool findInAncestors = true]) {
    return this
        ._testabilityGetter
        .findTestabilityInTree(this, elem, findInAncestors);
  }
}

/**
 * Adapter interface for retrieving the `Testability` service associated for a
 * particular context.
 */
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
