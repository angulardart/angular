// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'dart:html' hide Location;

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';

void main() {
  FakeRouter fakeRouter;

  setUp(() {
    fakeRouter = new FakeRouter();
  });

  tearDown(disposeAnyRunningTest);

  test('should attempt to navigate to the provided link', () async {
    final fixture = await new NgTestBed<TestRouterLink>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create();
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, isEmpty);
    await fixture.update((comp) {
      comp.routerLink = '/users/bob';
    });
    expect(anchor.pathname, '/users/bob');
    expect(fakeRouter.lastNavigatedPath, isNull);
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, '/users/bob');
  });

  test('should parse out query params and fragment', () async {
    final fixture =
        await new NgTestBed<TestRouterLinkWithTarget>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (comp) {
      comp.routerLink = '/users/bob?param1=one&param2=2#frag';
    });
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, '/users/bob');
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, '/users/bob');
    expect(fakeRouter.lastNavigatedParams.queryParameters, {
      'param1': 'one',
      'param2': '2',
    });
    expect(fakeRouter.lastNavigatedParams.fragment, 'frag');
  });

  test('should not use the router when the target is not _self', () async {
    final fixture =
        await new NgTestBed<TestRouterLinkWithTarget>().addProviders([
      provide(Location, useValue: const FakeLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (comp) {
      comp.routerLink = '/users/bob';
    });
    final anchor = fixture.rootElement.querySelector('a') as AnchorElement;
    expect(anchor.pathname, '/users/bob');
    expect(anchor.target, '_parent');
    await fixture.update((_) => anchor.click());
    expect(fakeRouter.lastNavigatedPath, isNull);
  });
}

@Component(
  selector: 'test-router-link',
  directives: const [
    RouterLink,
  ],
  template: r'''
    <a [routerLink]="routerLink"></a>
  ''',
)
class TestRouterLink {
  String routerLink;
}

@Component(
  selector: 'test-router-link',
  directives: const [
    RouterLink,
  ],
  template: r'''
    <a [routerLink]="routerLink" target="_parent"></a>
  ''',
)
class TestRouterLinkWithTarget {
  String routerLink;
}

class FakeRouter implements Router {
  String lastNavigatedPath;
  NavigationParams lastNavigatedParams;

  @override
  Future<NavigationResult> navigate(String routerLink,
      [NavigationParams navigationParams]) async {
    lastNavigatedPath = routerLink;
    lastNavigatedParams = navigationParams;
    return null;
  }

  @override
  noSuchMethod(i) => super.noSuchMethod(i);
}

class FakeLocation implements Location {
  const FakeLocation();

  @override
  String prepareExternalUrl(String url) => url;

  @override
  noSuchMethod(i) => null;
}
