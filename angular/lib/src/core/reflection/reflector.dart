import 'dart:collection';

import 'platform_reflection_capabilities.dart';

export "platform_reflection_capabilities.dart";
export "types.dart";

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
  final _injectableInfo = new HashMap<dynamic, ReflectionInfo>();

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

  ReflectionInfo _getReflectionInfo(dynamic typeOrFunc) {
    return _injectableInfo[typeOrFunc];
  }

  bool _containsReflectionInfo(dynamic typeOrFunc) {
    return _injectableInfo.containsKey(typeOrFunc);
  }
}
