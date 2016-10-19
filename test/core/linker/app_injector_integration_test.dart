@TestOn('browser')
library angular2.test.core.linker.app_injector_integration_test;

import "package:angular2/core.dart"
    show
        Injector,
        provide,
        Injectable,
        Provider,
        Inject,
        Self,
        Optional,
        InjectorModule,
        ComponentResolver,
        Provides;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show stringify;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

class Engine {}

class BrokenEngine {
  BrokenEngine() {
    throw new BaseException("Broken Engine");
  }
}

class DashboardSoftware {}

@Injectable()
class Dashboard {
  Dashboard(DashboardSoftware software);
}

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

@InjectorModule()
class SomeModule {}

@InjectorModule(providers: const [SomeService])
class SomeModuleWithProviders {}

@InjectorModule()
class SomeModuleWithProp {
  @Provides(Engine)
  String a = "aValue";
  @Provides("multiProp", multi: true)
  var multiProp = "aMultiValue";
}

@InjectorModule(providers: const [Car])
class SomeChildModuleWithProvider {}

@InjectorModule()
class SomeChildModuleWithDeps {
  SomeService someService;
  SomeChildModuleWithDeps(this.someService);
}

@InjectorModule()
class SomeChildModuleWithProp {
  @Provides(Engine)
  String a = "aChildValue";
}

@InjectorModule()
class SomeModuleWithUnknownArgs {
  SomeModuleWithUnknownArgs(a, b, c);
}

