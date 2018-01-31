// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';

import 'router_link_active_directive_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  FakeRouter fakeRouter;

  setUp(() {
    fakeRouter = new FakeRouter();
  });

  tearDown(disposeAnyRunningTest);

  test('should add/remove a CSS class as a route is activated', () async {
    final fixture = await new NgTestBed<TestRouterLinkActive>().addProviders([
      provide(Location, useValue: const NullLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (component) {
      component.link = '/user/bob';
      fakeRouter.current = new RouterState('/user/jill', const []);
    });
    final anchor = fixture.rootElement.querySelector('a');
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current = new RouterState('/user/bob', const []);
    });
    expect(anchor.classes, contains('active-link'));
  });

  test('should validate queryParams and fragment', () async {
    final fixture = await new NgTestBed<TestRouterLinkActive>().addProviders([
      provide(Location, useValue: const NullLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (component) {
      component.link = '/user/bob?param=1#frag';
      fakeRouter.current = new RouterState('/user/bob', const []);
    });
    final anchor = fixture.rootElement.querySelector('a');
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current = new RouterState('/user/bob', const [],
          queryParameters: {'param': '1'});
    });
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current =
          new RouterState('/user/bob', const [], fragment: 'frag');
    });
    expect(anchor.classes, isEmpty);

    await fixture.update((_) {
      fakeRouter.current = new RouterState('/user/bob', const [],
          queryParameters: {'param': '1'}, fragment: 'frag');
    });
    expect(anchor.classes, contains('active-link'));
  });

  test(
      'should ignore the current urls queryParams and fragment if not '
      'specified in the routerLinks', () async {
    final fixture = await new NgTestBed<TestRouterLinkActive>().addProviders([
      provide(Location, useValue: const NullLocation()),
      provide(Router, useValue: fakeRouter),
    ]).create(beforeChangeDetection: (component) {
      component.link = '/user/bob';
      fakeRouter.current = new RouterState('/user/bob', const [],
          queryParameters: {'param': '1'}, fragment: 'frag');
    });
    final anchor = fixture.rootElement.querySelector('a');
    expect(anchor.classes, contains('active-link'));
  });
}

@Component(
  selector: 'test-router-link-active',
  directives: const [
    RouterLink,
    RouterLinkActive,
  ],
  template: r'''
    <a [routerLink]="link" routerLinkActive="active-link">Bob</a>
  ''',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestRouterLinkActive {
  String link;
}

class FakeRouter implements Router {
  final _streamController =
      new StreamController<RouterState>.broadcast(sync: true);

  RouterState _current;

  @override
  RouterState get current => _current;
  set current(RouterState current) {
    _streamController.add(current);
    _current = current;
  }

  @override
  noSuchMethod(i) => super.noSuchMethod(i);

  @override
  Stream<RouterState> get stream => _streamController.stream;
}

class NullLocation implements Location {
  const NullLocation();

  @override
  noSuchMethod(i) => null;
}
