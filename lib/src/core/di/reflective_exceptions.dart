import "package:angular2/src/facade/exceptions.dart"
    show BaseException, WrappedException;
import "reflective_injector.dart" show ReflectiveInjector;
import "reflective_key.dart" show ReflectiveKey;
import "provider.dart";
import "metadata.dart";

List<dynamic> findFirstClosedCycle(List keys) {
  var res = [];
  for (var i = 0; i < keys.length; ++i) {
    if (res.contains(keys[i])) {
      res.add(keys[i]);
      return res;
    } else {
      res.add(keys[i]);
    }
  }
  return res;
}

List<dynamic> findFirstClosedCycleReversed(List keys) {
  var res = [];
  for (var i = keys.length - 1; i >= 0; i--) {
    if (res.contains(keys[i])) {
      res.add(keys[i]);
      return res;
    } else {
      res.add(keys[i]);
    }
  }
  return res;
}

String constructResolvingPath(List<dynamic> keys) {
  if (keys.length > 1) {
    var reversed = findFirstClosedCycleReversed(keys);
    var tokenStrs = reversed
        .map((k) => '${InjectMetadata.tokenToString(k.token)}')
        .toList();
    return " (" + tokenStrs.join(" -> ") + ")";
  } else {
    return "";
  }
}

/// Base class for all errors arising from misconfigured providers.
class AbstractProviderError extends BaseException {
  String message;
  List<ReflectiveKey> keys;
  List<ReflectiveInjector> injectors;
  Function constructResolvingMessage;
  AbstractProviderError(ReflectiveInjector injector, ReflectiveKey key,
      Function constructResolvingMessage)
      : super("DI Exception") {
    /* super call moved to initializer */;
    this.keys = [key];
    this.injectors = [injector];
    this.constructResolvingMessage = constructResolvingMessage;
    this.message = this.constructResolvingMessage(this.keys);
  }
  void addKey(ReflectiveInjector injector, ReflectiveKey key) {
    this.injectors.add(injector);
    this.keys.add(key);
    this.message = this.constructResolvingMessage(this.keys);
  }

  get context {
    return injectors.last.debugContext();
  }
}

/// Thrown when trying to retrieve a dependency by `Key` from [Injector], but
/// the [Injector] does not have a [Provider] for [Key].
///
/// class A {
///   A(B b);
/// }
///
/// expect(() => Injector.resolveAndCreate([A]), throws);
///
class NoProviderError extends AbstractProviderError {
  NoProviderError(ReflectiveInjector injector, ReflectiveKey key)
      : super(injector, key, (List<dynamic> keys) {
          var first = '${InjectMetadata.tokenToString(keys.first.token)}';
          return '''No provider for ${ first}!${ constructResolvingPath ( keys )}''';
        });
}

/// Thrown when dependencies form a cycle.
///
/// Example:
///
/// var injector = Injector.resolveAndCreate([
///   provide("one", useFactory: (two) => "two", deps: [[new Inject("two")]]),
///   provide("two", useFactory: (one) => "one", deps: [[new Inject("one")]])
/// ]);
///
/// expect(() => injector.get("one"), throws);
///
/// Retrieving [A] or [B] throws a [CyclicDependencyError] as the graph above
/// cannot be constructed.
class CyclicDependencyError extends AbstractProviderError {
  CyclicDependencyError(ReflectiveInjector injector, ReflectiveKey key)
      : super(injector, key, (List<dynamic> keys) {
          return 'Cannot instantiate cyclic '
              'dependency!${constructResolvingPath(keys)}';
        });
}

/// Thrown when a constructing type returns with an Error.
///
/// The [InstantiationError] class contains the original error plus the
/// dependency graph which caused this object to be instantiated.
///
/// ### Example ([live demo](http://plnkr.co/edit/7aWYdcqTQsP0eNqEdUAf?p=preview))
///
/// ```typescript
/// class A {
///   constructor() {
///     throw new Error('message');
///   }
/// }
///
/// var injector = Injector.resolveAndCreate([A]);
///
/// try {
///   injector.get(A);
/// } catch (e) {
///   expect(e instanceof InstantiationError).toBe(true);
///   expect(e.originalException.message).toEqual("message");
///   expect(e.originalStack).toBeDefined();
/// }
///
class InstantiationError extends WrappedException {
  List<ReflectiveKey> keys;
  List<ReflectiveInjector> injectors;

