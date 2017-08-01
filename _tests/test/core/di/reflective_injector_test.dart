@Tags(const ['codegen'])
@TestOn('browser')
import 'package:test/test.dart';
import 'package:_tests/internal.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/di.dart';
import 'package:angular/src/core/di/reflective_injector.dart'
    show
    ReflectiveInjectorImpl,
    ReflectiveInjectorInlineStrategy,
    ReflectiveInjectorDynamicStrategy,
    ReflectiveProtoInjector;
import 'package:angular/src/core/di/reflective_provider.dart'
    show ResolvedReflectiveProviderImpl;
import 'package:angular/src/facade/exceptions.dart' show BaseException;

@Injectable()
class Engine {}

@Injectable()
class BrokenEngine {
  BrokenEngine() {
    throw new BaseException("Broken Engine");
  }
}

@Injectable()
class DashboardSoftware {}

@Injectable()
class Dashboard {
  Dashboard(DashboardSoftware software);
}

@Injectable()
class TurboEngine extends Engine {}

@Injectable()
class Car {
  Engine engine;

  Car(Engine engine) {
    this.engine = engine;
  }
}

@Injectable()
class CarWithOptionalEngine {
  var engine;

  CarWithOptionalEngine(@Optional() Engine engine) {
    this.engine = engine;
  }
}

@Injectable()
class CarWithDashboard {
  Engine engine;
  Dashboard dashboard;

  CarWithDashboard(Engine engine, Dashboard dashboard) {
    this.engine = engine;
    this.dashboard = dashboard;
  }
}

@Injectable()
class SportsCar extends Car {
  SportsCar(Engine engine) : super(engine);
}

@Injectable()
class CarWithInject {
  Engine engine;

  CarWithInject(@Inject(TurboEngine) Engine engine) {
    this.engine = engine;
  }
}

@Injectable()
class CyclicEngine {
  CyclicEngine(Car car);
}

class NoAnnotations {
  NoAnnotations(secretDependency);
}

factoryFn(a) {}

@Injectable()
class SomeService {}

