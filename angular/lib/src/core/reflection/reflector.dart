import 'dart:collection';

import 'platform_reflection_capabilities.dart';
import 'types.dart';

export "platform_reflection_capabilities.dart";
export "types.dart";

/// Reflective information about a symbol, including annotations, interfaces,
/// and other metadata.
class ReflectionInfo {
  List annotations;
  List<List> parameters;
  Function factory;
  List interfaces;
  Map<String, List> propMetadata;
  ReflectionInfo(
      [this.annotations,
      this.parameters,
      this.factory,
      this.interfaces,
      this.propMetadata]);
}

/// Provides access to reflection data about symbols.
///
/// Used internally by Angular to power dependency injection and compilation.
class Reflector {
  final _injectableInfo = new HashMap<dynamic, ReflectionInfo>();
  final _getters = new HashMap<String, GetterFn>();
  final _setters = new HashMap<String, SetterFn>();
  final _methods = new HashMap<String, MethodFn>();

  PlatformReflectionCapabilities reflectionCapabilities;

  Reflector(this.reflectionCapabilities);

  bool get reflectionEnabled => reflectionCapabilities.reflectionEnabled;

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

  void registerGetters(Map<String, GetterFn> getters) {
    _mergeMaps(_getters, getters);
  }

  void registerSetters(Map<String, SetterFn> setters) {
    _mergeMaps(_setters, setters);
  }

  void registerMethods(Map<String, MethodFn> methods) {
    _mergeMaps(_methods, methods);
  }

  Function factory(Type type) {
    if (this._containsReflectionInfo(type)) {
      return _getReflectionInfo(type).factory;
    } else {
      return reflectionCapabilities.factory(type);
    }
  }

  List<List<dynamic>> parameters(dynamic typeOrFunc) {
    var res = _injectableInfo[typeOrFunc];
    if (res != null) {
      return res.parameters ?? const [];
    } else {
      return reflectionCapabilities.parameters(typeOrFunc);
    }
  }

  List<dynamic> annotations(dynamic typeOrFunc) {
    if (_injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).annotations;
      return res ?? [];
    } else {
      return reflectionCapabilities.annotations(typeOrFunc);
    }
  }

  Map<String, List<dynamic>> propMetadata(dynamic typeOrFunc) {
    if (_injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).propMetadata;
      return res ?? {};
    } else {
      return reflectionCapabilities.propMetadata(typeOrFunc);
    }
  }

  List<dynamic> interfaces(Type type) {
    if (_injectableInfo.containsKey(type)) {
      var res = this._getReflectionInfo(type).interfaces;
      return res ?? [];
    } else {
      return reflectionCapabilities.interfaces(type);
    }
  }

  GetterFn getter(String name) {
    var res = _getters[name];
    if (res != null) return res;
    return reflectionCapabilities.getter(name);
  }

  SetterFn setter(String name) {
    var res = _setters[name];
    if (res != null) return res;
    return reflectionCapabilities.setter(name);
  }

  MethodFn method(String name) {
    var m = _methods[name];
    if (m != null) return m;
    return reflectionCapabilities.method(name);
  }

  ReflectionInfo _getReflectionInfo(dynamic typeOrFunc) {
    return _injectableInfo[typeOrFunc];
  }

  bool _containsReflectionInfo(dynamic typeOrFunc) {
    return _injectableInfo.containsKey(typeOrFunc);
  }

  String importUri(Type type) {
    return reflectionCapabilities.importUri(type);
  }
}

void _mergeMaps(Map<String, Function> target, Map<String, Function> config) {
  config.forEach((String k, Function v) => target[k] = v);
}
