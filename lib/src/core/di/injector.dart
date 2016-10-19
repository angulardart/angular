import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'decorators.dart';

const _THROW_IF_NOT_FOUND = const Object();
const THROW_IF_NOT_FOUND = _THROW_IF_NOT_FOUND;

class _NullInjector implements Injector {
  dynamic get(dynamic token, [dynamic notFoundValue = _THROW_IF_NOT_FOUND]) {
    if (identical(notFoundValue, _THROW_IF_NOT_FOUND)) {
      throw new BaseException(
          'No provider for ${Inject.tokenToString(token)}!');
    }
    return notFoundValue;
  }
}

/// The Injector interface.
///
/// This class can also be used to get hold of an Injector.
abstract class Injector {
  static var THROW_IF_NOT_FOUND = _THROW_IF_NOT_FOUND;
  static Injector NULL = new _NullInjector();

  /// Retrieves an instance from the injector based on the provided token.
  /// If not found:
  /// - Throws [NoProviderError] if no `notFoundValue` that is not equal to
  /// Injector.THROW_IF_NOT_FOUND is given
  /// - Returns the `notFoundValue` otherwise
  ///
  /// ### Example ([live demo](http://plnkr.co/edit/HeXSHg?p=preview))
  ///
  /// var injector = ReflectiveInjector.resolveAndCreate([
  ///   provide("validToken", {useValue: "Value"})
  /// ]);
  /// expect(injector.get("validToken")).toEqual("Value");
  /// expect(() => injector.get("invalidToken")).toThrowError();
  ///
  /// [Injector] returns itself when given [Injector] as a token.
  ///
  /// var injector = ReflectiveInjector.resolveAndCreate([]);
  /// expect(injector.get(Injector)).toBe(injector);
  dynamic get(dynamic token, [dynamic notFoundValue]);
}

/// Factory for creating an Injector that delegates to parent.
class _EmptyInjectorFactory implements InjectorFactory<dynamic> {
  Injector create([Injector parent = null, dynamic context = null]) {
    return parent == null ? Injector.NULL : parent;
  }

  const _EmptyInjectorFactory();
}

/// A factory for an injector.
abstract class InjectorFactory<CONTEXT> {
  /// An InjectorFactory that will always delegate to the parent.
  static InjectorFactory<dynamic> EMPTY = const _EmptyInjectorFactory();

  /// Binds an InjectorFactory to a fixed context
  static InjectorFactory<dynamic> bind(
      InjectorFactory<dynamic> factory, dynamic context) {
    return new _BoundInjectorFactory(factory, context);
  }

  Injector create([Injector parent, CONTEXT context]);
}

class _BoundInjectorFactory implements InjectorFactory<dynamic> {
  InjectorFactory<dynamic> _delegate;
  dynamic _context;
  _BoundInjectorFactory(this._delegate, this._context);
  Injector create([Injector parent = null, dynamic context = null]) {
    return this._delegate.create(parent, this._context);
  }
}
