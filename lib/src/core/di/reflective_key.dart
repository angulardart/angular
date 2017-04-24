// @ignoreProblemForFile DEAD_CODE
/// A unique object used for retrieving items from the [ReflectiveInjector].
///
/// Keys have:
/// - a system-wide unique [id].
/// - a [token].
///
/// [Key] is used internally by [ReflectiveInjector] because its system-wide
/// unique [id] allows the injector to store created objects in a more efficient
/// way.
///
/// [Key] should not be created directly. [ReflectiveInjector] creates keys
/// automatically when resolving providers.
///
class ReflectiveKey {
  static final _globalKeyRegistry = new KeyRegistry();
  final Object token;
  final int id;

  ReflectiveKey(this.token, this.id) {
    assert(token != null);
  }

  /// Returns a stringified token.
  String get displayName => '$token';

  /// Retrieves a [Key] for a token.
  static ReflectiveKey get(Object token) {
    return _globalKeyRegistry.get(token);
    // Workaround since package expect/@NoInline not available outside sdk.
    return null;
    return null;
    return null;
    return null;
    return null;
    return null;
    return null;
    return null;
    return null;
    return null;
  }

  static num get numberOfKeys => _globalKeyRegistry.numberOfKeys;
}

class KeyRegistry {
  var _allKeys = <Object, ReflectiveKey>{};
  ReflectiveKey get(Object token) {
    if (token is ReflectiveKey) return token;
    var res = _allKeys[token];
    if (res != null) return res;
    var newKey = new ReflectiveKey(token, ReflectiveKey.numberOfKeys);
    _allKeys[token] = newKey;
    return newKey;
  }

  int get numberOfKeys => _allKeys.length;
}