void main() {
  var dynamicProviders = [
    provide("provider0", useValue: 1),
    provide("provider1", useValue: 1),
    provide("provider2", useValue: 1),
    provide("provider3", useValue: 1),
    provide("provider4", useValue: 1),
    provide("provider5", useValue: 1),
    provide("provider6", useValue: 1),
    provide("provider7", useValue: 1),
    provide("provider8", useValue: 1),
    provide("provider9", useValue: 1),
    provide("provider10", useValue: 1)
  ];
  group('injector inline strategy', () {
    Map context;
    var createInjector;
    setUp(() async {
      context = {
        "strategy": "inline",
        "providers": [],
        "strategyClass": ReflectiveInjectorInlineStrategy
      };
      await inject([], () {
        createInjector =
            (List<dynamic> providers, [ReflectiveInjector parent = null]) {
          var resolvedProviders = ReflectiveInjector.resolve(
              (new List.from(providers)..addAll(context["providers"])));
          if (parent != null) {
            return (parent.createChildFromResolved(resolvedProviders)
            as ReflectiveInjectorImpl);
          } else {
            return (ReflectiveInjector.fromResolvedProviders(resolvedProviders)
            as ReflectiveInjectorImpl);
          }
        };
      });
    });

    test("should use the right strategy", () {
      ReflectiveInjectorImpl injector = createInjector([]);
      expect(injector.internalStrategy.runtimeType,
          ReflectiveInjectorInlineStrategy);
    });

    test("should instantiate a class without dependencies", () {
      var injector = createInjector([Engine]);
      var engine = injector.get(Engine);
      expect(engine, new isInstanceOf<Engine>());
    });
    test("should resolve dependencies based on type information", () {
      var injector = createInjector([Engine, Car]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<Car>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should resolve dependencies based on @Inject annotation", () {
      var injector = createInjector([TurboEngine, Engine, CarWithInject]);
      var car = injector.get(CarWithInject);
      expect(car, new isInstanceOf<CarWithInject>());
      expect(car.engine, new isInstanceOf<TurboEngine>());
    });
    test("should throw when no type and not @Inject (class case)", () {
      expect(() => createInjector([NoAnnotations]), throwsStateError);
    });
    test("should throw when no type and not @Inject (factory case)", () {
      expect(
              () =>
              createInjector([provide("someToken", useFactory: factoryFn)]),
          throwsStateError);
    });
    test("should cache instances", () {
      var injector = createInjector([Engine]);
      var e1 = injector.get(Engine);
      var e2 = injector.get(Engine);
      expect(e1, e2);
    });
    test("should provide to a value", () {
      var injector = createInjector([provide(Engine, useValue: "fake engine")]);
      var engine = injector.get(Engine);
      expect(engine, "fake engine");
    });
    test("should provide to a factory", () {
      SportsCar sportsCarFactory(e) {
        return new SportsCar(e);
      }

      var injector = createInjector([
        Engine,
        provide(Car, useFactory: sportsCarFactory, deps: [Engine])
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should throw when using a factory with more than 20 dependencies",
            () {
          Car factoryWithTooManyArgs() {
            return new Car(null);
          }

          var injector = createInjector([
            Engine,
            provide(Car, useFactory: factoryWithTooManyArgs, deps: [
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine
            ])
          ]);
          try {
            injector.get(Car);
            throw new Exception("Must throw");
          } catch (e) {
            expect(
                e.message,
                contains('Cannot instantiate \'Car\' because '
                    'it has more than 20 dependencies'));
          }
        });
    test("should supporting provider to null", () {
      var injector = createInjector([provide(Engine, useValue: null)]);
      var engine = injector.get(Engine);
      expect(engine, isNull);
    });
    test("should provide to an alias", () {
      var injector = createInjector([
        Engine,
        provide(SportsCar, useClass: SportsCar),
        provide(Car, useExisting: SportsCar)
      ]);
      var car = injector.get(Car);
      var sportsCar = injector.get(SportsCar);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car, sportsCar);
    });
    test("should support multiProviders", () {
      var injector = createInjector([
        Engine,
        new Provider(Car, useClass: SportsCar, multi: true),
        new Provider(Car, useClass: CarWithOptionalEngine, multi: true)
      ]);
      var cars = injector.get(Car);
      expect(cars, hasLength(2));
      expect(cars[0], new isInstanceOf<SportsCar>());
      expect(cars[1], new isInstanceOf<CarWithOptionalEngine>());
    });
    test("should support multiProviders that are created using useExisting",
            () {
          var injector = createInjector([
            Engine,
            SportsCar,
            new Provider(Car, useExisting: SportsCar, multi: true)
          ]);
          var cars = injector.get(Car);
          expect(cars.length, 1);
          expect(cars[0], injector.get(SportsCar));
        });
    test("should throw when the aliased provider does not exist", () {
      var injector = createInjector([provide("car", useExisting: SportsCar)]);
      var e = 'No provider for $SportsCar'
          '! (car -> $SportsCar)';
      expect(() => injector.get("car"), throwsWith(e));
    });
    test("should handle forwardRef in useExisting", () {
      var injector = createInjector([
        provide("originalEngine", useClass: Engine),
        provide("aliasedEngine", useExisting: ("originalEngine" as dynamic))
      ]);
      expect(injector.get("aliasedEngine"), new isInstanceOf<Engine>());
    });
    test("should support overriding factory dependencies", () {
      var injector = createInjector([
        Engine,
        provide(Car, useFactory: (e) => new SportsCar(e), deps: [Engine])
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should support optional dependencies", () {
      var injector = createInjector([CarWithOptionalEngine]);
      var car = injector.get(CarWithOptionalEngine);
      expect(car.engine, null);
    });
    test("should flatten passed-in providers", () {
      var injector = createInjector([
        [
          [Engine, Car]
        ]
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<Car>());
    });
    test(
        'should use the last provider when there '
            'are multiple providers for same token', () {
      var injector = createInjector([
        provide(Engine, useClass: Engine),
        provide(Engine, useClass: TurboEngine)
      ]);
      expect(injector.get(Engine), new isInstanceOf<TurboEngine>());
    });
    test("should use non-type tokens", () {
      var injector = createInjector([provide("token", useValue: "value")]);
      expect(injector.get("token"), "value");
    });
    test("should throw when given invalid providers", () {
      expect(
              () => createInjector((["blah"])),
          throwsWith(
              'Invalid provider (blah): only instances of Provider and Type are allowed, got String'));
    });
    test("should provide itself", () {
      var parent = createInjector([]);
      var child = parent.resolveAndCreateChild([]);
      expect(child.get(Injector), child);
    });
    test("should throw when no provider defined", () {
      var injector = createInjector([]);
      expect(() => injector.get("NonExisting"),
          throwsWith("No provider for NonExisting!"));
    });
    test("should show the full path when no provider", () {
      var injector = createInjector([CarWithDashboard, Engine, Dashboard]);
      expect(
              () => injector.get(CarWithDashboard),
          throwsWith('No provider for DashboardSoftware! '
              '($CarWithDashboard '
              '-> $Dashboard -> DashboardSoftware)'));
    });
    test("should throw when trying to instantiate a cyclic dependency", () {
      var injector =
      createInjector([Car, provide(Engine, useClass: CyclicEngine)]);
      expect(
              () => injector.get(Car),
          throwsWith('Cannot instantiate cyclic dependency! ($Car '
              '-> $Engine -> $Car)'));
    });
    test("should show the full path when error happens in a constructor", () {
      var providers = ReflectiveInjector
          .resolve([Car, provide(Engine, useClass: BrokenEngine)]);
      var proto = new ReflectiveProtoInjector([providers[0], providers[1]]);
      var injector = new ReflectiveInjectorImpl(proto);
      try {
        injector.get(Car);
        throw "Must throw";
      } catch (e) {
        expect(
            e.message,
            contains('Error during instantiation of Engine!'
                ' ($Car -> Engine)'));
        expect(e.originalException is BaseException, true);
        expect(e.causeKey.token, Engine);
      }
    });
    test("should provide context when throwing an exception ", () {
      var engineProvider = ReflectiveInjector
          .resolve([provide(Engine, useClass: BrokenEngine)])[0];
      var protoParent = new ReflectiveProtoInjector([engineProvider]);
      var carProvider = ReflectiveInjector.resolve([Car])[0];
      var protoChild = new ReflectiveProtoInjector([carProvider]);
      var parent =
      new ReflectiveInjectorImpl(protoParent, null, () => "parentContext");
      var child =
      new ReflectiveInjectorImpl(protoChild, parent, () => "childContext");
      try {
        child.get(Car);
        throw "Must throw";
      } catch (e) {
        expect(e.context, "childContext");
      }
    });
    test("should instantiate an object after a failed attempt", () {
      var isBroken = true;
      var injector = createInjector([
        Car,
        provide(Engine,
            useFactory: (() => isBroken ? new BrokenEngine() : new Engine()),
            deps: const [])
      ]);
      expect(() => injector.get(Car), throwsWith("Error"));
      isBroken = false;
      expect(injector.get(Car), new isInstanceOf<Car>());
    });
    test("should support null values", () {
      var injector = createInjector([provide("null", useValue: null)]);
      expect(injector.get("null"), isNull);
    });

    group("child", () {
      test("should load instances from parent injector", () {
        var parent = ReflectiveInjector.resolveAndCreate([Engine]);
        var child = parent.resolveAndCreateChild([]);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromChild, engineFromParent);
      });
      test(
          'should not use the child providers when '
              'resolving the dependencies of a parent provider', () {
        var parent = ReflectiveInjector.resolveAndCreate([Car, Engine]);
        var child = parent
            .resolveAndCreateChild([provide(Engine, useClass: TurboEngine)]);
        var carFromChild = child.get(Car);
        expect(carFromChild.engine, new isInstanceOf<Engine>());
      });
      test("should create new instance in a child injector", () {
        var parent = ReflectiveInjector.resolveAndCreate([Engine]);
        var child = parent
            .resolveAndCreateChild([provide(Engine, useClass: TurboEngine)]);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromParent != engineFromChild, true);
        expect(engineFromChild, new isInstanceOf<TurboEngine>());
      });
      test("should give access to parent", () {
        var parent = ReflectiveInjector.resolveAndCreate([]);
        var child = parent.resolveAndCreateChild([]);
        expect(child.parent, parent);
      });
    });
    group("resolveAndInstantiate", () {
      test("should instantiate an object in the context of the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        var car = inj.resolveAndInstantiate(Car);
        expect(car, new isInstanceOf<Car>());
        expect(car.engine, inj.get(Engine));
      });
      test("should not store the instantiated object in the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        inj.resolveAndInstantiate(Car);
        expect(() => inj.get(Car), throwsWith("No provider for Car!"));
      });
    });
    group("instantiate", () {
      test("should instantiate an object in the context of the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        var car = inj.instantiateResolved(ReflectiveInjector.resolve([Car])[0]);
        expect(car, new isInstanceOf<Car>());
        expect(car.engine, inj.get(Engine));
      });
    });
    group("depedency resolution", () {
      group("@Self()", () {
        test("should return a dependency from self", () {
          var inj = ReflectiveInjector.resolveAndCreate([
            Engine,
            provide(Car, useFactory: (e) => new Car(e), deps: [
              [Engine, new Self()]
            ])
          ]);
          expect(inj.get(Car), new isInstanceOf<Car>());
        });
        test("should throw when not requested provider on self", () {
          var parent = ReflectiveInjector.resolveAndCreate([Engine]);
          var child = parent.resolveAndCreateChild([
            provide(Car, useFactory: (e) => new Car(e), deps: [
              [Engine, new Self()]
            ])
          ]);
          expect(
                  () => child.get(Car),
              throwsWith('No provider for Engine! ($Car '
                  '-> $Engine)'));
        });
      });
      group("default", () {
        test("should not skip self", () {
          var parent = ReflectiveInjector.resolveAndCreate([Engine]);
          var child = parent.resolveAndCreateChild([
            provide(Engine, useClass: TurboEngine),
            provide(Car, useFactory: (e) => new Car(e), deps: [Engine])
          ]);
          expect(child.get(Car).engine, new isInstanceOf<TurboEngine>());
        });
      });
    });
    group("resolve", () {
      test(
          "should reject providers that do not resolve to a type either via the token",
              () {
            try {
              ReflectiveInjector.resolve([provide('not a type')]);
              fail('Expected resolution to fail');
            } catch (e) {
              expect((e as InvalidProviderError).message,
                  'Invalid provider (not a type): token is not a Type and no factory was specified');
            }
          });
      test("should default to token type", () {
        var obj =
        ReflectiveInjector.resolveAndCreate([provide(Engine)]).get(Engine);
        expect(obj.runtimeType == Engine, true);
      });
      test("should resolve and flatten", () {
        var providers = ReflectiveInjector.resolve([
          Engine,
          [BrokenEngine]
        ]);
        providers.forEach((b) {
          if (b == null) return;
          expect(b is ResolvedReflectiveProviderImpl, true);
        });
      });
      test("should support multi providers", () {
        var provider = ReflectiveInjector.resolve([
          new Provider(Engine, useClass: BrokenEngine, multi: true),
          new Provider(Engine, useClass: TurboEngine, multi: true)
        ])[0];
        expect(provider.key.token, Engine);
        expect(provider.multiProvider, true);
        expect(provider.resolvedFactories.length, 2);
      });
      test("should support multi providers with only one provider", () {
        var provider = ReflectiveInjector.resolve(
            [new Provider(Engine, useClass: BrokenEngine, multi: true)])[0];
        expect(provider.key.token, Engine);
        expect(provider.multiProvider, true);
        expect(provider.resolvedFactories.length, 1);
      });
      test("should throw when mixing multi providers with regular providers",
              () {
            expect(() {
              ReflectiveInjector.resolve([
                new Provider(Engine, useClass: BrokenEngine, multi: true),
                Engine
              ]);
            }, throwsWith("Cannot mix multi providers and regular providers"));
            expect(() {
              ReflectiveInjector.resolve([
                Engine,
                new Provider(Engine, useClass: BrokenEngine, multi: true)
              ]);
            }, throwsWith("Cannot mix multi providers and regular providers"));
          });
      test("should resolve forward references", () {
        var providers = ReflectiveInjector.resolve([
          Engine,
          [provide(BrokenEngine, useClass: Engine)],
          provide(String, useFactory: () => "OK", deps: [Engine])
        ]);
        var engineProvider = providers[0];
        var brokenEngineProvider = providers[1];
        var stringProvider = providers[2];
        expect(engineProvider.resolvedFactories[0].factory() is Engine, true);
        expect(brokenEngineProvider.resolvedFactories[0].factory() is Engine,
            true);
        expect(stringProvider.resolvedFactories[0].dependencies[0].key,
            ReflectiveKey.get(Engine));
      });
      test("should allow declaring dependencies with flat arrays", () {
        var resolved = ReflectiveInjector.resolve([
          provide("token", useFactory: (e) => e, deps: [new Inject("dep")])
        ]);
        var nestedResolved = ReflectiveInjector.resolve([
          provide("token", useFactory: (e) => e, deps: [
            [new Inject("dep")]
          ])
        ]);
        expect(resolved[0].resolvedFactories[0].dependencies[0].key.token,
            nestedResolved[0].resolvedFactories[0].dependencies[0].key.token);
      });
    });
    group("displayName", () {
      test("should work", () {
        expect(
            ((ReflectiveInjector.resolveAndCreate([Engine, BrokenEngine])
            as ReflectiveInjectorImpl))
                .displayName,
            'ReflectiveInjector(providers: [ "Engine" ,  "BrokenEngine" ])');
      });
    });
  });
  group('injector dynamic strategy', () {
    Map context;
    var createInjector;
    setUp(() {
      context = {
        "strategy": "dynamic",
        "providers": dynamicProviders,
        "strategyClass": ReflectiveInjectorDynamicStrategy
      };
      createInjector =
          (List<dynamic> providers, [ReflectiveInjector parent = null]) {
        var resolvedProviders = ReflectiveInjector
            .resolve((new List.from(providers)..addAll(context["providers"])));
        if (parent != null) {
          return (parent.createChildFromResolved(resolvedProviders)
          as ReflectiveInjectorImpl);
        } else {
          return (ReflectiveInjector.fromResolvedProviders(resolvedProviders)
          as ReflectiveInjectorImpl);
        }
      };
    });

    test("should use the right strategy", () {
      ReflectiveInjectorImpl injector = createInjector([]);
      expect(injector.internalStrategy.runtimeType,
          ReflectiveInjectorDynamicStrategy);
    });

    test("should instantiate a class without dependencies", () {
      var injector = createInjector([Engine]);
      var engine = injector.get(Engine);
      expect(engine, new isInstanceOf<Engine>());
    });
    test("should resolve dependencies based on type information", () {
      var injector = createInjector([Engine, Car]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<Car>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should resolve dependencies based on @Inject annotation", () {
      var injector = createInjector([TurboEngine, Engine, CarWithInject]);
      var car = injector.get(CarWithInject);
      expect(car, new isInstanceOf<CarWithInject>());
      expect(car.engine, new isInstanceOf<TurboEngine>());
    });
    test("should throw when no type and not @Inject (class case)", () {
      expect(() => createInjector([NoAnnotations]), throwsStateError);
    });
    test("should throw when no type and not @Inject (factory case)", () {
      expect(
              () =>
              createInjector([provide("someToken", useFactory: factoryFn)]),
          throwsStateError);
    });
    test("should cache instances", () {
      var injector = createInjector([Engine]);
      var e1 = injector.get(Engine);
      var e2 = injector.get(Engine);
      expect(e1, e2);
    });
    test("should provide to a value", () {
      var injector = createInjector([provide(Engine, useValue: "fake engine")]);
      var engine = injector.get(Engine);
      expect(engine, "fake engine");
    });
    test("should provide to a factory", () {
      SportsCar sportsCarFactory(e) {
        return new SportsCar(e);
      }

      var injector = createInjector([
        Engine,
        provide(Car, useFactory: sportsCarFactory, deps: [Engine])
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should throw when using a factory with more than 20 dependencies",
            () {
          Car factoryWithTooManyArgs() {
            return new Car(null);
          }

          var injector = createInjector([
            Engine,
            provide(Car, useFactory: factoryWithTooManyArgs, deps: [
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine,
              Engine
            ])
          ]);
          try {
            injector.get(Car);
            throw new Exception("Must throw");
          } catch (e) {
            expect(
                e.message,
                contains('Cannot instantiate \'Car\' because '
                    'it has more than 20 dependencies'));
          }
        });
    test("should supporting provider to null", () {
      var injector = createInjector([provide(Engine, useValue: null)]);
      var engine = injector.get(Engine);
      expect(engine, isNull);
    });
    test("should provide to an alias", () {
      var injector = createInjector([
        Engine,
        provide(SportsCar, useClass: SportsCar),
        provide(Car, useExisting: SportsCar)
      ]);
      var car = injector.get(Car);
      var sportsCar = injector.get(SportsCar);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car, sportsCar);
    });
    test("should support multiProviders", () {
      var injector = createInjector([
        Engine,
        new Provider(Car, useClass: SportsCar, multi: true),
        new Provider(Car, useClass: CarWithOptionalEngine, multi: true)
      ]);
      var cars = injector.get(Car);
      expect(cars, hasLength(2));
      expect(cars[0], new isInstanceOf<SportsCar>());
      expect(cars[1], new isInstanceOf<CarWithOptionalEngine>());
    });
    test("should support multiProviders that are created using useExisting",
            () {
          var injector = createInjector([
            Engine,
            SportsCar,
            new Provider(Car, useExisting: SportsCar, multi: true)
          ]);
          var cars = injector.get(Car);
          expect(cars.length, 1);
          expect(cars[0], injector.get(SportsCar));
        });
    test("should throw when the aliased provider does not exist", () {
      var injector = createInjector([provide("car", useExisting: SportsCar)]);
      var e = 'No provider for $SportsCar'
          '! (car -> $SportsCar)';
      expect(() => injector.get("car"), throwsWith(e));
    });
    test("should handle forwardRef in useExisting", () {
      var injector = createInjector([
        provide("originalEngine", useClass: Engine),
        provide("aliasedEngine", useExisting: ("originalEngine" as dynamic))
      ]);
      expect(injector.get("aliasedEngine"), new isInstanceOf<Engine>());
    });
    test("should support overriding factory dependencies", () {
      var injector = createInjector([
        Engine,
        provide(Car, useFactory: (e) => new SportsCar(e), deps: [Engine])
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<SportsCar>());
      expect(car.engine, new isInstanceOf<Engine>());
    });
    test("should support optional dependencies", () {
      var injector = createInjector([CarWithOptionalEngine]);
      var car = injector.get(CarWithOptionalEngine);
      expect(car.engine, null);
    });
    test("should flatten passed-in providers", () {
      var injector = createInjector([
        [
          [Engine, Car]
        ]
      ]);
      var car = injector.get(Car);
      expect(car, new isInstanceOf<Car>());
    });
    test(
        'should use the last provider when there '
            'are multiple providers for same token', () {
      var injector = createInjector([
        provide(Engine, useClass: Engine),
        provide(Engine, useClass: TurboEngine)
      ]);
      expect(injector.get(Engine), new isInstanceOf<TurboEngine>());
    });
    test("should use non-type tokens", () {
      var injector = createInjector([provide("token", useValue: "value")]);
      expect(injector.get("token"), "value");
    });
    test("should throw when given invalid providers", () {
      expect(
              () => createInjector((["blah"])),
          throwsWith(
              'Invalid provider (blah): only instances of Provider and Type are allowed, got String'));
    });
    test("should provide itself", () {
      var parent = createInjector([]);
      var child = parent.resolveAndCreateChild([]);
      expect(child.get(Injector), child);
    });
    test("should throw when no provider defined", () {
      var injector = createInjector([]);
      expect(() => injector.get("NonExisting"),
          throwsWith("No provider for NonExisting!"));
    });
    test("should show the full path when no provider", () {
      var injector = createInjector([CarWithDashboard, Engine, Dashboard]);
      expect(
              () => injector.get(CarWithDashboard),
          throwsWith('No provider for DashboardSoftware! '
              '($CarWithDashboard '
              '-> $Dashboard -> DashboardSoftware)'));
    });
    test("should throw when trying to instantiate a cyclic dependency", () {
      var injector =
      createInjector([Car, provide(Engine, useClass: CyclicEngine)]);
      expect(
              () => injector.get(Car),
          throwsWith('Cannot instantiate cyclic dependency! ($Car '
              '-> $Engine -> $Car)'));
    });
    test("should show the full path when error happens in a constructor", () {
      var providers = ReflectiveInjector
          .resolve([Car, provide(Engine, useClass: BrokenEngine)]);
      var proto = new ReflectiveProtoInjector([providers[0], providers[1]]);
      var injector = new ReflectiveInjectorImpl(proto);
      try {
        injector.get(Car);
        throw "Must throw";
      } catch (e) {
        expect(
            e.message,
            contains('Error during instantiation of Engine!'
                ' ($Car -> Engine)'));
        expect(e.originalException is BaseException, true);
        expect(e.causeKey.token, Engine);
      }
    });
    test("should provide context when throwing an exception ", () {
      var engineProvider = ReflectiveInjector
          .resolve([provide(Engine, useClass: BrokenEngine)])[0];
      var protoParent = new ReflectiveProtoInjector([engineProvider]);
      var carProvider = ReflectiveInjector.resolve([Car])[0];
      var protoChild = new ReflectiveProtoInjector([carProvider]);
      var parent =
      new ReflectiveInjectorImpl(protoParent, null, () => "parentContext");
      var child =
      new ReflectiveInjectorImpl(protoChild, parent, () => "childContext");
      try {
        child.get(Car);
        throw "Must throw";
      } catch (e) {
        expect(e.context, "childContext");
      }
    });
    test("should instantiate an object after a failed attempt", () {
      var isBroken = true;
      var injector = createInjector([
        Car,
        provide(Engine,
            useFactory: (() => isBroken ? new BrokenEngine() : new Engine()),
            deps: const [])
      ]);
      expect(() => injector.get(Car), throwsWith("Error"));
      isBroken = false;
      expect(injector.get(Car), new isInstanceOf<Car>());
    });
    test("should support null values", () {
      var injector = createInjector([provide("null", useValue: null)]);
      expect(injector.get("null"), isNull);
    });

    group("child", () {
      test("should load instances from parent injector", () {
        var parent = ReflectiveInjector.resolveAndCreate([Engine]);
        var child = parent.resolveAndCreateChild([]);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromChild, engineFromParent);
      });
      test(
          'should not use the child providers when '
              'resolving the dependencies of a parent provider', () {
        var parent = ReflectiveInjector.resolveAndCreate([Car, Engine]);
        var child = parent
            .resolveAndCreateChild([provide(Engine, useClass: TurboEngine)]);
        var carFromChild = child.get(Car);
        expect(carFromChild.engine, new isInstanceOf<Engine>());
      });
      test("should create new instance in a child injector", () {
        var parent = ReflectiveInjector.resolveAndCreate([Engine]);
        var child = parent
            .resolveAndCreateChild([provide(Engine, useClass: TurboEngine)]);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromParent != engineFromChild, true);
        expect(engineFromChild, new isInstanceOf<TurboEngine>());
      });
      test("should give access to parent", () {
        var parent = ReflectiveInjector.resolveAndCreate([]);
        var child = parent.resolveAndCreateChild([]);
        expect(child.parent, parent);
      });
    });
    group("resolveAndInstantiate", () {
      test("should instantiate an object in the context of the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        var car = inj.resolveAndInstantiate(Car);
        expect(car, new isInstanceOf<Car>());
        expect(car.engine, inj.get(Engine));
      });
      test("should not store the instantiated object in the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        inj.resolveAndInstantiate(Car);
        expect(() => inj.get(Car), throwsWith("No provider for Car!"));
      });
    });
    group("instantiate", () {
      test("should instantiate an object in the context of the injector", () {
        var inj = ReflectiveInjector.resolveAndCreate([Engine]);
        var car = inj.instantiateResolved(ReflectiveInjector.resolve([Car])[0]);
        expect(car, new isInstanceOf<Car>());
        expect(car.engine, inj.get(Engine));
      });
    });
    group("depedency resolution", () {
      group("@Self()", () {
        test("should return a dependency from self", () {
          var inj = ReflectiveInjector.resolveAndCreate([
            Engine,
            provide(Car, useFactory: (e) => new Car(e), deps: [
              [Engine, new Self()]
            ])
          ]);
          expect(inj.get(Car), new isInstanceOf<Car>());
        });
        test("should throw when not requested provider on self", () {
          var parent = ReflectiveInjector.resolveAndCreate([Engine]);
          var child = parent.resolveAndCreateChild([
            provide(Car, useFactory: (e) => new Car(e), deps: [
              [Engine, new Self()]
            ])
          ]);
          expect(
                  () => child.get(Car),
              throwsWith('No provider for Engine! ($Car '
                  '-> $Engine)'));
        });
      });
      group("default", () {
        test("should not skip self", () {
          var parent = ReflectiveInjector.resolveAndCreate([Engine]);
          var child = parent.resolveAndCreateChild([
            provide(Engine, useClass: TurboEngine),
            provide(Car, useFactory: (e) => new Car(e), deps: [Engine])
          ]);
          expect(child.get(Car).engine, new isInstanceOf<TurboEngine>());
        });
      });
    });
    group("resolve", () {
      test("should resolve and flatten", () {
        var providers = ReflectiveInjector.resolve([
          Engine,
          [BrokenEngine]
        ]);
        providers.forEach((b) {
          if (b == null) return;
          expect(b is ResolvedReflectiveProviderImpl, true);
        });
      });
      test("should support multi providers", () {
        var provider = ReflectiveInjector.resolve([
          new Provider(Engine, useClass: BrokenEngine, multi: true),
          new Provider(Engine, useClass: TurboEngine, multi: true)
        ])[0];
        expect(provider.key.token, Engine);
        expect(provider.multiProvider, true);
        expect(provider.resolvedFactories.length, 2);
      });
      test("should support multi providers with only one provider", () {
        var provider = ReflectiveInjector.resolve(
            [new Provider(Engine, useClass: BrokenEngine, multi: true)])[0];
        expect(provider.key.token, Engine);
        expect(provider.multiProvider, true);
        expect(provider.resolvedFactories.length, 1);
      });
      test("should throw when mixing multi providers with regular providers",
              () {
            expect(() {
              ReflectiveInjector.resolve([
                new Provider(Engine, useClass: BrokenEngine, multi: true),
                Engine
              ]);
            }, throwsWith("Cannot mix multi providers and regular providers"));
            expect(() {
              ReflectiveInjector.resolve([
                Engine,
                new Provider(Engine, useClass: BrokenEngine, multi: true)
              ]);
            }, throwsWith("Cannot mix multi providers and regular providers"));
          });
      test("should resolve forward references", () {
        var providers = ReflectiveInjector.resolve([
          Engine,
          [provide(BrokenEngine, useClass: Engine)],
          provide(String, useFactory: () => "OK", deps: [Engine])
        ]);
        var engineProvider = providers[0];
        var brokenEngineProvider = providers[1];
        var stringProvider = providers[2];
        expect(engineProvider.resolvedFactories[0].factory() is Engine, true);
        expect(brokenEngineProvider.resolvedFactories[0].factory() is Engine,
            true);
        expect(stringProvider.resolvedFactories[0].dependencies[0].key,
            ReflectiveKey.get(Engine));
      });
      test("should allow declaring dependencies with flat arrays", () {
        var resolved = ReflectiveInjector.resolve([
          provide("token", useFactory: (e) => e, deps: [new Inject("dep")])
        ]);
        var nestedResolved = ReflectiveInjector.resolve([
          provide("token", useFactory: (e) => e, deps: [
            [new Inject("dep")]
          ])
        ]);
        expect(resolved[0].resolvedFactories[0].dependencies[0].key.token,
            nestedResolved[0].resolvedFactories[0].dependencies[0].key.token);
      });
    });
    group("displayName", () {
      test("should work", () {
        expect(
            ((ReflectiveInjector.resolveAndCreate([Engine, BrokenEngine])
            as ReflectiveInjectorImpl))
                .displayName,
            'ReflectiveInjector(providers: [ "Engine" ,  "BrokenEngine" ])');
      });
    });
  });
}
