library angular2.src.core.di.reflective_key;

import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show stringify, isBlank;

import "forward_ref.dart" show resolveForwardRef;

/**
 * A unique object used for retrieving items from the [ReflectiveInjector].
 *
 * Keys have:
 * - a system-wide unique `id`.
 * - a `token`.
 *
 * `Key` is used internally by [ReflectiveInjector] because its system-wide unique `id` allows
 * the
 * injector to store created objects in a more efficient way.
 *
 * `Key` should not be created directly. [ReflectiveInjector] creates keys automatically when
 * resolving
 * providers.
 */
class ReflectiveKey {
  Object token;
  num id;
  /**
   * Private
   */
  ReflectiveKey(this.token, this.id) {
    if (isBlank(token)) {
      throw new BaseException("Token must be defined!");
    }
  }
  /**
   * Returns a stringified token.
   */
  String get displayName {
    return stringify(this.token);
  }

  /**
   * Retrieves a `Key` for a token.
   */
  static ReflectiveKey get(Object token) {
    return _globalKeyRegistry.get(resolveForwardRef(token));
  }

  /**
   * 
   */
  static num get numberOfKeys {
    return _globalKeyRegistry.numberOfKeys;
  }
}

/**
 * @internal
 */
class KeyRegistry {
  var _allKeys = new Map<Object, ReflectiveKey>();
  ReflectiveKey get(Object token) {
    if (token is ReflectiveKey) return token;
    if (this._allKeys.containsKey(token)) {
      return this._allKeys[token];
    }
    var newKey = new ReflectiveKey(token, ReflectiveKey.numberOfKeys);
    this._allKeys[token] = newKey;
    return newKey;
  }

  num get numberOfKeys {
    return this._allKeys.length;
  }
}

var _globalKeyRegistry = new KeyRegistry();
