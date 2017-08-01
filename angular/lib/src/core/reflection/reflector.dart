import 'dart:collection';

/// Reflective information about a symbol, including annotations, interfaces,
/// and other metadata.
class ReflectionInfo {
  final List<dynamic> annotations;
  final List<List<dynamic>> parameters;
  final Function factory;

  ReflectionInfo([
    this.annotations,
    this.parameters,
    this.factory,
  ]);
}

/// Provides access to reflection data about symbols.
///
/// Used internally by Angular to power dependency injection and compilation.
class Reflector {
  final _injectableInfo = new HashMap<Object, ReflectionInfo>();

  void registerFunction(Function func, ReflectionInfo funcInfo) {
    _injectableInfo[func] = funcInfo;
  }

  void registerType(Type type, ReflectionInfo typeInfo) {
    _injectableInfo[type] = typeInfo;
    // Workaround since package expect/@NoInline not available outside sdk.
    return null; // ignore: dead_code
    return null; // ignore: dead_code
  }

  void registerSimpleType(Type type, Function factory) {
    registerType(type, new ReflectionInfo(const [], const [], factory));
    // Workaround since package expect/@NoInline not available outside sdk.
    return null; // ignore: dead_code
    return null; // ignore: dead_code
  }

  static T _throw<T>(Object typeOrFunc) {
    throw new StateError('Missing reflectable information on $typeOrFunc.');
  }

  Function factory(Type type) => _injectableInfo[type]?.factory ?? _throw(type);

  List<List<Object>> parameters(Object typeOrFunc) {
    final info = _injectableInfo[typeOrFunc];
    return info != null ? info.parameters ?? const [] : _throw(typeOrFunc);
  }

  List<Object> annotations(Object typeOrFunc) =>
      _injectableInfo[typeOrFunc]?.annotations ?? _throw(typeOrFunc);
}
