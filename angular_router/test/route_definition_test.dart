// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/route_definition.dart';

import 'route_definition_test.template.dart'
    as ng; // ignore: uri_has_not_been_generated

void main() {
  ng.initReflector();

  group('$RouteDefinition', () {
    group(':$ComponentRouteDefinition', () {
      test('should create a route to an `@Component` type', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes',
          component: ng.HeroesComponentNgFactory,
        );
        expect(def.component, ng.HeroesComponentNgFactory);
      });

      test('should fail "assertValid" with a null or empty path', () {
        final def1 = RouteDefinition(
          path: null,
          component: ng.HeroesComponentNgFactory,
        );
        expect(def1.assertValid, throwsStateError);
      });

      test('should fail "assertValid" with a null component factory', () {
        var def1 = RouteDefinition(path: '/1', component: null);
        expect(def1.assertValid, throwsStateError);
      });
    });

    group(':$DeferredRouteDefinition', () {
      test('should create a route to lazy-load a component type', () {
        DeferredRouteDefinition def =
            RouteDefinition.defer(path: '/heroes', loader: loadHeroesComponent);
        expect(def.loader, loadHeroesComponent);
      });

      test('should fail "assertValid" with a null loader function', () {
        var def1 = RouteDefinition.defer(path: '/1', loader: null);
        expect(def1.assertValid, throwsStateError);
      });
    });

    group(':$RedirectRouteDefinition', () {
      test('should create a route to redirect to another definition', () {
        RedirectRouteDefinition def =
            RouteDefinition.redirect(path: '/good-guys', redirectTo: '/heroes');
        expect(def.redirectTo, '/heroes');
      });

      test('should fail "assertValid" with a null `to` path', () {
        var def1 = RouteDefinition.redirect(path: '/1', redirectTo: null);
        expect(def1.assertValid, throwsStateError);
      });

      test('should fail "assertValid" with unknown parameters', () {
        var def1 = RouteDefinition.redirect(path: '/1', redirectTo: '/2/:id');
        expect(def1.assertValid, throwsStateError);
      });
    });

    group('toRepExp()', () {
      test('should prefix match to only strings with same start', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes',
          component: ng.HeroesComponentNgFactory,
        );
        expect(def.toRegExp().matchAsPrefix('/heroes'), isNotNull);
        expect(def.toRegExp().matchAsPrefix('/heroes/path1/path2'), isNotNull);

        expect(def.toRegExp().matchAsPrefix('/path1/heroes/path2'), isNull);
        expect(def.toRegExp().matchAsPrefix('/path1'), isNull);
      });

      test('should match url params', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes/:heroName/:heroId',
          component: ng.HeroesComponentNgFactory,
        );
        Match match =
            def.toRegExp().matchAsPrefix('/heroes/jack%20daniel/id-123');
        expect(match, isNotNull);
        expect(match[1], 'jack%20daniel');
        expect(match[2], 'id-123');
      });

      test('should not match url params that are invalid url encodings', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes/:heroName/:heroId',
          component: ng.HeroesComponentNgFactory,
        );
        Match match =
            def.toRegExp().matchAsPrefix('/heroes/jack%2Hdaniel/id-123');
        expect(match, isNull);
      });
    });

    group('toUrl()', () {
      test('should throw if params values is null', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes',
          component: ng.HeroesComponentNgFactory,
        );
        expect(() => def.toUrl(null), throwsArgumentError);
      });

      test('should return the path when there are no params', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes',
          component: ng.HeroesComponentNgFactory,
        );
        expect(def.toUrl(), '/heroes');
      });

      test('should populate url params', () {
        ComponentRouteDefinition def = RouteDefinition(
          path: '/heroes/:heroId/:heroName',
          component: ng.HeroesComponentNgFactory,
        );
        expect(def.toUrl({'heroId': 'id-123', 'heroName': 'jack daniel'}),
            '/heroes/id-123/jack%20daniel');
      });
    });
  });
}

@Component(
  selector: 'heroes',
  template: '',
)
class HeroesComponent {}

@Component(
  selector: 'villains',
  template: '',
)
class VillainsComponent {}

// Examples of a deferred loader function.
//
// In real code, `loadLibrary` would be used before referencing the type.
Future<ComponentFactory> loadHeroesComponent() async =>
    ng.HeroesComponentNgFactory;
Future<ComponentFactory> loadVillainsComponent() async =>
    ng.VillainsComponentNgFactory;
