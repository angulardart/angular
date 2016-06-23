library angular2.src.core.di.injector;

import "package:angular2/src/facade/collection.dart"
    show Map, MapWrapper, ListWrapper;
import "provider.dart"
    show
        ResolvedProvider,
        Provider,
        Dependency,
        ProviderBuilder,
        ResolvedFactory,
        provide,
        resolveProviders;
import "exceptions.dart"
    show
        AbstractProviderError,
        NoProviderError,
        CyclicDependencyError,
        InstantiationError,
        InvalidProviderError,
        OutOfBoundsError;
import "package:angular2/src/facade/lang.dart" show Type;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, unimplemented;
import "key.dart" show Key;
import "metadata.dart" show SelfMetadata, HostMetadata, SkipSelfMetadata;

Type ___unused;
// Threshold for the dynamic version
const _MAX_CONSTRUCTION_COUNTER = 10;
const Object UNDEFINED = const Object();

abstract class ProtoInjectorStrategy {
  ResolvedProvider getProviderAtIndex(num index);
  InjectorStrategy createInjectorStrategy(Injector_ inj);
}

class ProtoInjectorInlineStrategy implements ProtoInjectorStrategy {
  ResolvedProvider provider0 = null;
  ResolvedProvider provider1 = null;
  ResolvedProvider provider2 = null;
  ResolvedProvider provider3 = null;
  ResolvedProvider provider4 = null;
  ResolvedProvider provider5 = null;
  ResolvedProvider provider6 = null;
  ResolvedProvider provider7 = null;
  ResolvedProvider provider8 = null;
  ResolvedProvider provider9 = null;
  num keyId0 = null;
  num keyId1 = null;
  num keyId2 = null;
  num keyId3 = null;
  num keyId4 = null;
  num keyId5 = null;
  num keyId6 = null;
  num keyId7 = null;
  num keyId8 = null;
  num keyId9 = null;
  ProtoInjectorInlineStrategy(
      ProtoInjector protoEI, List<ResolvedProvider> providers) {
    var length = providers.length;
    if (length > 0) {
      this.provider0 = providers[0];
      this.keyId0 = providers[0].key.id;
    }
    if (length > 1) {
      this.provider1 = providers[1];
      this.keyId1 = providers[1].key.id;
    }
    if (length > 2) {
      this.provider2 = providers[2];
      this.keyId2 = providers[2].key.id;
    }
    if (length > 3) {
      this.provider3 = providers[3];
      this.keyId3 = providers[3].key.id;
    }
    if (length > 4) {
      this.provider4 = providers[4];
      this.keyId4 = providers[4].key.id;
    }
    if (length > 5) {
      this.provider5 = providers[5];
      this.keyId5 = providers[5].key.id;
    }
    if (length > 6) {
      this.provider6 = providers[6];
      this.keyId6 = providers[6].key.id;
    }
    if (length > 7) {
      this.provider7 = providers[7];
      this.keyId7 = providers[7].key.id;
    }
    if (length > 8) {
      this.provider8 = providers[8];
      this.keyId8 = providers[8].key.id;
    }
    if (length > 9) {
      this.provider9 = providers[9];
      this.keyId9 = providers[9].key.id;
    }
  }
  ResolvedProvider getProviderAtIndex(num index) {
    if (index == 0) return this.provider0;
    if (index == 1) return this.provider1;
    if (index == 2) return this.provider2;
    if (index == 3) return this.provider3;
    if (index == 4) return this.provider4;
    if (index == 5) return this.provider5;
    if (index == 6) return this.provider6;
    if (index == 7) return this.provider7;
    if (index == 8) return this.provider8;
    if (index == 9) return this.provider9;
    throw new OutOfBoundsError(index);
  }

  InjectorStrategy createInjectorStrategy(Injector_ injector) {
    return new InjectorInlineStrategy(injector, this);
  }
}

class ProtoInjectorDynamicStrategy implements ProtoInjectorStrategy {
  List<ResolvedProvider> providers;
  List<num> keyIds;
  ProtoInjectorDynamicStrategy(ProtoInjector protoInj, this.providers) {
    var len = providers.length;
    this.keyIds = ListWrapper.createFixedSize(len);
    for (var i = 0; i < len; i++) {
      this.keyIds[i] = providers[i].key.id;
    }
  }
  ResolvedProvider getProviderAtIndex(num index) {
    if (index < 0 || index >= this.providers.length) {
      throw new OutOfBoundsError(index);
    }
    return this.providers[index];
  }

