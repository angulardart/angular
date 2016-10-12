import 'dart:async';
import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/platform/browser_static.dart';
import 'package:angular2/src/core/application_ref.dart';
import 'package:angular2/src/core/linker/app_view_utils.dart';
import 'package:angular2/src/facade/exception_handler.dart';

import 'error_handler.dart';

/// Creates a new application based on a root [appComponentType].
///
/// The component is bootstrapped within [hostElement].
///
/// If [onLoad] is specified, is called _before_ initial change detection.
Future<ComponentRef> ngTestBootstrap/*<E>*/(
  Type appComponentType,
  Element hostElement, {
  void onLoad(component/*=E*/),
  List<Object> userProviders: const [],
}) {
  // This should be kept in sync with 'bootstrapStatic' as much as possible.
  final platformRef = browserStaticPlatform();
  final appInjector = ReflectiveInjector.resolveAndCreate([
    BROWSER_APP_PROVIDERS,
    const Provider(ExceptionHandler, useClass: TestExceptionHandler),
    userProviders,
  ], platformRef.injector);
  appViewUtils ??= appInjector.get(AppViewUtils);
  final ApplicationRefImpl appRef = appInjector.get(ApplicationRef);
  return appRef.run(() {
    return _runAndLoadComponent(
      appRef,
      appComponentType,
      hostElement,
      appInjector,
      onLoad: onLoad,
    );
  });
}

Future<ComponentRef> _runAndLoadComponent/*<E>*/(
  ApplicationRefImpl appRef,
  Type appComponentType,
  Element hostElement,
  Injector appInjector, {
  void onLoad(component/*=E*/),
}) {
  return (appInjector.get(DynamicComponentLoader) as DynamicComponentLoader)
      .loadAsRootIntoNode(
    appComponentType,
    appInjector,
    overrideNode: hostElement,
  )
      .then((componentRef) {
    // If we want an event before any change detection occurs.
    if (onLoad != null) {
      onLoad(componentRef.instance);
    }
    // Once the component is initially created, we hook it up (manually)
    // into the change detection tree. This is required because we aren't
    // going through 'bootstrap', which normally would have initialized
    // the tree.
    appRef.registerChangeDetector(componentRef.changeDetectorRef);
    componentRef.onDestroy(() {
      appRef.unregisterChangeDetector(componentRef.changeDetectorRef);
    });

    // Initial tick so users can catch ngOnInit-based exceptions.
    appRef.tick();
    return componentRef;
  });
}