  InstantiationError(ReflectiveInjector injector, originalException,
      originalStack, ReflectiveKey key)
      : super("DI Exception", originalException, originalStack, null) {
    /* super call moved to initializer */;
    this.keys = [key];
    this.injectors = [injector];
  }
  void addKey(ReflectiveInjector injector, ReflectiveKey key) {
    this.injectors.add(injector);
    this.keys.add(key);
  }

  String get wrapperMessage => 'Error during instantiation of '
      '${InjectMetadata.tokenToString(keys.first.token)}!'
      '${constructResolvingPath(keys)}.';

  ReflectiveKey get causeKey {
    return this.keys[0];
  }

  get context {
    return this.injectors[this.injectors.length - 1].debugContext();
  }
}

/// Thrown when an invalid provider is passed in the provider list to create an
/// [Injector].
///
/// Example:
///
///     Injector.resolveAndCreate(["not a type"]);
///
class InvalidProviderError extends BaseException {
  /// Thrown when an invalid provider ([Provider] or [Type]) is passed in the
  /// provider list to the [Injector].
  InvalidProviderError(provider)
      : this.withCustomMessage(provider,
            'only instances of Provider and Type are allowed, got ${provider.runtimeType}');

  /// Constructs a error with a custom message.
  InvalidProviderError.withCustomMessage(provider, String message)
      : super(
            'Invalid provider (${provider is Provider ? provider.token : provider}): $message');
}

/// Thrown when the class has no annotation information.
///
/// Lack of annotation information prevents the [Injector] from determining
/// which dependencies need to be injected into the constructor.
///
/// class A {
///   A(b);
/// }
///
/// expect(() => Injector.resolveAndCreate([A]), throws);
///
/// This error is also thrown when the class not marked with [Injectable] has
/// parameter types.
///
/// class B {}
///
/// class A {
///   A(B b) {} // no information about the parameter types of A is available.
/// }
///
/// expect(() => Injector.resolveAndCreate([A,B]), throws);
///
class NoAnnotationError extends BaseException {
  NoAnnotationError(typeOrFunc, List<List<dynamic>> params)
      : super(NoAnnotationError._genMessage(typeOrFunc, params));

  static _genMessage(typeOrFunc, List<List<dynamic>> params) {
    var signature = [];
    for (var i = 0, ii = params.length; i < ii; i++) {
      var parameter = params[i];
      if (parameter == null || parameter.length == 0) {
        signature.add("?");
      } else {
        signature.add(parameter
            .map((x) => InjectMetadata.tokenToString(x))
            .toList()
            .join(" "));
      }
    }
    String typeStr = InjectMetadata.tokenToString(typeOrFunc);
    return "Cannot resolve all parameters for '$typeStr'(" +
        signature.join(", ") +
        "). " +
        "Make sure that all the parameters are decorated with Inject "
        "or have valid type annotations and that '$typeStr" +
        "' is decorated with Injectable.";
  }
}

/// Thrown when getting an object by index.
///
/// ### Example ([live demo](http://plnkr.co/edit/bRs0SX2OTQiJzqvjgl8P?p=preview))
///
/// class A {}
///
/// var injector = Injector.resolveAndCreate([A]);
///
/// expect(() => injector.getAt(100), throws);
///
class OutOfBoundsError extends BaseException {
  OutOfBoundsError(index) : super('''Index ${ index} is out-of-bounds.''') {
    /* super call moved to initializer */;
  }
}
// TODO: add a working example after alpha38 is released

/// Thrown when a multi provider and a regular provider are bound to the same token.
///
/// expect(() => Injector.resolveAndCreate([
///   new Provider("Strings", useValue: "string1", multi: true),
///   new Provider("Strings", useValue: "string2", multi: false)
/// ]), throws);
///
class MixingMultiProvidersWithRegularProvidersError extends BaseException {
  MixingMultiProvidersWithRegularProvidersError(provider1, provider2)
      : super("Cannot mix multi providers and regular providers, got: " +
            provider1.toString() +
            " " +
            provider2.toString());
}
