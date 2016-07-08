library angular2.src.core.reflection.reflector;

import "package:angular2/src/facade/collection.dart"
    show Map, MapWrapper, Set, SetWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show Type, isPresent;

import "platform_reflection_capabilities.dart"
    show PlatformReflectionCapabilities;
import "reflector_reader.dart" show ReflectorReader;
import "types.dart" show SetterFn, GetterFn, MethodFn;

export "platform_reflection_capabilities.dart"
    show PlatformReflectionCapabilities;
export "types.dart" show SetterFn, GetterFn, MethodFn;

/**
 * Reflective information about a symbol, including annotations, interfaces, and other metadata.
 */
class ReflectionInfo {
  List<dynamic> annotations;
  List<List<dynamic>> parameters;
  Function factory;
  List<dynamic> interfaces;
  Map<String, List<dynamic>> propMetadata;
  ReflectionInfo(
      [this.annotations,
      this.parameters,
      this.factory,
      this.interfaces,
      this.propMetadata]) {}
}

/**
 * Provides access to reflection data about symbols. Used internally by Angular
 * to power dependency injection and compilation.
 */
class Reflector extends ReflectorReader {
  /** @internal */
  var _injectableInfo = new Map<dynamic, ReflectionInfo>();
  /** @internal */
  var _getters = new Map<String, GetterFn>();
  /** @internal */
  var _setters = new Map<String, SetterFn>();
  /** @internal */
  var _methods = new Map<String, MethodFn>();
  /** @internal */
  Set<dynamic> _usedKeys;
  PlatformReflectionCapabilities reflectionCapabilities;
  Reflector(PlatformReflectionCapabilities reflectionCapabilities) : super() {
    /* super call moved to initializer */;
    this._usedKeys = null;
    this.reflectionCapabilities = reflectionCapabilities;
  }
  bool isReflectionEnabled() {
    return this.reflectionCapabilities.isReflectionEnabled();
  }

  /**
   * Causes `this` reflector to track keys used to access
   * [ReflectionInfo] objects.
   */
  void trackUsage() {
    this._usedKeys = new Set();
  }

  /**
   * Lists types for which reflection information was not requested since
   * [#trackUsage] was called. This list could later be audited as
   * potential dead code.
   */
  List<dynamic> listUnusedKeys() {
    if (this._usedKeys == null) {
      throw new BaseException("Usage tracking is disabled");
    }
    var allTypes = MapWrapper.keys(this._injectableInfo);
    return allTypes
        .where((key) => !SetWrapper.has(this._usedKeys, key))
        .toList();
  }

  void registerFunction(Function func, ReflectionInfo funcInfo) {
    this._injectableInfo[func] = funcInfo;
  }

  void registerType(Type type, ReflectionInfo typeInfo) {
    this._injectableInfo[type] = typeInfo;
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
    if (this._injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).parameters;
      return isPresent(res) ? res : [];
    } else {
      return this.reflectionCapabilities.parameters(typeOrFunc);
    }
  }

  List<dynamic> annotations(dynamic typeOrFunc) {
    if (this._injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).annotations;
      return isPresent(res) ? res : [];
    } else {
      return this.reflectionCapabilities.annotations(typeOrFunc);
    }
  }

  Map<String, List<dynamic>> propMetadata(dynamic typeOrFunc) {
    if (this._injectableInfo.containsKey(typeOrFunc)) {
      var res = this._getReflectionInfo(typeOrFunc).propMetadata;
      return isPresent(res) ? res : {};
    } else {
      return this.reflectionCapabilities.propMetadata(typeOrFunc);
    }
  }

  List<dynamic> interfaces(Type type) {
    if (this._injectableInfo.containsKey(type)) {
      var res = this._getReflectionInfo(type).interfaces;
      return isPresent(res) ? res : [];
    } else {
      return this.reflectionCapabilities.interfaces(type);
    }
  }

  GetterFn getter(String name) {
    if (this._getters.containsKey(name)) {
      return this._getters[name];
    } else {
      return this.reflectionCapabilities.getter(name);
    }
  }

  SetterFn setter(String name) {
    if (this._setters.containsKey(name)) {
      return this._setters[name];
    } else {
      return this.reflectionCapabilities.setter(name);
    }
  }

  MethodFn method(String name) {
    if (this._methods.containsKey(name)) {
      return this._methods[name];
    } else {
      return this.reflectionCapabilities.method(name);
    }
  }

  /** @internal */
  ReflectionInfo _getReflectionInfo(dynamic typeOrFunc) {
    if (isPresent(this._usedKeys)) {
      this._usedKeys.add(typeOrFunc);
    }
    return this._injectableInfo[typeOrFunc];
  }

  /** @internal */
  _containsReflectionInfo(dynamic typeOrFunc) {
    return this._injectableInfo.containsKey(typeOrFunc);
  }

  String importUri(Type type) {
    return this.reflectionCapabilities.importUri(type);
  }
}

void _mergeMaps(Map<String, Function> target, Map<String, Function> config) {
  StringMapWrapper.forEach(config, (Function v, String k) => target[k] = v);
}