  InjectorStrategy createInjectorStrategy(Injector_ ei) {
    return new InjectorDynamicStrategy(this, ei);
  }
}

class ProtoInjector {
  static ProtoInjector fromResolvedProviders(List<ResolvedProvider> providers) {
    return new ProtoInjector(providers);
  }

  /** @internal */
  ProtoInjectorStrategy _strategy;
  num numberOfProviders;
  ProtoInjector(List<ResolvedProvider> providers) {
    this.numberOfProviders = providers.length;
    this._strategy = providers.length > _MAX_CONSTRUCTION_COUNTER
        ? new ProtoInjectorDynamicStrategy(this, providers)
        : new ProtoInjectorInlineStrategy(this, providers);
  }
  ResolvedProvider getProviderAtIndex(num index) {
    return this._strategy.getProviderAtIndex(index);
  }
}

abstract class InjectorStrategy {
  dynamic getObjByKeyId(num keyId);
  dynamic getObjAtIndex(num index);
  num getMaxNumberOfObjects();
  void resetConstructionCounter();
  dynamic instantiateProvider(ResolvedProvider provider);
}

class InjectorInlineStrategy implements InjectorStrategy {
  Injector_ injector;
  ProtoInjectorInlineStrategy protoStrategy;
  dynamic obj0 = UNDEFINED;
  dynamic obj1 = UNDEFINED;
  dynamic obj2 = UNDEFINED;
  dynamic obj3 = UNDEFINED;
  dynamic obj4 = UNDEFINED;
  dynamic obj5 = UNDEFINED;
  dynamic obj6 = UNDEFINED;
  dynamic obj7 = UNDEFINED;
  dynamic obj8 = UNDEFINED;
  dynamic obj9 = UNDEFINED;
  InjectorInlineStrategy(this.injector, this.protoStrategy) {}
  void resetConstructionCounter() {
    this.injector._constructionCounter = 0;
  }

  dynamic instantiateProvider(ResolvedProvider provider) {
    return this.injector._new(provider);
  }

  dynamic getObjByKeyId(num keyId) {
    var p = this.protoStrategy;
    var inj = this.injector;
    if (identical(p.keyId0, keyId)) {
      if (identical(this.obj0, UNDEFINED)) {
        this.obj0 = inj._new(p.provider0);
      }
      return this.obj0;
    }
    if (identical(p.keyId1, keyId)) {
      if (identical(this.obj1, UNDEFINED)) {
        this.obj1 = inj._new(p.provider1);
      }
      return this.obj1;
    }
    if (identical(p.keyId2, keyId)) {
      if (identical(this.obj2, UNDEFINED)) {
        this.obj2 = inj._new(p.provider2);
      }
      return this.obj2;
    }
    if (identical(p.keyId3, keyId)) {
      if (identical(this.obj3, UNDEFINED)) {
        this.obj3 = inj._new(p.provider3);
      }
      return this.obj3;
    }
    if (identical(p.keyId4, keyId)) {
      if (identical(this.obj4, UNDEFINED)) {
        this.obj4 = inj._new(p.provider4);
      }
      return this.obj4;
    }
    if (identical(p.keyId5, keyId)) {
      if (identical(this.obj5, UNDEFINED)) {
        this.obj5 = inj._new(p.provider5);
      }
      return this.obj5;
    }
    if (identical(p.keyId6, keyId)) {
      if (identical(this.obj6, UNDEFINED)) {
        this.obj6 = inj._new(p.provider6);
      }
      return this.obj6;
    }
    if (identical(p.keyId7, keyId)) {
      if (identical(this.obj7, UNDEFINED)) {
        this.obj7 = inj._new(p.provider7);
      }
      return this.obj7;
    }
    if (identical(p.keyId8, keyId)) {
      if (identical(this.obj8, UNDEFINED)) {
        this.obj8 = inj._new(p.provider8);
      }
      return this.obj8;
    }
    if (identical(p.keyId9, keyId)) {
      if (identical(this.obj9, UNDEFINED)) {
        this.obj9 = inj._new(p.provider9);
      }
      return this.obj9;
    }
    return UNDEFINED;
  }