void main() {
  group("generated injector integration tests", () {
    ComponentResolver compiler;
    setUp(() async {
      await inject([ComponentResolver], (_compiler) {
        compiler = _compiler;
      });
    });
    Injector createInjector(List<dynamic> providers, [Injector parent = null]) {
      return compiler
          .createInjectorFactory(SomeModule, providers)
          .create(parent);
    }

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
      expect(
          () => createInjector([NoAnnotations]),
          throwsWith("Cannot resolve all parameters for 'NoAnnotations'(?). "
              "Make sure that all the parameters are decorated with Inject or have valid type annotations "
              "and that 'NoAnnotations' is decorated with Injectable."));
    });
    test("should throw when no type and not @Inject (factory case)", () {
      var funcRegExp = "'\.*factoryFn\.*'";
      expect(
          () => createInjector([provide("someToken", useFactory: factoryFn)]),
          throwsWith(new RegExp("Cannot resolve all parameters for $funcRegExp"
              r"\(\?\)\. "
              "Make sure that all the parameters are decorated with Inject or "
              "have valid type annotations and that $funcRegExp is decorated "
              r"with Injectable\.")));
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
        provide(Car, useClass: SportsCar, multi: true),
        provide(Car, useClass: CarWithOptionalEngine, multi: true)
      ]);
      var cars = injector.get(Car);
      expect(cars.length, 2);
      expect(cars[0], new isInstanceOf<SportsCar>());
      expect(cars[1], new isInstanceOf<CarWithOptionalEngine>());
    });
    test("should support multiProviders that are created using useExisting",
        () {
      var injector = createInjector([
        Engine,
        SportsCar,
        provide(Car, useExisting: SportsCar, multi: true)
      ]);
      var cars = injector.get(Car);
      expect(cars.length, 1);
      expect(cars[0], injector.get(SportsCar));
    });
    test("should throw when the aliased provider does not exist", () {
      var injector = createInjector([provide("car", useExisting: SportsCar)]);
      var e = '''No provider for ${ stringify ( SportsCar )}!''';
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
        "should use the last provider when there are multiple providers for same token",
        () {
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
              "Invalid provider - only instances of Provider and Type are allowed, got: blah"));
    });
    test("should provide itself", () {
      var parent = createInjector([]);
      var child = createInjector([], parent);
      expect(child.get(Injector), child);
    });
    test("should throw when no provider defined", () {
      var injector = createInjector([]);
      expect(() => injector.get("NonExisting"),
          throwsWith("No provider for NonExisting!"));
    });
    test("should throw when trying to instantiate a cyclic dependency", () {
      expect(
          () => createInjector([Car, provide(Engine, useClass: CyclicEngine)]),
          throwsWith(new RegExp(r'Cannot instantiate cyclic dependency! Car')));
    });
    test("should support null values", () {
      var injector = createInjector([provide("null", useValue: null)]);
      expect(injector.get("null"), null);
    });
    group("child", () {
      test("should load instances from parent injector", () {
        var parent = createInjector([Engine]);
        var child = createInjector([], parent);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromChild, engineFromParent);
      });
      test(
          "should not use the child providers when resolving the dependencies of a parent provider",
          () {
        var parent = createInjector([Car, Engine]);
        var child =
            createInjector([provide(Engine, useClass: TurboEngine)], parent);
        var carFromChild = child.get(Car);
        expect(carFromChild.engine, new isInstanceOf<Engine>());
      });
      test("should create new instance in a child injector", () {
        var parent = createInjector([Engine]);
        var child =
            createInjector([provide(Engine, useClass: TurboEngine)], parent);
        var engineFromParent = parent.get(Engine);
        var engineFromChild = child.get(Engine);
        expect(engineFromParent != engineFromChild, isTrue);
        expect(engineFromChild, new isInstanceOf<TurboEngine>());
      });
    });
    group("depedency resolution", () {
      group("@Self()", () {
        test("should return a dependency from self", () {
          var inj = createInjector([
            Engine,
            provide(Car, useFactory: (e) => new Car(e), deps: [
              [Engine, new Self()]
            ])
          ]);
          expect(inj.get(Car), new isInstanceOf<Car>());
        });
        test("should throw when not requested provider on self", () {
          expect(
              () => createInjector([
                    provide(Car, useFactory: (e) => new Car(e), deps: [
                      [Engine, new Self()]
                    ])
                  ]),
              throwsWith(new RegExp(r'No provider for Engine')));
        });
      });
      group("default", () {
        test("should not skip self", () {
          var parent = createInjector([Engine]);
          var child = createInjector([
            provide(Engine, useClass: TurboEngine),
            provide(Car, useFactory: (e) => new Car(e), deps: [Engine])
          ], parent);
          expect(child.get(Car).engine, new isInstanceOf<TurboEngine>());
        });
      });
    });
    group("modules", () {
      test("should use the providers of the module", () {
        var factory = compiler.createInjectorFactory(SomeModuleWithProviders);
        var injector = factory.create();
        expect(injector.get(SomeService), new isInstanceOf<SomeService>());
      });
      test("should provide the main module", () {
        var factory = compiler.createInjectorFactory(SomeModule);
        var someModule = new SomeModule();
        var injector = factory.create(null, someModule);
        expect(injector.get(SomeModule), someModule);
      });
      test("should throw when asking for the main module and it was not given",
          () {
        var factory = compiler.createInjectorFactory(SomeModule);
        var injector = factory.create();
        expect(() => injector.get(SomeModule),
            throwsWith('No provider for ${ stringify ( SomeModule )}!'));
      });
      test("should use the providers of child modules (types)", () {
        var injector = createInjector([SomeChildModuleWithProvider, Engine]);
        expect(injector.get(SomeChildModuleWithProvider),
            new isInstanceOf<SomeChildModuleWithProvider>());
        expect(injector.get(Car), new isInstanceOf<Car>());
      });
      test("should use the providers of child modules (providers)", () {
        var injector = createInjector([
          provide(SomeChildModuleWithProvider,
              useClass: SomeChildModuleWithProvider),
          Engine
        ]);
        expect(injector.get(SomeChildModuleWithProvider),
            new isInstanceOf<SomeChildModuleWithProvider>());
        expect(injector.get(Car), new isInstanceOf<Car>());
      });
      test("should inject deps into child modules", () {
        var injector = createInjector([SomeChildModuleWithDeps, SomeService]);
        expect(injector.get(SomeChildModuleWithDeps).someService,
            new isInstanceOf<SomeService>());
      });
      test(
          "should support modules whose constructor arguments cannot be injected",
          () {
        var factory = compiler.createInjectorFactory(SomeModuleWithUnknownArgs);
        expect(factory.create().get(Injector), isNotNull);
        factory = compiler.createInjectorFactory(SomeModule, [
          new Provider(SomeModuleWithUnknownArgs,
              useValue: new SomeModuleWithUnknownArgs(1, 2, 3))
        ]);
        expect(factory.create().get(Injector), isNotNull);
      });
    });
    group("provider properties", () {
      Injector createInjector(Type mainModuleType, List<dynamic> providers,
          [mainModule = null]) {
        return compiler
            .createInjectorFactory(mainModuleType, providers)
            .create(null, mainModule);
      }

      test("should support multi providers", () {
        var inj = createInjector(
            SomeModuleWithProp,
            [new Provider("multiProp", useValue: "bMultiValue", multi: true)],
            new SomeModuleWithProp());
        expect(inj.get("multiProp"), ["aMultiValue", "bMultiValue"]);
      });
      group("properties on initial module", () {
        test("should support provider properties", () {
          var inj =
              createInjector(SomeModuleWithProp, [], new SomeModuleWithProp());
          expect(inj.get(Engine), "aValue");
        });
        test(
            "should throw if the module is missing when the injector is created",
            () {
          expect(() => createInjector(SomeModuleWithProp, []),
              throwsWith("This injector needs a main module instance!"));
        });
      });
      group("properties on child modules", () {
        test("should support provider properties", () {
          var inj = createInjector(SomeModule, [SomeChildModuleWithProp]);
          expect(inj.get(Engine), "aChildValue");
        });
        test("should throw if the module is missing when the value is read",
            () {
          var inj = createInjector(SomeModule, [
            new Provider(Engine,
                useProperty: "a", useExisting: SomeChildModuleWithProp)
          ]);
          expect(
              () => inj.get(Engine),
              throwsWith(
                  'No provider for ${ stringify ( SomeChildModuleWithProp )}!'));
        });
      });
    });
  });
}
