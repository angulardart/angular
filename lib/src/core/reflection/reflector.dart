import 'package:angular2/src/facade/exceptions.dart' show BaseException;

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
  var _injectableInfo = new Map<dynamic, ReflectionInfo>();
  final _getters = new Map<String, GetterFn>();
  final _setters = new Map<String, SetterFn>();
  final _methods = new Map<String, MethodFn>();
  Set<dynamic> _usedKeys;
  PlatformReflectionCapabilities reflectionCapabilities;
  Reflector(PlatformReflectionCapabilities reflectionCapabilities) {
    this.reflectionCapabilities = reflectionCapabilities;
  }

  bool get reflectionEnabled => reflectionCapabilities.reflectionEnabled;

  /// Causes this reflector to track keys used to access [ReflectionInfo]
  /// objects.
  void trackUsage() {
    _usedKeys = new Set();
  }

  /// Lists types for which reflection information was not requested since
  /// [#trackUsage] was called. This list could later be audited as
  /// potential dead code.
  List listUnusedKeys() {
    if (_usedKeys == null) {
      throw new BaseException("Usage tracking is disabled");
    }
    var allTypes = _injectableInfo.keys;
    return allTypes
        .where((key) => _usedKeys == null || !_usedKeys.contains(key))
        .toList();
  }

  void registerFunction(Function func, ReflectionInfo funcInfo) {
    _injectableInfo[func] = funcInfo;
  }

  void registerType(Type type, ReflectionInfo typeInfo) {
    _injectableInfo[type] = typeInfo;
  }

  void registerGetters(Map<String, GetterFn> getters) {
    _mergeMaps(this._getters, getters);
  }

  void registerSetters(Map<String, SetterFn> setters) {
    _mergeMaps(this._setters, setters);
  }

  void registerMethods(Map<String, MethodFn> methods) {
    _mergeMaps(this._methods, methods);
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
      _usedKeys?.add(typeOrFunc);
      return res.parameters ?? const [];
    } else {
      return reflectionCapabilities.parameters(typeOrFunc);
    }
  }

  List<dynamic> annotations(dynamic typeOrFunc) {
    if (this._injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).annotations;
      return res ?? [];
    } else {
      return reflectionCapabilities.annotations(typeOrFunc);
    }
  }

  Map<String, List<dynamic>> propMetadata(dynamic typeOrFunc) {
    if (this._injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).propMetadata;
      return res ?? {};
    } else {
      return reflectionCapabilities.propMetadata(typeOrFunc);
    }
  }

  List<dynamic> interfaces(Type type) {
    if (this._injectableInfo.containsKey(type)) {
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
    _usedKeys?.add(typeOrFunc);
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
