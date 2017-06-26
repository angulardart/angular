// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:pageloader/html.dart';
import 'package:angular/angular.dart';

import 'bed.dart';
import 'stabilizer.dart';

/// Inject a service for [tokenOrType] from [fixture].
///
/// This is for compatibility reasons only and should not be used otherwise.
T injectFromFixture<T>(NgTestFixture fixture, tokenOrType) {
  return fixture._rootComponentRef.injector.get(tokenOrType);
}

/// Returns the component instance backing [fixture].
///
/// This is for compatibility reasons only and should not be used otherwise.
T componentOfFixture<T>(NgTestFixture<T> fixture) {
  return fixture._rootComponentRef.instance;
}

class NgTestFixture<T> {
  final ApplicationRef _applicationRef;
  final ComponentRef _rootComponentRef;
  final NgTestStabilizer _testStabilizer;

  HtmlPageLoader _pageLoaderInstance;

  factory NgTestFixture(
    ApplicationRef applicationRef,
    ComponentRef rootComponentRef,
    NgTestStabilizer testStabilizer,
  ) = NgTestFixture<T>._;

  NgTestFixture._(
    this._applicationRef,
    this._rootComponentRef,
    this._testStabilizer,
  );

  /// Destroys the test case, returning a future that completes after disposed.
  ///
  /// In most cases, it is preferable to use `disposeAnyRunningTest`.
  Future<Null> dispose() async {
    await update();
    _rootComponentRef.destroy();
    _applicationRef.dispose();
    activeTest = null;
  }

  /// Return a page object representing [pageObjectType] from the DOM.
  Future<T> resolvePageObject<T>(Type pageObjectType) async {
    await update();
    return _pageLoader.getInstance<T>(pageObjectType);
  }

  /// A page loader instance representing this test fixture.
  PageLoader get _pageLoader => _pageLoaderInstance ??= new HtmlPageLoader(
        rootElement,
        executeSyncedFn: (fn) async {
          await fn();
          return update;
        },
        useShadowDom: false,
      );

  /// Root element.
  Element get rootElement => _rootComponentRef.location.nativeElement;

  /// Returns a future that completes after the DOM is reported stable.
  ///
  /// It is import to `update` before making an assertion on the DOM, as Angular
  /// (and other services) could be waiting (asynchronously) to make a change -
  /// and often you'd want to assert against the _final_ state.
  ///
  /// #Example use
  /// ```dart
  /// expect(fixture.text, contains('Loading...'));
  /// await fixture.update();
  /// expect(fixture.text, contains('Hello World'));
  /// ```
  ///
  /// Optionally, pass a [run] to run _before_ stabilizing:
  /// await fixture.update((c) {
  ///   c.value = 5;
  /// });
  /// expect(fixture.text, contains('5 little piggies'));
  Future<Null> update([run(T instance)]) {
    return _testStabilizer.stabilize(run: () {
      if (run != null) {
        new Future<Null>.sync(() {
          run(_rootComponentRef.instance);
        });
      }
    });
  }

  /// All text nodes within the fixture.
  ///
  /// Provided as a convenience to do simple `expect` matchers.
  String get text => rootElement.text;
}