  dynamic getObjAtIndex(num index) {
    if (index == 0) return this.obj0;
    if (index == 1) return this.obj1;
    if (index == 2) return this.obj2;
    if (index == 3) return this.obj3;
    if (index == 4) return this.obj4;
    if (index == 5) return this.obj5;
    if (index == 6) return this.obj6;
    if (index == 7) return this.obj7;
    if (index == 8) return this.obj8;
    if (index == 9) return this.obj9;
    throw new OutOfBoundsError(index);
  }

  num getMaxNumberOfObjects() {
    return _MAX_CONSTRUCTION_COUNTER;
  }
}

class InjectorDynamicStrategy implements InjectorStrategy {
  ProtoInjectorDynamicStrategy protoStrategy;
  Injector_ injector;
  List<dynamic> objs;
  InjectorDynamicStrategy(this.protoStrategy, this.injector) {
    this.objs = ListWrapper.createFixedSize(protoStrategy.providers.length);
    ListWrapper.fill(this.objs, UNDEFINED);
  }
  void resetConstructionCounter() {
    this.injector._constructionCounter = 0;
  }

  dynamic instantiateProvider(ResolvedProvider provider) {
    return this.injector._new(provider);
  }

  dynamic getObjByKeyId(num keyId) {
    var p = this.protoStrategy;
    for (var i = 0; i < p.keyIds.length; i++) {
      if (identical(p.keyIds[i], keyId)) {
        if (identical(this.objs[i], UNDEFINED)) {
          this.objs[i] = this.injector._new(p.providers[i]);
        }
        return this.objs[i];
      }
    }
    return UNDEFINED;
  }

  dynamic getObjAtIndex(num index) {
    if (index < 0 || index >= this.objs.length) {
      throw new OutOfBoundsError(index);
    }
    return this.objs[index];
  }

  num getMaxNumberOfObjects() {
    return this.objs.length;
  }
}

/**
 * Used to provide dependencies that cannot be easily expressed as providers.
 */
abstract class DependencyProvider {
  dynamic getDependency(
      Injector injector, ResolvedProvider provider, Dependency dependency);
}

abstract class Injector {
  /**
   * Turns an array of provider definitions into an array of resolved providers.
   *
   * A resolution is a process of flattening multiple nested arrays and converting individual
   * providers into an array of [ResolvedProvider]s.
   *
   * ### Example ([live demo](http://plnkr.co/edit/AiXTHi?p=preview))
   *
   * ```typescript
   * @Injectable()
   * class Engine {
   * }
   *
   * @Injectable()
   * class Car {
   *   constructor(public engine:Engine) {}
   * }
   *
   * var providers = Injector.resolve([Car, [[Engine]]]);
   *
   * expect(providers.length).toEqual(2);
   *
   * expect(providers[0] instanceof ResolvedProvider).toBe(true);
   * expect(providers[0].key.displayName).toBe("Car");
   * expect(providers[0].dependencies.length).toEqual(1);
   * expect(providers[0].factory).toBeDefined();
   *
   * expect(providers[1].key.displayName).toBe("Engine");
   * });
   * ```
   *
   * See [Injector#fromResolvedProviders] for more info.
   */
  static List<ResolvedProvider> resolve(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    return resolveProviders(providers);
  }

  /**
   * Resolves an array of providers and creates an injector from those providers.
   *
   * The passed-in providers can be an array of `Type`, [Provider],
   * or a recursive array of more providers.
   *
   * ### Example ([live demo](http://plnkr.co/edit/ePOccA?p=preview))
   *
   * ```typescript
   * @Injectable()
   * class Engine {
   * }
   *
   * @Injectable()
   * class Car {
   *   constructor(public engine:Engine) {}
   * }
   *
   * var injector = Injector.resolveAndCreate([Car, Engine]);
   * expect(injector.get(Car) instanceof Car).toBe(true);
   * ```
   *
   * This function is slower than the corresponding `fromResolvedProviders`
   * because it needs to resolve the passed-in providers first.
   * See [Injector#resolve] and [Injector#fromResolvedProviders].
   */
  static Injector resolveAndCreate(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    var resolvedProviders = Injector.resolve(providers);
    return Injector.fromResolvedProviders(resolvedProviders);
  }

