// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/bootstrap/run.dart';
import 'package:angular/src/core/application_ref.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/linker/view_ref.dart';
import 'package:angular/src/core/render/api.dart';
import 'package:angular/src/platform/dom/shared_styles_host.dart';

/// Returns an application injector factory for [providers], if any.
InjectorFactory testInjectorFactory(List<dynamic> providers) {
  // Identity InjectorFactory (No-op).
  if (providers.isEmpty) {
    return ([parent]) => parent;
  }
  return ([parent]) {
    return ReflectiveInjector.resolveAndCreate([
      providers,
    ], parent);
  };
}

/// Returns a future that completes with a new instantiated component.
///
/// It is treated as the root component of a temporary application for testing
/// and created within the [hostElement] provided.
///
/// If [beforeChangeDetection] is specified, allows interacting with instance of
/// component created _before_ the initial change detection occurs; for example
/// setting up properties or state.
Future<ComponentRef<E>> bootstrapForTest<E>(
  ComponentFactory<E> componentFactory,
  Element hostElement,
  InjectorFactory userInjector, {
  void Function(E) beforeChangeDetection,
}) {
  if (componentFactory == null) {
    throw new ArgumentError.notNull('componentFactory');
  }
  if (hostElement == null) {
    throw new ArgumentError.notNull('hostElement');
  }
  if (userInjector == null) {
    throw new ArgumentError.notNull('userInjector');
  }
  // This should be kept in sync with 'runApp' as much as possible.
  final injector = appInjector(userInjector);
  final ApplicationRefImpl appRef = injector.get(ApplicationRef);
  NgZoneError caughtError;
  final NgZone ngZone = injector.get(NgZone);
  final onErrorSub = ngZone.onError.listen((e) {
    caughtError = e;
  });
  // Code works improperly when .run is typed to return FutureOr:
  // https://github.com/dart-lang/sdk/issues/32285.
  return appRef.run<ComponentRef<E>>(() {
    return _runAndLoadComponent(
      appRef,
      componentFactory,
      hostElement,
      injector,
      beforeChangeDetection: beforeChangeDetection,
    ).then((ComponentRef<E> componentRef) async {
      // ComponentRef<E> is due to weirdness around type promotion:
      // https://github.com/dart-lang/sdk/issues/32284
      hostElement.append(componentRef.location);
      await ngZone.onTurnDone.first;
      // Required to prevent onTurnDone to become re-entrant, as described in
      // the bug https://github.com/dart-lang/angular/issues/631. Without this
      // the .first.then((_) => ...) eventually calls stabilization, which
      // in turn triggers another zone entry/exit, which is illegal.
      //
      // Can be removed if NgZone.onTurnDone ever supports re-entry, either by
      // no longer using Streams or fixing dart:async.
      await new Future.value();
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

Future<ComponentRef<E>> _runAndLoadComponent<E>(
  ApplicationRefImpl appRef,
  ComponentFactory<E> componentFactory,
  Element hostElement,
  Injector injector, {
  void beforeChangeDetection(E componentInstance),
}) {
  // TODO: Consider using hostElement instead.
  sharedStylesHost ??= new DomSharedStylesHost(document);
  final componentRef = componentFactory.create(injector);
  final cdMode = (componentRef.hostView as ViewRefImpl).appView.cdMode;
  if (!isDefaultChangeDetectionStrategy(cdMode) &&
      cdMode != ChangeDetectionStrategy.CheckAlways) {
    throw new UnsupportedError(
        'The root component in an Angular test or application must use the '
        'default form of change detection (ChangeDetectionStrategy.Default). '
        'Instead got ${(componentRef.hostView as ViewRefImpl).appView.cdMode} '
        'on component $E.');
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
  return new Future.value(componentRef);
}
