// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/src/runtime.dart' show isDevMode;

import 'bed.dart';
import 'stabilizer.dart';

/// Inject a service for [tokenOrType] from [fixture].
///
/// This is for compatibility reasons only and should not be used otherwise.
T injectFromFixture<T>(NgTestFixture<void> fixture, Object tokenOrType) {
  return fixture._rootComponentRef.injector.get(tokenOrType);
}

class NgTestFixture<T> {
  final ApplicationRef _applicationRef;
  final ComponentRef<T> _rootComponentRef;
  final NgTestStabilizer _testStabilizer;

  factory NgTestFixture(
    ApplicationRef applicationRef,
    ComponentRef<T> rootComponentRef,
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
  Future<void> dispose() async {
    await update();
    _rootComponentRef.destroy();
    _rootComponentRef.location.parent.remove();
    _applicationRef.dispose();
    if (isDevMode) {
      debugClearComponentStyles();
    }
    activeTest = null;
  }

  /// Root element.
  Element get rootElement => _rootComponentRef.location;

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
  Future<void> update([void Function(T instance) run]) {
    return _testStabilizer.stabilize(runAndTrackSideEffects: () {
      if (run != null) {
        Future<void>.sync(() {
          _rootComponentRef.update(run);
        });
      }
    });
  }

  /// All text nodes within the fixture.
  ///
  /// Provided as a convenience to do simple `expect` matchers.
  String get text => rootElement.text;

  /// A component instance to use for read-only operations (expect, assert)
  /// ONLY.
  ///
  /// Warning this instance is not stabilized and so the test will not be in a
  /// stable state likely leading to unexpected results. State changes to
  /// the instance should be done through the `update` call, or external
  /// stabilized mechanism such as page objects. Use this **ONLY** for simple
  /// expects of the instance state.
  ///
  /// #Example
  /// ```dart
  /// await fixture.update((c) {
  ///   c.value = 5;
  /// });
  /// expect(fixture.assertOnlyInstance.square, 25, reason:
  ///     'Instance should square the number');
  T get assertOnlyInstance => _rootComponentRef.instance;
}