  /**
   * Creates an injector from previously resolved providers.
   *
   * This API is the recommended way to construct injectors in performance-sensitive parts.
   *
   * ### Example ([live demo](http://plnkr.co/edit/KrSMci?p=preview))
   *
   * ```typescript
   * @Injectable()
   * class Engine {
   * }
   *
   * @Injectable()
   * class Car {
   *   constructor(public engine:Engine) {}
   * }
   *
   * var providers = Injector.resolve([Car, Engine]);
   * var injector = Injector.fromResolvedProviders(providers);
   * expect(injector.get(Car) instanceof Car).toBe(true);
   * ```
   */
  static Injector fromResolvedProviders(List<ResolvedProvider> providers) {
    return new Injector_(ProtoInjector.fromResolvedProviders(providers));
  }

  /**
   * 
   */
  static Injector fromResolvedBindings(List<ResolvedProvider> providers) {
    return Injector.fromResolvedProviders(providers);
  }

  /**
   * Retrieves an instance from the injector based on the provided token.
   * Throws [NoProviderError] if not found.
   *
   * ### Example ([live demo](http://plnkr.co/edit/HeXSHg?p=preview))
   *
   * ```typescript
   * var injector = Injector.resolveAndCreate([
   *   provide("validToken", {useValue: "Value"})
   * ]);
   * expect(injector.get("validToken")).toEqual("Value");
   * expect(() => injector.get("invalidToken")).toThrowError();
   * ```
   *
   * `Injector` returns itself when given `Injector` as a token.
   *
   * ```typescript
   * var injector = Injector.resolveAndCreate([]);
   * expect(injector.get(Injector)).toBe(injector);
   * ```
   */
  dynamic get(dynamic token) {
    return unimplemented();
  }

  /**
   * Retrieves an instance from the injector based on the provided token.
   * Returns null if not found.
   *
   * ### Example ([live demo](http://plnkr.co/edit/tpEbEy?p=preview))
   *
   * ```typescript
   * var injector = Injector.resolveAndCreate([
   *   provide("validToken", {useValue: "Value"})
   * ]);
   * expect(injector.getOptional("validToken")).toEqual("Value");
   * expect(injector.getOptional("invalidToken")).toBe(null);
   * ```
   *
   * `Injector` returns itself when given `Injector` as a token.
   *
   * ```typescript
   * var injector = Injector.resolveAndCreate([]);
   * expect(injector.getOptional(Injector)).toBe(injector);
   * ```
   */
  dynamic getOptional(dynamic token) {
    return unimplemented();
  }

  /**
   * Parent of this injector.
   *
   * <!-- TODO: Add a link to the section of the user guide talking about hierarchical injection.
   * -->
   *
   * ### Example ([live demo](http://plnkr.co/edit/eosMGo?p=preview))
   *
   * ```typescript
   * var parent = Injector.resolveAndCreate([]);
   * var child = parent.resolveAndCreateChild([]);
   * expect(child.parent).toBe(parent);
   * ```
   */
  Injector get parent {
    return unimplemented();
  }

  /**
   * @internal
   */
  dynamic debugContext() {
    return null;
  }

  /**
   * Resolves an array of providers and creates a child injector from those providers.
   *
   * <!-- TODO: Add a link to the section of the user guide talking about hierarchical injection.
   * -->
   *
   * The passed-in providers can be an array of `Type`, [Provider],
   * or a recursive array of more providers.
   *
   * ### Example ([live demo](http://plnkr.co/edit/opB3T4?p=preview))
   *
   * ```typescript
   * class ParentProvider {}
   * class ChildProvider {}
   *
   * var parent = Injector.resolveAndCreate([ParentProvider]);
   * var child = parent.resolveAndCreateChild([ChildProvider]);
   *
   * expect(child.get(ParentProvider) instanceof ParentProvider).toBe(true);
   * expect(child.get(ChildProvider) instanceof ChildProvider).toBe(true);
   * expect(child.get(ParentProvider)).toBe(parent.get(ParentProvider));
   * ```
   *
   * This function is slower than the corresponding `createChildFromResolved`
   * because it needs to resolve the passed-in providers first.
   * See [Injector#resolve] and [Injector#createChildFromResolved].
   */
  Injector resolveAndCreateChild(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    return unimplemented();
  }

