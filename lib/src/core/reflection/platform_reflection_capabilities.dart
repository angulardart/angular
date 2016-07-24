import "types.dart";

abstract class PlatformReflectionCapabilities {
  bool isReflectionEnabled();
  Function factory(Type type);
  List interfaces(Type type);
  List<List> parameters(type);
  List annotations(typeOrFunc);
  Map<String, List> propMetadata(typeOrFunc);
  GetterFn getter(String name);
  SetterFn setter(String name);
  MethodFn method(String name);
  String importUri(Type type);
}
