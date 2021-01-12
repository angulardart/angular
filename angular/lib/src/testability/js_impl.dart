part of 'testability.dart';

/// Which contextual object the Dart APIs are added to using `setProperty(...)`.
///
/// See <https://developer.mozilla.org/en-US/docs/Web/API/Window/self>.
///
/// TODO(b/168535057): Replace entirely with `@JS()`-style interop.
@JS('self')
external Object get _self;

class _JSTestabilityProxy implements _TestabilityProxy {
  const _JSTestabilityProxy();

  @override
  void addToWindow(TestabilityRegistry registry) {
    var jsRegistry = unsafeCast<List<Object?>?>(
      js_util.getProperty(_self, 'ngTestabilityRegistries'),
    );
    if (jsRegistry == null) {
      jsRegistry = _createAndExport$ngTestabilityRegistries();
      _export$getAngularTestability();
      _export$getAllAngularTestabilities();
      _export$frameworkStabilizers();
    }
    jsRegistry.add(_createRegistry(registry));
  }

  /// Assigns an empty `JSArray` to `self.ngTestabilityRegistries`.
  static List<Object?> _createAndExport$ngTestabilityRegistries() {
    final jsRegistry = <dynamic>[];
    js_util.setProperty(_self, 'ngTestabilityRegistries', jsRegistry);
    return jsRegistry;
  }

  /// For every registered [TestabilityRegistry], tries `getAngularTestability`.
  ///
  /// TODO(b/168535057): Return `JsTestability` instead (needs testing).
  static Object _getAngularTestability(Element element) {
    final registry = unsafeCast<List<Object?>>(
      js_util.getProperty(
        _self,
        'ngTestabilityRegistries',
      ),
    );
    for (var i = 0; i < registry.length; i++) {
      final result = unsafeCast<Object?>(js_util.callMethod(
        registry[i]!,
        'getAngularTestability',
        [element],
      ));
      if (result != null) {
        return result;
      }
    }
    // TODO(b/168535057): Why does this throw where the Dart API returns null?
    throw StateError('Could not find testability for element.');
  }

  /// Sets `self.getAngularTestability` => [_getAngularTestability].
  static void _export$getAngularTestability() {
    js_util.setProperty(
      _self,
      'getAngularTestability',
      allowInterop(_getAngularTestability),
    );
  }

  /// For every registered [TestabilityRegistry], returns the JS API for it.
  ///
  /// TODO(b/168535057): Return `List<JsTestability>` instead (needs testing).
  static List<Object?> _getAllAngularTestabilities() {
    final registry = unsafeCast<List<Object?>>(
      js_util.getProperty(_self, 'ngTestabilityRegistries'),
    );
    final result = <dynamic>[];
    for (var i = 0; i < registry.length; i++) {
      final testabilities = unsafeCast<List<Object?>>(js_util.callMethod(
        registry[i]!,
        'getAllAngularTestabilities',
        [],
      ));

      // We can't rely on testabilities being a Dart List, since it's read
      // from a JS variable. It might have been created from DDC.
      // Therefore, we only assume that it supports .length and [] access.
      final length = unsafeCast<int>(
        js_util.getProperty(testabilities, 'length'),
      );
      for (var j = 0; j < length; j++) {
        final testability = js_util.getProperty(testabilities, j);
        result.add(testability);
      }
    }
    return result;
  }

  /// Sets `self.getAllAngularTestabilities` => [_getAllAngularTestabilities].
  static void _export$getAllAngularTestabilities() {
    js_util.setProperty(
      _self,
      'getAllAngularTestabilities',
      allowInterop(_getAllAngularTestabilities),
    );
  }

  /// For every testability, calls [callback] when they _all_ report stable.
  ///
  /// TODO(b/168535057): Remove `didWork`.
  static void _whenAllStable(void Function(bool didWork) callback) {
    final testabilities = _getAllAngularTestabilities();

    var pendingStable = testabilities.length;
    var anyDidWork = false;

    void decrement(bool didWork) {
      if (didWork) {
        anyDidWork = didWork;
      }
      pendingStable--;
      if (pendingStable == 0) {
        callback(anyDidWork);
      }
    }

    for (var testability in testabilities) {
      js_util.callMethod(
        testability!,
        'whenStable',
        [allowInterop(decrement)],
      );
    }
  }

  /// Adds [_whenAllStable] to `self.frameworkStabilizers`.
  ///
  /// The code handling `frameworkStabilizers` must be more defensive than the
  /// code handling `ngTestabilityRegistries` because other (non-Angular,
  /// non-Dart) frameworks may also set and add stabilizers to this list at any
  /// time.
  ///
  /// TODO(b/168535057): Document where `frameworkStabilizers` is defined.
  static void _export$frameworkStabilizers() {
    // There is no way to know if other frameworks will put `null` inside.
    List<Object?> frameworkStabilizers;
    if (js_util.hasProperty(_self, 'frameworkStabilizers')) {
      frameworkStabilizers = unsafeCast(
        js_util.getProperty(_self, 'frameworkStabilizers'),
      );
    } else {
      js_util.setProperty(
        _self,
        'frameworkStabilizers',
        frameworkStabilizers = [],
      );
    }
    frameworkStabilizers.add(allowInterop(_whenAllStable));
  }

  @override
  Testability? findTestabilityInTree(
    TestabilityRegistry registry,
    Element? element,
  ) {
    if (element == null) {
      return null;
    }
    final testability = registry.testabilityFor(element);
    return testability ?? findTestabilityInTree(registry, element.parent);
  }

  /// Given the dart [registry] object, returns a JS-interop enabled object.
  ///
  /// TODO(b/168535057): Rework using `@JS()` similar to [JsTestability].
  static Object _createRegistry(TestabilityRegistry registry) {
    final object = unsafeCast<Object>(js_util.newObject());

    JsTestability? getAngularTestability(Element element) {
      final dartTestability = registry.findTestabilityInTree(element);
      return dartTestability?.asJsApi();
    }

    js_util.setProperty(
      object,
      'getAngularTestability',
      allowInterop(getAngularTestability),
    );

    List<JsTestability> getAllAngularTestabilities() {
      return registry.allTestabilities.map((t) => t.asJsApi()).toList();
    }

    js_util.setProperty(
      object,
      'getAllAngularTestabilities',
      allowInterop(getAllAngularTestabilities),
    );

    return object;
  }
}

extension on Testability {
  JsTestability asJsApi() {
    return JsTestability(
      isStable: allowInterop(() => isStable),
      whenStable: allowInterop(whenStable),
    );
  }
}