  /**
   * Creates a child injector from previously resolved providers.
   *
   * <!-- TODO: Add a link to the section of the user guide talking about hierarchical injection.
   * -->
   *
   * This API is the recommended way to construct injectors in performance-sensitive parts.
   *
   * ### Example ([live demo](http://plnkr.co/edit/VhyfjN?p=preview))
   *
   * ```typescript
   * class ParentProvider {}
   * class ChildProvider {}
   *
   * var parentProviders = Injector.resolve([ParentProvider]);
   * var childProviders = Injector.resolve([ChildProvider]);
   *
   * var parent = Injector.fromResolvedProviders(parentProviders);
   * var child = parent.createChildFromResolved(childProviders);
   *
   * expect(child.get(ParentProvider) instanceof ParentProvider).toBe(true);
   * expect(child.get(ChildProvider) instanceof ChildProvider).toBe(true);
   * expect(child.get(ParentProvider)).toBe(parent.get(ParentProvider));
   * ```
   */
  Injector createChildFromResolved(List<ResolvedProvider> providers) {
    return unimplemented();
  }

  /**
   * Resolves a provider and instantiates an object in the context of the injector.
   *
   * The created object does not get cached by the injector.
   *
   * ### Example ([live demo](http://plnkr.co/edit/yvVXoB?p=preview))
   *
   * ```typescript
   * @Injectable()
   * class Engine {
   * }
   *
   * @Injectable()
   * class Car {
   *   constructor(public engine:Engine) {}
   * }
   *
   * var injector = Injector.resolveAndCreate([Engine]);
   *
   * var car = injector.resolveAndInstantiate(Car);
   * expect(car.engine).toBe(injector.get(Engine));
   * expect(car).not.toBe(injector.resolveAndInstantiate(Car));
   * ```
   */
  dynamic resolveAndInstantiate(dynamic /* Type | Provider */ provider) {
    return unimplemented();
  }

  /**
   * Instantiates an object using a resolved provider in the context of the injector.
   *
   * The created object does not get cached by the injector.
   *
   * ### Example ([live demo](http://plnkr.co/edit/ptCImQ?p=preview))
   *
   * ```typescript
   * @Injectable()
   * class Engine {
   * }
   *
   * @Injectable()
   * class Car {
   *   constructor(public engine:Engine) {}
   * }
   *
   * var injector = Injector.resolveAndCreate([Engine]);
   * var carProvider = Injector.resolve([Car])[0];
   * var car = injector.instantiateResolved(carProvider);
   * expect(car.engine).toBe(injector.get(Engine));
   * expect(car).not.toBe(injector.instantiateResolved(carProvider));
   * ```
   */
  dynamic instantiateResolved(ResolvedProvider provider) {
    return unimplemented();
  }
}

/**
 * A dependency injection container used for instantiating objects and resolving dependencies.
 *
 * An `Injector` is a replacement for a `new` operator, which can automatically resolve the
 * constructor dependencies.
 *
 * In typical use, application code asks for the dependencies in the constructor and they are
 * resolved by the `Injector`.
 *
 * ### Example ([live demo](http://plnkr.co/edit/jzjec0?p=preview))
 *
 * The following example creates an `Injector` configured to create `Engine` and `Car`.
 *
 * ```typescript
 * @Injectable()
 * class Engine {
 * }
 *
 * @Injectable()
 * class Car {
 *   constructor(public engine:Engine) {}
 * }
 *
 * var injector = Injector.resolveAndCreate([Car, Engine]);
 * var car = injector.get(Car);
 * expect(car instanceof Car).toBe(true);
 * expect(car.engine instanceof Engine).toBe(true);
 * ```
 *
 * Notice, we don't use the `new` operator because we explicitly want to have the `Injector`
 * resolve all of the object's dependencies automatically.
 */
class Injector_ implements Injector {
  Function _debugContext;
  /** @internal */
  InjectorStrategy _strategy;
  /** @internal */
  num _constructionCounter = 0;
  /** @internal */
  dynamic _proto;
  /** @internal */
  Injector _parent;
  /**
   * Private
   */
  Injector_(dynamic _proto,
      [Injector _parent = null, this._debugContext = null]) {
    this._proto = _proto;
    this._parent = _parent;
    this._strategy = _proto._strategy.createInjectorStrategy(this);
  }
  /**
   * @internal
   */
  dynamic debugContext() {
    return this._debugContext();
  }

