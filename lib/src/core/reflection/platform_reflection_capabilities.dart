library angular2.src.core.reflection.platform_reflection_capabilities;

import "package:angular2/src/facade/lang.dart" show Type;

import "types.dart" show GetterFn, SetterFn, MethodFn;

abstract class PlatformReflectionCapabilities {
  bool isReflectionEnabled();
  Function factory(Type type);
  List interfaces(Type type);
  List<List> parameters(dynamic type);
  List annotations(dynamic type);
  Map<String, List> propMetadata(dynamic typeOrFunc);
  GetterFn getter(String name);
  SetterFn setter(String name);
  MethodFn method(String name);
  String importUri(Type type);
}
