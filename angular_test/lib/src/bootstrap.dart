// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/bootstrap/run.dart';
import 'package:angular/src/core/application_ref.dart';

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

/// Used as a "tear-off" of [NgZone].
NgZone _createNgZone() => NgZone();

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
  FutureOr<void> Function(Injector) beforeComponentCreated,
  FutureOr<void> Function(E) beforeChangeDetection,
  NgZone Function() createNgZone = _createNgZone,
}) async {
  if (componentFactory == null) {
    throw ArgumentError.notNull('componentFactory');
  }
  if (hostElement == null) {
    throw ArgumentError.notNull('hostElement');
  }
  if (userInjector == null) {
    throw ArgumentError.notNull('userInjector');
  }
  // This should be kept in sync with 'runApp' as much as possible.
  final injector = appInjector(userInjector, createNgZone: createNgZone);
  final ApplicationRef appRef = injector.get(ApplicationRef);
  NgZoneError caughtError;
  final NgZone ngZone = injector.get(NgZone);
  final onErrorSub = ngZone.onError.listen((e) {
    caughtError = e;
  });

  if (beforeComponentCreated != null) {
    await beforeComponentCreated(injector);
  }

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
      await ngZone.onTurnDone.first;
      // Required to prevent onTurnDone to become re-entrant, as described in
      // the bug https://github.com/dart-lang/angular/issues/631. Without this
      // the .first.then((_) => ...) eventually calls stabilization, which
      // in turn triggers another zone entry/exit, which is illegal.
      //
      // Can be removed if NgZone.onTurnDone ever supports re-entry, either by
      // no longer using Streams or fixing dart:async.
      await Future<void>.value();
      await onErrorSub.cancel();
      if (caughtError != null) {
        return Future.error(
          caughtError.error,
          StackTrace.fromString(caughtError.stackTrace.join('\n')),
        );
      }
      return componentRef;
    });
  });
}

Future<ComponentRef<E>> _runAndLoadComponent<E>(
  ApplicationRef appRef,
  ComponentFactory<E> componentFactory,
  Element hostElement,
  Injector injector, {
  FutureOr<void> beforeChangeDetection(E componentInstance),
}) {
  final componentRef = componentFactory.create(injector);

  Future<ComponentRef<E>> loadComponent() {
    hostElement.append(componentRef.location);
    appRef.registerChangeDetector(componentRef.changeDetectorRef);
    componentRef.onDestroy(() {
      appRef.unregisterChangeDetector(componentRef.changeDetectorRef);
    });
    appRef.tick();
    return Future.value(componentRef);
  }

  FutureOr<void> beforeChangeDetectionReturn;
  if (beforeChangeDetection != null) {
    beforeChangeDetectionReturn = beforeChangeDetection(componentRef.instance);
  }

  if (beforeChangeDetectionReturn is Future<void>) {
    return beforeChangeDetectionReturn.then((_) => loadComponent());
  } else {
    return loadComponent();
  }
}
