import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "injector.dart" show Injector, THROW_IF_NOT_FOUND;
import "decorators.dart";
import "provider.dart" show Provider;
import "reflective_exceptions.dart"
    show
        AbstractProviderError,
        NoProviderError,
        CyclicDependencyError,
        InstantiationError,
        OutOfBoundsError;
import "reflective_key.dart" show ReflectiveKey;
import "reflective_provider.dart"
    show
        ResolvedReflectiveProvider,
        ReflectiveDependency,
        ResolvedReflectiveFactory,
        resolveReflectiveProviders;

// Threshold for the dynamic version
const _MAX_CONSTRUCTION_COUNTER = 10;
const UNDEFINED = const Object();

abstract class ReflectiveProtoInjectorStrategy {
  ResolvedReflectiveProvider getProviderAtIndex(num index);
  ReflectiveInjectorStrategy createInjectorStrategy(ReflectiveInjectorImpl inj);
}

class ReflectiveProtoInjectorInlineStrategy
    implements ReflectiveProtoInjectorStrategy {
  ResolvedReflectiveProvider provider0;
  ResolvedReflectiveProvider provider1;
  ResolvedReflectiveProvider provider2;
  ResolvedReflectiveProvider provider3;
  ResolvedReflectiveProvider provider4;
  ResolvedReflectiveProvider provider5;
  ResolvedReflectiveProvider provider6;
  ResolvedReflectiveProvider provider7;
  ResolvedReflectiveProvider provider8;
  ResolvedReflectiveProvider provider9;
  num keyId0;
  num keyId1;
  num keyId2;
  num keyId3;
  num keyId4;
  num keyId5;
  num keyId6;
  num keyId7;
  num keyId8;
  num keyId9;
  ReflectiveProtoInjectorInlineStrategy(ReflectiveProtoInjector protoEI,
      List<ResolvedReflectiveProvider> providers) {
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
  ResolvedReflectiveProvider getProviderAtIndex(num index) {
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

  ReflectiveInjectorStrategy createInjectorStrategy(
      ReflectiveInjectorImpl injector) {
    return new ReflectiveInjectorInlineStrategy(injector, this);
  }
}

class ReflectiveProtoInjectorDynamicStrategy
    implements ReflectiveProtoInjectorStrategy {
  List<ResolvedReflectiveProvider> providers;
  final List<num> keyIds = <num>[];
  ReflectiveProtoInjectorDynamicStrategy(
      ReflectiveProtoInjector protoInj, this.providers) {
    var len = providers.length;
    for (var i = 0; i < len; i++) {
      keyIds.add(providers[i].key.id);
    }
  }
  ResolvedReflectiveProvider getProviderAtIndex(num index) => providers[index];

  ReflectiveInjectorStrategy createInjectorStrategy(ReflectiveInjectorImpl ei) {
    return new ReflectiveInjectorDynamicStrategy(this, ei);
  }
}

class ReflectiveProtoInjector {
  static ReflectiveProtoInjector fromResolvedProviders(
      List<ResolvedReflectiveProvider> providers) {
    return new ReflectiveProtoInjector(providers);
  }

  ReflectiveProtoInjectorStrategy _strategy;
  num numberOfProviders;
  ReflectiveProtoInjector(List<ResolvedReflectiveProvider> providers) {
    this.numberOfProviders = providers.length;
    this._strategy = providers.length > _MAX_CONSTRUCTION_COUNTER
        ? new ReflectiveProtoInjectorDynamicStrategy(this, providers)
        : new ReflectiveProtoInjectorInlineStrategy(this, providers);
  }
  ResolvedReflectiveProvider getProviderAtIndex(num index) {
    return this._strategy.getProviderAtIndex(index);
  }
}

abstract class ReflectiveInjectorStrategy {
  dynamic getObjByKeyId(num keyId);
  dynamic getObjAtIndex(num index);
  num getMaxNumberOfObjects();
  void resetConstructionCounter();
  dynamic instantiateProvider(ResolvedReflectiveProvider provider);
}

class ReflectiveInjectorInlineStrategy implements ReflectiveInjectorStrategy {
  ReflectiveInjectorImpl injector;
  ReflectiveProtoInjectorInlineStrategy protoStrategy;
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
  ReflectiveInjectorInlineStrategy(this.injector, this.protoStrategy);
  void resetConstructionCounter() {
    this.injector._constructionCounter = 0;
  }

  dynamic instantiateProvider(ResolvedReflectiveProvider provider) {
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

class ReflectiveInjectorDynamicStrategy implements ReflectiveInjectorStrategy {
  ReflectiveProtoInjectorDynamicStrategy protoStrategy;
  ReflectiveInjectorImpl injector;
  List<dynamic> objs;
  ReflectiveInjectorDynamicStrategy(this.protoStrategy, this.injector) {
    this.objs = new List.filled(protoStrategy.providers.length, UNDEFINED,
        growable: true);
  }
  void resetConstructionCounter() {
    this.injector._constructionCounter = 0;
  }

  dynamic instantiateProvider(ResolvedReflectiveProvider provider) {
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

  dynamic getObjAtIndex(num index) => objs[index];

  num getMaxNumberOfObjects() => objs.length;
}

/// A ReflectiveDependency injection container used for instantiating objects
/// and resolving dependencies.
///
/// An [Injector] is a replacement for a [new] operator, which can automatically
/// resolve the constructor dependencies.
///
/// In typical use, application code asks for the dependencies in the
/// constructor and they are resolved by the [Injector].
///
/// The following example creates an `Injector` configured to create [Engine]
/// and [Car].
///
///     @Injectable()
///     class Engine {
///     }
///
///     @Injectable()
///     class Car {
///       Car(Engine engine);
///     }
///
///     var injector = ReflectiveInjector.resolveAndCreate([Car, Engine]);
///     var car = injector.get(Car);
///     expect(car is Car, true);
///     expect(car.engine is Engine, true);
///
/// Notice, we don't use the [new] operator because we explicitly want to have
/// the [Injector] resolve all of the object's dependencies automatically.
///
abstract class ReflectiveInjector implements Injector {
  /// Turns an array of provider definitions into an array of resolved
  /// providers.
  ///
  /// A resolution is a process of flattening multiple nested arrays and
  /// converting individual providers into an array of
  /// [ResolvedReflectiveProvider]s.
  ///
  ///     @Injectable()
  ///     class Engine {
  ///     }
  ///
  ///     @Injectable()
  ///     class Car {
  ///       Car(Engine engine);
  ///     }
  ///
  ///     var providers = ReflectiveInjector.resolve([Car, [[Engine]]]);
  ///
  ///     expect(providers, hasLength(2));
  ///
  ///     expect(providers[0] is ResolvedReflectiveProvider, true);
  ///     expect(providers[0].key.displayName, "Car");
  ///     expect(providers[0].dependencies, hasLength(1));
  ///     expect(providers[0].factory, isNotNull);
  ///
  ///     expect(providers[1].key.displayName, "Engine");
  ///
  /// See [ReflectiveInjector#fromResolvedProviders] for more info.
  ///
  static List<ResolvedReflectiveProvider> resolve(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers) {
    return resolveReflectiveProviders(providers);
  }

  /// Resolves an array of providers and creates an injector from those
  /// providers.
  ///
  /// The passed-in providers can be an array of [Type] | [Provider],
  /// or a recursive array of more providers.
  ///
  ///     @Injectable()
  ///     class Engine {
  ///     }
  ///
  ///     @Injectable()
  ///     class Car {
  ///       Car(Engine engine);
  ///     }
  ///
  ///     var injector = ReflectiveInjector.resolveAndCreate([Car, Engine]);
  ///     expect(injector.get(Car) is Car, true);
  ///
  ///
  /// This function is slower than the corresponding [fromResolvedProviders]
  /// because it needs to resolve the passed-in providers first.
  /// See [Injector#resolve] and [Injector#fromResolvedProviders].
  ///
  static ReflectiveInjector resolveAndCreate(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers,
      [Injector parent = null]) {
    var ResolvedReflectiveProviders = ReflectiveInjector.resolve(providers);
    return ReflectiveInjector.fromResolvedProviders(
        ResolvedReflectiveProviders, parent);
  }

  /// Creates an injector from previously resolved providers.
  ///
  /// This API is the recommended way to construct injectors in
  /// performance-sensitive parts.
  ///
  ///     @Injectable()
  ///     class Engine {
  ///     }
  ///
  ///     @Injectable()
  ///     class Car {
  ///       Car(Engine engine);
  ///     }
  ///
  ///     var providers = ReflectiveInjector.resolve([Car, Engine]);
  ///     var injector = ReflectiveInjector.fromResolvedProviders(providers);
  ///     expect(injector.get(Car) is Car, true);
  ///
  static ReflectiveInjector fromResolvedProviders(
      List<ResolvedReflectiveProvider> providers,
      [Injector parent = null]) {
    return new ReflectiveInjectorImpl(
        ReflectiveProtoInjector.fromResolvedProviders(providers), parent);
  }

  static ReflectiveInjector fromResolvedBindings(
      List<ResolvedReflectiveProvider> providers) {
    return ReflectiveInjector.fromResolvedProviders(providers);
  }

  /// Parent of this injector.
  ///
  /// <!-- TODO: Add a link to the section of the user guide talking about
  /// hierarchical injection.
  ///
  ///     var parent = ReflectiveInjector.resolveAndCreate([]);
  ///     var child = parent.resolveAndCreateChild([]);
  ///     expect(child.parent, parent);
  ///
  Injector get parent;

  dynamic debugContext() => null;

  /// Resolves an array of providers and creates a child injector from those providers.
  ///
  /// The passed-in providers can be an array of `Type`, [Provider],
  /// or a recursive array of more providers.
  ///
  ///     class ParentProvider {}
  ///     class ChildProvider {}
  ///
  ///     var parent = ReflectiveInjector.resolveAndCreate([ParentProvider]);
  ///     var child = parent.resolveAndCreateChild([ChildProvider]);
  ///
  ///     expect(child.get(ParentProvider) is ParentProvider, true);
  ///     expect(child.get(ChildProvider) is ChildProvider, true);
  ///     expect(child.get(ParentProvider), parent.get(ParentProvider));
  ///
  /// This function is slower than the corresponding [createChildFromResolved]
  /// because it needs to resolve the passed-in providers first.
  /// See [Injector#resolve] and [Injector#createChildFromResolved].
  ///
  ReflectiveInjector resolveAndCreateChild(
      List<dynamic /* Type | Provider | List < dynamic > */ > providers);

  /// Creates a child injector from previously resolved providers.
  ///
  /// This API is the recommended way to construct injectors in
  /// performance-sensitive parts.
  ///
  ///     class ParentProvider {}
  ///     class ChildProvider {}
  ///
  ///     var parentProviders = ReflectiveInjector.resolve([ParentProvider]);
  ///     var childProviders = ReflectiveInjector.resolve([ChildProvider]);
  ///
  ///     var parent = ReflectiveInjector.fromResolvedProviders(parentProviders);
  ///     var child = parent.createChildFromResolved(childProviders);
  ///
  ///     expect(child.get(ParentProvider) is ParentProvider, true);
  ///     expect(child.get(ChildProvider) is ChildProvider, true);
  ///     expect(child.get(ParentProvider), parent.get(ParentProvider));
  ///
  ReflectiveInjector createChildFromResolved(
      List<ResolvedReflectiveProvider> providers);

  /// Resolves a provider and instantiates an object in the context of the
  /// injector.
  dynamic resolveAndInstantiate(dynamic /* Type | Provider */ provider);

  /// Instantiates an object using a resolved provider in the context of the
  /// injector.
  ///
  /// The created object does not get cached by the injector.
  ///
  ///     @Injectable()
  ///     class Engine {
  ///     }
  ///
  ///     @Injectable()
  ///     class Car {
  ///       Car(Engine engine);
  ///     }
  ///
  ///     var injector = ReflectiveInjector.resolveAndCreate([Engine]);
  ///     var carProvider = ReflectiveInjector.resolve([Car])[0];
  ///     var car = injector.instantiateResolved(carProvider);
  ///     expect(car.engine, injector.get(Engine));
  ///     expect(car != injector.instantiateResolved(carProvider), true);
  ///
  dynamic instantiateResolved(ResolvedReflectiveProvider provider);

  dynamic get(dynamic token, [dynamic notFoundValue]);
}

class ReflectiveInjectorImpl implements ReflectiveInjector {
  final _proto;
  Injector _parent;
  final Function _debugContext;

  ReflectiveInjectorStrategy _strategy;
  num _constructionCounter = 0;

  ReflectiveInjectorImpl(this._proto,
      [this._parent = null, this._debugContext = null]) {
    _strategy = _proto._strategy.createInjectorStrategy(this);
  }

  dynamic debugContext() => _debugContext();

  dynamic get(dynamic token, [dynamic notFoundValue = THROW_IF_NOT_FOUND]) {
    return this._getByKey(ReflectiveKey.get(token), null, null, notFoundValue);
  }

  dynamic getAt(num index) {
    return this._strategy.getObjAtIndex(index);
  }

  Injector get parent => _parent;

  /// Internal. Do not use.
  ///
  /// We return [any] not to export the InjectorStrategy type.
  dynamic get internalStrategy => _strategy;

  ReflectiveInjector resolveAndCreateChild(
          List<dynamic /* Type | Provider | List < dynamic > */ > providers) =>
      this.createChildFromResolved(ReflectiveInjector.resolve(providers));

  ReflectiveInjector createChildFromResolved(
          List<ResolvedReflectiveProvider> providers) =>
      new ReflectiveInjectorImpl(new ReflectiveProtoInjector(providers))
        .._parent = this;

  dynamic resolveAndInstantiate(dynamic /* Type | Provider */ provider) =>
      instantiateResolved(ReflectiveInjector.resolve([provider])[0]);

  dynamic instantiateResolved(ResolvedReflectiveProvider provider) =>
      _instantiateProvider(provider);

  dynamic _new(ResolvedReflectiveProvider provider) {
    // Although tempting do not place this in an assert since it will cause
    // StackOverflow and fail test suite with StackOverflow.
    if (_constructionCounter++ > _strategy.getMaxNumberOfObjects()) {
      throw new CyclicDependencyError(this, provider.key);
    }
    return _instantiateProvider(provider);
  }

  dynamic _instantiateProvider(ResolvedReflectiveProvider provider) {
    var factories = provider.resolvedFactories;
    if (provider.multiProvider) {
      int len = factories.length;
      var res = new List(len);
      for (var i = 0; i < len; ++i) {
        res[i] = _instantiate(provider, factories[i]);
      }
      return res;
    } else {
      return _instantiate(provider, factories[0]);
    }
  }

  dynamic _instantiate(ResolvedReflectiveProvider provider,
      ResolvedReflectiveFactory resolvedFactory) {
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
      d0 = length > 0
          ? this._getByReflectiveDependency(provider, deps[0])
          : null;
      d1 = length > 1
          ? this._getByReflectiveDependency(provider, deps[1])
          : null;
      d2 = length > 2
          ? this._getByReflectiveDependency(provider, deps[2])
          : null;
      d3 = length > 3
          ? this._getByReflectiveDependency(provider, deps[3])
          : null;
      d4 = length > 4
          ? this._getByReflectiveDependency(provider, deps[4])
          : null;
      d5 = length > 5
          ? this._getByReflectiveDependency(provider, deps[5])
          : null;
      d6 = length > 6
          ? this._getByReflectiveDependency(provider, deps[6])
          : null;
      d7 = length > 7
          ? this._getByReflectiveDependency(provider, deps[7])
          : null;
      d8 = length > 8
          ? this._getByReflectiveDependency(provider, deps[8])
          : null;
      d9 = length > 9
          ? this._getByReflectiveDependency(provider, deps[9])
          : null;
      d10 = length > 10
          ? this._getByReflectiveDependency(provider, deps[10])
          : null;
      d11 = length > 11
          ? this._getByReflectiveDependency(provider, deps[11])
          : null;
      d12 = length > 12
          ? this._getByReflectiveDependency(provider, deps[12])
          : null;
      d13 = length > 13
          ? this._getByReflectiveDependency(provider, deps[13])
          : null;
      d14 = length > 14
          ? this._getByReflectiveDependency(provider, deps[14])
          : null;
      d15 = length > 15
          ? this._getByReflectiveDependency(provider, deps[15])
          : null;
      d16 = length > 16
          ? this._getByReflectiveDependency(provider, deps[16])
          : null;
      d17 = length > 17
          ? this._getByReflectiveDependency(provider, deps[17])
          : null;
      d18 = length > 18
          ? this._getByReflectiveDependency(provider, deps[18])
          : null;
      d19 = length > 19
          ? this._getByReflectiveDependency(provider, deps[19])
          : null;
    } catch (e) {
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
              "Cannot instantiate '${provider.key.displayName}' "
              "because it has more than 20 dependencies");
      }
    } catch (e, e_stack) {
      throw new InstantiationError(this, e, e_stack, provider.key);
    }
    return resolvedFactory.postProcess(obj);
  }

  dynamic _getByReflectiveDependency(
      ResolvedReflectiveProvider provider, ReflectiveDependency dep) {
    return _getByKey(dep.key, dep.lowerBoundVisibility,
        dep.upperBoundVisibility, dep.optional ? null : THROW_IF_NOT_FOUND);
  }

  dynamic _getByKey(ReflectiveKey key, Object lowerBoundVisibility,
      Object upperBoundVisibility, dynamic notFoundValue) {
    if (identical(key, INJECTOR_KEY)) {
      return this;
    }
    if (upperBoundVisibility is Self) {
      return _getByKeySelf(key, notFoundValue);
    } else {
      return _getByKeyDefault(key, notFoundValue, lowerBoundVisibility);
    }
  }

  dynamic _throwOrNull(ReflectiveKey key, dynamic notFoundValue) {
    if (!identical(notFoundValue, THROW_IF_NOT_FOUND)) {
      return notFoundValue;
    } else {
      throw new NoProviderError(this, key);
    }
  }

  dynamic _getByKeySelf(ReflectiveKey key, dynamic notFoundValue) {
    var obj = this._strategy.getObjByKeyId(key.id);
    return (!identical(obj, UNDEFINED))
        ? obj
        : this._throwOrNull(key, notFoundValue);
  }

  dynamic _getByKeyDefault(
      ReflectiveKey key, dynamic notFoundValue, Object lowerBoundVisibility) {
    Injector inj;
    if (lowerBoundVisibility is SkipSelf) {
      inj = this._parent;
    } else {
      inj = this;
    }
    while (inj is ReflectiveInjectorImpl) {
      var inj_ = (inj as ReflectiveInjectorImpl);
      var obj = inj_._strategy.getObjByKeyId(key.id);
      if (!identical(obj, UNDEFINED)) return obj;
      inj = inj_._parent;
    }
    if (!identical(inj, null)) {
      return inj.get(key.token, notFoundValue);
    } else {
      return this._throwOrNull(key, notFoundValue);
    }
  }

  String get displayName {
    String providers = _mapProviders(
            this, (ResolvedReflectiveProvider b) => ' "${b.key.displayName}" ')
        .join(", ");
    return 'ReflectiveInjector(providers: [$providers])';
  }

  String toString() => displayName;
}

var INJECTOR_KEY = ReflectiveKey.get(Injector);
List<dynamic> _mapProviders(ReflectiveInjectorImpl injector, Function fn) {
  var res = [];
  for (var i = 0; i < injector._proto.numberOfProviders; ++i) {
    res.add(fn(injector._proto.getProviderAtIndex(i)));
  }
  return res;
}
