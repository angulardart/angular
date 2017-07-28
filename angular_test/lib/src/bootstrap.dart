// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/core/linker/view_ref.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';

/// Returns an application injector for [providers] based on a [platform].
///
/// Optionally can include the deprecated router APIs [withRouter].
Injector createTestInjector(List<dynamic> providers, {bool withRouter: false}) {
  final appInjector = ReflectiveInjector.resolveAndCreate([
    BROWSER_APP_PROVIDERS,
    withRouter
        ? const [
            const Provider(LocationStrategy, useClass: MockLocationStrategy),
          ]
        : const [],
    providers,
  ], browserStaticPlatform().injector);
  appViewUtils ??= appInjector.get(AppViewUtils);
  return appInjector;
}

/// Returns a future that completes with a new instantiated component.
///
/// It is treated as the root component of a temporary application for testing
/// and created within the [hostElement] provided.
///
/// If [beforeChangeDetection] is specified, allows interacting with instance of
/// component created _before_ the initial change detection occurs; for example
/// setting up properties or state.
Future<ComponentRef> bootstrapForTest<E>(
  Type appComponentType,
  Element hostElement, {
  void beforeChangeDetection(E componentInstance),
  List addProviders: const [],
}) {
  if (appComponentType == null) {
    throw new ArgumentError.notNull('appComponentType');
  }
  if (hostElement == null) {
    throw new ArgumentError.notNull('hostElement');
  }
  // This should be kept in sync with 'bootstrapStatic' as much as possible.
  final appInjector = createTestInjector([
    BROWSER_APP_PROVIDERS,
    addProviders,
  ]);
  final ApplicationRefImpl appRef = appInjector.get(ApplicationRef);
  NgZoneError caughtError;
  final NgZone ngZone = appInjector.get(NgZone);
  final onErrorSub = ngZone.onError.listen((e) {
    caughtError = e;
  });
  return appRef.run(() {
    return _runAndLoadComponent(
      appRef,
      appComponentType,
      hostElement,
      appInjector,
      beforeChangeDetection: beforeChangeDetection,
    ).then((componentRef) async {
      hostElement.append(componentRef.location);
      await ngZone.onTurnDone.first;
      onErrorSub.cancel();
      if (caughtError != null) {
        return new Future.error(
          caughtError.error,
          new StackTrace.fromString(caughtError.stackTrace.join('\n')),
        );
      }
      return componentRef;
    });
  });
}

Future<ComponentRef> _runAndLoadComponent<E>(
  ApplicationRefImpl appRef,
  Type appComponentType,
  Element hostElement,
  Injector appInjector, {
  void beforeChangeDetection(E componentInstance),
}) async {
  final resolver = appInjector.get(ComponentResolver) as ComponentResolver;
  final componentFactory = await resolver.resolveComponent(appComponentType);
  final componentRef = componentFactory.create(appInjector);
  final cdMode = (componentRef.hostView as ViewRefImpl).appView.cdMode;
  if (!isDefaultChangeDetectionStrategy(cdMode) &&
      cdMode != ChangeDetectionStrategy.CheckAlways) {
    throw new UnsupportedError(
        'The root component in an Angular test or application must use the '
        'default form of change detection (ChangeDetectionStrategy.Default). '
        'Instead got ${(componentRef.hostView as ViewRefImpl).appView.cdMode} '
        'on component $appComponentType.');
  }
  if (beforeChangeDetection != null) {
    beforeChangeDetection(componentRef.instance);
  }
  hostElement.append(componentRef.location);
  appRef.registerChangeDetector(componentRef.changeDetectorRef);
  componentRef.onDestroy(() {
    appRef.unregisterChangeDetector(componentRef.changeDetectorRef);
  });
  appRef.tick();
  return componentRef;
}
