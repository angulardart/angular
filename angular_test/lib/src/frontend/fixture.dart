// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:func/func.dart';
import 'package:pageloader/objects.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/core/linker/view_ref.dart';
import 'package:angular/src/debug/debug_app_view.dart';
import 'package:angular/src/debug/debug_node.dart';

import 'bed.dart';
import 'stabilizer.dart';

/// Inject a service for [tokenOrType] from [fixture].
///
/// This is for compatibility reasons only and should not be used otherwise.
T injectFromFixture<T>(NgTestFixture fixture, tokenOrType) {
  return fixture._rootComponentRef.injector.get(tokenOrType);
}

class NgTestFixture<T> {
  final ApplicationRef _applicationRef;
  final Func2<Element, NgTestFixture<T>, PageLoader> _pageLoaderFactory;
  final ComponentRef _rootComponentRef;
  final NgTestStabilizer _testStabilizer;

  PageLoader _pageLoaderInstance;

  factory NgTestFixture(
    ApplicationRef applicationRef,
    PageLoader pageLoaderFactory(Element element, NgTestFixture<T> fixture),
    ComponentRef rootComponentRef,
    NgTestStabilizer testStabilizer,
  ) = NgTestFixture<T>._;

  NgTestFixture._(
    this._applicationRef,
    this._pageLoaderFactory,
    this._rootComponentRef,
    this._testStabilizer,
  );

  /// Whether the test component was generated in debug-mode.
  bool get _isDebugMode {
    return (_rootComponentRef.hostView as ViewRefImpl).appView is DebugAppView;
  }

  /// Root debug element, throwing if not available.
  DebugElement get _debugElement {
    if (_isDebugMode) {
      var node = getDebugNode(_rootComponentRef.location);
      if (node is DebugElement) {
        return node;
      }
      throw new StateError('Root is not an element');
    }
    throw new UnsupportedError('Cannot utilize in codegen release mode');
  }

  /// Destroys the test case, returning a future that completes after disposed.
  ///
  /// In most cases, it is preferable to use `disposeAnyRunningTest`.
  Future<Null> dispose() async {
    await update();
    _rootComponentRef.destroy();
    _rootComponentRef.location.parent.remove();
    _applicationRef.dispose();
    activeTest = null;
  }

  /// Return a page object representing [pageObjectType] from the DOM.
  Future<T> resolvePageObject<T>(Type pageObjectType) async {
    await update();
    return _pageLoader.getInstance<T>(pageObjectType);
  }

  /// A page loader instance representing this test fixture.
  PageLoader get _pageLoader {
    return _pageLoaderInstance ??= _pageLoaderFactory(rootElement, this);
  }

  /// Returns the first component instance that matches predicate [test].
  ///
  /// Example use:
  /// ```dart
  /// await fixture.query<FooComponent>(
  ///   (el) => el.componentInstance is FooComponent,
  ///   (foo) {
  ///     // Run expectation or interact.
  ///   },
  /// );
  /// ```
  ///
  /// Calls [run] with `null` if there was no matching element.
  ///
  /// **NOTE**: The root component is _not_ query-able. See [update] instead.
  Future<Null> query<E>(bool test(DebugElement element), run(E instance)) {
    final instance = _debugElement.query(test)?.componentInstance;
    return update((_) => run(instance));
  }

  /// Returns all component instances that matches predicate [test].
  ///
  /// Example use:
  /// ```dart
  /// await fixture.queryAll<FooComponent>(
  ///   (el) => el.componentInstance is FooComponent,
  ///   (foo) {
  ///     // Run expectation or interact.
  ///   },
  /// );
  /// ```
  ///
  /// Calls [run] with an empty iterable if there was no matching element.
  ///
  /// **NOTE**: The root component is _not_ query-able. See [update] instead.
  Future<Null> queryAll<E>(
    bool test(DebugElement element),
    run(Iterable<E> instances),
  ) {
    return update((_) {
      return run(_debugElement.queryAll(test).map((e) => e.componentInstance));
    });
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

  /// A component instance to use for read-only operations (expect, assert)
  /// ONLY.
  ///
  /// Warning this instance is not stabalized and so the test will not be in a
  /// stable state likely leading to unexpected results. State changes to
  /// the instance should be done through the `update` call, or external
  /// stablalized mechanism such as page objects. Use this **ONLY** for simple
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
