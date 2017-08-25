@TestOn('browser')
import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/angular.dart';

void main() {
  Injector injector;

  group('Injector.empty', () {
    setUp(() => injector = const Injector.empty());

    test('should throw by default when `get` is invoked', () {
      expect(
        () => injector.get(HeroService),
        throwsWith('No provider found for $HeroService.'),
      );
    });

    test('should return a default value if supplied', () {
      final defaultHeroService = new HeroService();
      expect(
        injector.get(HeroService, defaultHeroService),
        defaultHeroService,
      );
    });
  });

  group('Injector.map', () {
    test('should throw by default when a key is not found', () {
      injector = new Injector.map();
      expect(
        () => injector.get(HeroService),
        throwsWith('No provider found for $HeroService.'),
      );
    });

    test('should return a default value if supplied', () {
      injector = new Injector.map();
      final defaultHeroService = new HeroService();
      expect(
        injector.get(HeroService, defaultHeroService),
        defaultHeroService,
      );
    });

    test('should return a value if token present in map', () {
      final aHeroService = new HeroService();
      injector = new Injector.map({HeroService: aHeroService});
      expect(injector.get(HeroService), aHeroService);
    });

    test('should return self when $Injector is the token', () {
      injector = new Injector.map();
      expect(injector.get(Injector), injector);
    });

    test('should ask the parent injector if the token is missing', () {
      final aHeroService = new HeroService();
      final parent = new Injector.map({HeroService: aHeroService});
      final child = new Injector.map(const {}, parent);
      expect(child.get(HeroService), aHeroService);
    });

    test('should override parent bindings with child token bindings', () {
      final parentHeroService = new HeroService();
      final childHeroService = new HeroService();
      final parent = new Injector.map({HeroService: parentHeroService});
      final child = new Injector.map({HeroService: childHeroService}, parent);
      expect(child.get(HeroService), childHeroService);
    });

    test('should produce good error messages within $ReflectiveInjector', () {
      final parentInjector = new Injector.map();
      final childInjector = ReflectiveInjector.resolveAndCreate(
        [
          provide(
            HeroPanel,
            useFactory: (HeroService service) => new HeroPanel(service),
            deps: const [HeroService],
          ),
        ],
        parentInjector,
      );
      // TODO(matanl): Support a key-based chain error in dev-mode.
      expect(
        () => childInjector.get(HeroService),
        throwsWith('No provider found for $HeroService'),
      );
    });
  });
}

class HeroService {}

class HeroPanel {
  HeroPanel(HeroService heroService);
}
