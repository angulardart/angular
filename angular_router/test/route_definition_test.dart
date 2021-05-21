import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/src/route_definition.dart';

import 'route_definition_test.template.dart'
    as ng; // ignore: uri_has_not_been_generated

void main() {
  ng.initReflector();

  group('$RouteDefinition', () {
    group(':$ComponentRouteDefinition', () {
      test('should create a route to an `@Component` type', () {
        final factory = ng.createHeroesComponentFactory();
        final def = RouteDefinition(
          path: '/heroes',
          component: factory,
        ) as ComponentRouteDefinition;
        expect(def.component, factory);
      });

      test('should fail "assertValid" with a null component factory', () {
        var def1 = RouteDefinition(path: '/1', component: null);
        expect(def1.assertValid, throwsStateError);
      });
    });

    group(':$DeferredRouteDefinition', () {
      test('should create a route to lazy-load a component type', () {
        final def = RouteDefinition.defer(
          path: '/heroes',
          loader: loadHeroesComponent,
        ) as DeferredRouteDefinition;
        expect(def.loader, loadHeroesComponent);
      });
    });

    group(':$RedirectRouteDefinition', () {
      test('should create a route to redirect to another definition', () {
        final def = RouteDefinition.redirect(
          path: '/good-guys',
          redirectTo: '/heroes',
        ) as RedirectRouteDefinition;
        expect(def.redirectTo, '/heroes');
      });

      test('should fail "assertValid" with unknown parameters', () {
        var def1 = RouteDefinition.redirect(path: '/1', redirectTo: '/2/:id');
        expect(def1.assertValid, throwsStateError);
      });
    });

    group('toRepExp()', () {
      test('should prefix match to only strings with same start', () {
        final def = RouteDefinition(
          path: '/heroes',
          component: ng.createHeroesComponentFactory(),
        ) as ComponentRouteDefinition;
        expect(def.toRegExp().matchAsPrefix('/heroes'), isNotNull);
        expect(def.toRegExp().matchAsPrefix('/heroes/path1/path2'), isNotNull);

        expect(def.toRegExp().matchAsPrefix('/path1/heroes/path2'), isNull);
        expect(def.toRegExp().matchAsPrefix('/path1'), isNull);
      });

      test('should match url params', () {
        final def = RouteDefinition(
          path: '/heroes/:heroName/:heroId',
          component: ng.createHeroesComponentFactory(),
        ) as ComponentRouteDefinition;
        var match =
            def.toRegExp().matchAsPrefix('/heroes/jack%20daniel/id-123');
        expect(match, isNotNull);
        expect(match![1], 'jack%20daniel');
        expect(match[2], 'id-123');
      });

      test('should not match url params that are invalid url encodings', () {
        final def = RouteDefinition(
          path: '/heroes/:heroName/:heroId',
          component: ng.createHeroesComponentFactory(),
        ) as ComponentRouteDefinition;
        var match =
            def.toRegExp().matchAsPrefix('/heroes/jack%2Hdaniel/id-123');
        expect(match, isNull);
      });
    });

    group('toUrl()', () {
      test('should return the path when there are no params', () {
        final def = RouteDefinition(
          path: '/heroes',
          component: ng.createHeroesComponentFactory(),
        ) as ComponentRouteDefinition;
        expect(def.toUrl(), '/heroes');
      });

      test('should populate url params', () {
        final def = RouteDefinition(
          path: '/heroes/:heroId/:heroName',
          component: ng.createHeroesComponentFactory(),
        ) as ComponentRouteDefinition;
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

// Examples of a deferred loader function.
//
// In real code, `loadLibrary` would be used before referencing the type.
Future<ComponentFactory<HeroesComponent>> loadHeroesComponent() async =>
    ng.createHeroesComponentFactory();
