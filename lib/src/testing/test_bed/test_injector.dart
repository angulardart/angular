import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/platform/browser_static.dart';
import 'package:angular2/src/core/application_ref.dart';

/// Test fixture facade into Angular dependency injection.
class TestInjector {
  final Injector _appInjector;
  final PlatformRef _platformRef;

  /// Creates a new [TestInjector] by resolving [userProviders].
  ///
  /// Automatically adds providers necessary to bootstrap Angular statically
  /// *before* any [userProviders] so some overrides are possible.
  factory TestInjector(List<Object> userProviders) {
    var platformRef = browserStaticPlatform();
    return new TestInjector._(
        ReflectiveInjector.resolveAndCreate(
            [BROWSER_APP_PROVIDERS, userProviders], platformRef.injector),
        platformRef);
  }

  TestInjector._(this._appInjector, this._platformRef);

  /// Cleans up any global state created by the injector.
  void dispose() {
    ApplicationRefImpl appRef = _get(ApplicationRef);
    appRef.dispose();
    _platformRef.dispose();
  }

  /// Loads [componentType] as the root component for the test application.
  ///
  /// Similar characteristics to `bootstrap` for actual applications.
  Future<ComponentRef> loadComponent(Type componentType) {
    document.body.append(new Element.tag('ng-test-root'));
    ApplicationRefImpl appRef = _get(ApplicationRef);
    return appRef.run(() {
      DynamicComponentLoader componentLoader = _get(DynamicComponentLoader);
      return componentLoader
          .loadAsRoot(componentType, 'ng-test-root', _appInjector)
          .then((componentRef) {
        // Once the component is initially created, we hook it up (manually)
        // into the change detection tree. This is required because we aren't
        // going through 'bootstrap', which normally would have initialized
        // the tree.
        //
        // TODO(matanl): Consolidate bootstrap and test bootstrap.
        appRef.registerChangeDetector(componentRef.changeDetectorRef);
        componentRef.onDestroy(() {
          appRef.unregisterChangeDetector(componentRef.changeDetectorRef);
        });
        return componentRef;
      });
    });
  }

  Object _get(Object token) => _appInjector.get(token);
}