  dynamic get(dynamic token) {
    return this._getByKey(Key.get(token), null, null, false);
  }

  dynamic getOptional(dynamic token) {
    return this._getByKey(Key.get(token), null, null, true);
  }

  dynamic getAt(num index) {
    return this._strategy.getObjAtIndex(index);
  }

  Injector get parent {
    return this._parent;
  }

  /**
   * @internal
   * Internal. Do not use.
   * We return `any` not to export the InjectorStrategy type.
   */
  dynamic get internalStrategy {
    return this._strategy;
  }

  Injector resolveAndCreateChild(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    var resolvedProviders = Injector.resolve(providers);
    return this.createChildFromResolved(resolvedProviders);
  }

  Injector createChildFromResolved(List<ResolvedProvider> providers) {
    var proto = new ProtoInjector(providers);
    var inj = new Injector_(proto);
    inj._parent = this;
    return inj;
  }

  dynamic resolveAndInstantiate(dynamic /* Type | Provider */ provider) {
    return this.instantiateResolved(Injector.resolve([provider])[0]);
  }

  dynamic instantiateResolved(ResolvedProvider provider) {
    return this._instantiateProvider(provider);
  }

  /** @internal */
  dynamic _new(ResolvedProvider provider) {
    if (this._constructionCounter++ > this._strategy.getMaxNumberOfObjects()) {
      throw new CyclicDependencyError(this, provider.key);
    }
    return this._instantiateProvider(provider);
  }

  dynamic _instantiateProvider(ResolvedProvider provider) {
    if (provider.multiProvider) {
      var res = ListWrapper.createFixedSize(provider.resolvedFactories.length);
      for (var i = 0; i < provider.resolvedFactories.length; ++i) {
        res[i] = this._instantiate(provider, provider.resolvedFactories[i]);
      }
      return res;
    } else {
      return this._instantiate(provider, provider.resolvedFactories[0]);
    }
  }

