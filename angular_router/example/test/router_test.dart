// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router.example/app_component.dart';
import 'package:angular_router.example/testing/app_component_po.dart';
import 'package:angular_test/angular_test.dart';

void main() {
  group('$Router', () {
    NgTestFixture<TestRouter> fixture;
    AppComponentPO pageObject;
    Router router;

    Future login() async {
      expect(await router.navigate('/login'), NavigationResult.SUCCESS);

      LoginComponentPO login = await pageObject.login();
      expect(login, isNotNull);
      await login.login('username', 'password');

      await new Future.delayed(new Duration(seconds: 5));
    }

    Future setUp([Iterable providers = const []]) async {
      fixture = await new NgTestBed<TestRouter>()
          .addProviders([provide(APP_BASE_HREF, useValue: ''), routerProviders]
            ..addAll(providers))
          .create();
      fixture.update((TestRouter component) => router = component.router);
      pageObject = await fixture.resolvePageObject(AppComponentPO);
    }

    tearDown(disposeAnyRunningTest);

    test('the base url should useAsDefault the dashboard', () async {
      await setUp();
      expect(await router.navigate('/'), NavigationResult.SUCCESS);
      expect(await pageObject.dashboard(), isNotNull);
      expect(router.current.path, '');
    });

    group('the router should navigate to the initialized URL', () {
      test('path strategy', () async {
        await setUp([
          provide(PlatformLocation,
              useValue: new FakePlatformLocation(
                  '/dashboard', '?param1=value', '#fragment'))
        ]);
        expect(router.current.path, '/dashboard');
        expect(router.current.queryParameters, {'param1': 'value'});
        expect(router.current.fragment, 'fragment');
        expect(await pageObject.dashboard(), isNotNull);
      });

      test('path strategy', () async {
        await setUp([
          routerProvidersHash,
          provide(PlatformLocation,
              useValue: new FakePlatformLocation(
                  '', '', '#dashboard?param1=value#fragment'))
        ]);
        expect(router.current.path, 'dashboard');
        expect(router.current.queryParameters, {'param1': 'value'});
        expect(router.current.fragment, 'fragment');
        expect(await pageObject.dashboard(), isNotNull);
      });
    });

    test('navigation works the same with a base_href', () async {
      await setUp([provide(APP_BASE_HREF, useValue: 'base/href')]);
      expect(await router.navigate('/'), NavigationResult.SUCCESS);
      expect(await pageObject.dashboard(), isNotNull);
      expect(router.current.path, '');
    });

    test('navigation with hash strategy cuts a starting /', () async {
      await setUp(routerProvidersHash);
      expect(await router.navigate('/'), NavigationResult.SUCCESS);
      expect(await pageObject.dashboard(), isNotNull);
      expect(router.current.path, '');

      expect(await router.navigate('/login'), NavigationResult.SUCCESS);
      expect(await pageObject.login(), isNotNull);
      expect(router.current.path, 'login');
    });

    test('canActivate should block the admin component if not logged in',
        () async {
      await setUp();
      expect(await router.navigate('/admin/heroes'),
          NavigationResult.BLOCKED_BY_GUARD);
    });

    test('canActivate should resolve the admin component if logged in',
        () async {
      await setUp();
      await login();

      expect(await router.navigate('/admin/heores'), NavigationResult.SUCCESS);
    });

    test('mistyping an admin url should redirect to the dashboard', () async {
      await setUp();
      await login();

      expect(await router.navigate('/admin/redirected_url'),
          NavigationResult.SUCCESS);
      var admin = await pageObject.admin();
      expect(admin, isNotNull);
      expect(await admin.adminDashboard(), isNotNull);
      expect(router.current.path, '/admin/dashboard');
    });
  });
}

class FakePlatformLocation implements PlatformLocation {
  final String _pathname;
  final String _search;
  final String _hash;

  const FakePlatformLocation(this._pathname, this._search, this._hash);

  @override
  String get pathname => _pathname;

  @override
  String get search => _search;

  @override
  String get hash => _hash;

  @override
  noSuchMethod(i) => null;
}

@Component(
  selector: 'test-router',
  directives: const [AppComponent],
  template: r'''
<my-app></my-app>
''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class TestRouter {
  Router router;

  TestRouter(this.router);
}