  dynamic _instantiate(
      ResolvedProvider provider, ResolvedFactory resolvedFactory) {
    var factory = resolvedFactory.factory;
    var deps = resolvedFactory.dependencies;
    var length = deps.length;
    dynamic d0;
    dynamic d1;
    dynamic d2;
    dynamic d3;
    dynamic d4;
    dynamic d5;
    dynamic d6;
    dynamic d7;
    dynamic d8;
    dynamic d9;
    dynamic d10;
    dynamic d11;
    dynamic d12;
    dynamic d13;
    dynamic d14;
    dynamic d15;
    dynamic d16;
    dynamic d17;
    dynamic d18;
    dynamic d19;
    try {
      d0 = length > 0 ? this._getByDependency(provider, deps[0]) : null;
      d1 = length > 1 ? this._getByDependency(provider, deps[1]) : null;
      d2 = length > 2 ? this._getByDependency(provider, deps[2]) : null;
      d3 = length > 3 ? this._getByDependency(provider, deps[3]) : null;
      d4 = length > 4 ? this._getByDependency(provider, deps[4]) : null;
      d5 = length > 5 ? this._getByDependency(provider, deps[5]) : null;
      d6 = length > 6 ? this._getByDependency(provider, deps[6]) : null;
      d7 = length > 7 ? this._getByDependency(provider, deps[7]) : null;
      d8 = length > 8 ? this._getByDependency(provider, deps[8]) : null;
      d9 = length > 9 ? this._getByDependency(provider, deps[9]) : null;
      d10 = length > 10 ? this._getByDependency(provider, deps[10]) : null;
      d11 = length > 11 ? this._getByDependency(provider, deps[11]) : null;
      d12 = length > 12 ? this._getByDependency(provider, deps[12]) : null;
      d13 = length > 13 ? this._getByDependency(provider, deps[13]) : null;
      d14 = length > 14 ? this._getByDependency(provider, deps[14]) : null;
      d15 = length > 15 ? this._getByDependency(provider, deps[15]) : null;
      d16 = length > 16 ? this._getByDependency(provider, deps[16]) : null;
      d17 = length > 17 ? this._getByDependency(provider, deps[17]) : null;
      d18 = length > 18 ? this._getByDependency(provider, deps[18]) : null;
      d19 = length > 19 ? this._getByDependency(provider, deps[19]) : null;
    } catch (e, e_stack) {
      if (e is AbstractProviderError || e is InstantiationError) {
        e.addKey(this, provider.key);
      }
      rethrow;
    }
    var obj;
    try {
      switch (length) {
        case 0:
          obj = factory();
          break;
        case 1:
          obj = factory(d0);
          break;
        case 2:
          obj = factory(d0, d1);
          break;
        case 3:
          obj = factory(d0, d1, d2);
          break;
        case 4:
          obj = factory(d0, d1, d2, d3);
          break;
        case 5:
          obj = factory(d0, d1, d2, d3, d4);
          break;
        case 6:
          obj = factory(d0, d1, d2, d3, d4, d5);
          break;
        case 7:
          obj = factory(d0, d1, d2, d3, d4, d5, d6);
          break;
        case 8:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7);
          break;
        case 9:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8);
          break;
        case 10:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9);
          break;
        case 11:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10);
          break;
        case 12:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11);
          break;
        case 13:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12);
          break;
        case 14:
          obj = factory(
              d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13);
          break;
        case 15:
          obj = factory(
              d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14);
          break;
        case 16:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12,
              d13, d14, d15);
          break;
        case 17:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12,
              d13, d14, d15, d16);
          break;
        case 18:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12,
              d13, d14, d15, d16, d17);
          break;
        case 19:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12,
              d13, d14, d15, d16, d17, d18);
          break;
        case 20:
          obj = factory(d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12,
              d13, d14, d15, d16, d17, d18, d19);
          break;
        default:
          throw new BaseException(
              '''Cannot instantiate \'${ provider . key . displayName}\' because it has more than 20 dependencies''');
      }
    } catch (e, e_stack) {
      throw new InstantiationError(this, e, e_stack, provider.key);
    }
    return obj;
  }

  dynamic _getByDependency(ResolvedProvider provider, Dependency dep) {
    return this._getByKey(dep.key, dep.lowerBoundVisibility,
        dep.upperBoundVisibility, dep.optional);
  }

  dynamic _getByKey(Key key, Object lowerBoundVisibility,
      Object upperBoundVisibility, bool optional) {
    if (identical(key, INJECTOR_KEY)) {
      return this;
    }
    if (upperBoundVisibility is SelfMetadata) {
      return this._getByKeySelf(key, optional);
    } else {
      return this._getByKeyDefault(key, optional, lowerBoundVisibility);
    }
  }

  /** @internal */
  dynamic _throwOrNull(Key key, bool optional) {
    if (optional) {
      return null;
    } else {
      throw new NoProviderError(this, key);
    }
  }

  /** @internal */
  dynamic _getByKeySelf(Key key, bool optional) {
    var obj = this._strategy.getObjByKeyId(key.id);
    return (!identical(obj, UNDEFINED))
        ? obj
        : this._throwOrNull(key, optional);
  }

  /** @internal */
  dynamic _getByKeyDefault(
      Key key, bool optional, Object lowerBoundVisibility) {
    Injector inj;
    if (lowerBoundVisibility is SkipSelfMetadata) {
      inj = this._parent;
    } else {
      inj = this;
    }
    while (inj is Injector_) {
      var inj_ = (inj as Injector_);
      var obj = inj_._strategy.getObjByKeyId(key.id);
      if (!identical(obj, UNDEFINED)) return obj;
      inj = inj_._parent;
    }
    if (!identical(inj, null)) {
      if (optional) {
        return inj.getOptional(key.token);
      } else {
        return inj.get(key.token);
      }
    } else {
      return this._throwOrNull(key, optional);
    }
  }

  String get displayName {
    return '''Injector(providers: [${ _mapProviders ( this , ( ResolvedProvider b ) => ''' "${ b . key . displayName}" ''' ) . join ( ", " )}])''';
  }

  String toString() {
    return this.displayName;
  }
}

var INJECTOR_KEY = Key.get(Injector);
List<dynamic> _mapProviders(Injector_ injector, Function fn) {
  var res = [];
  for (var i = 0; i < injector._proto.numberOfProviders; ++i) {
    res.add(fn(injector._proto.getProviderAtIndex(i)));
  }
  return res;
}
