abstract class InstanceFactory {
  DynamicInstance createInstance(
      dynamic superClass,
      dynamic clazz,
      List<dynamic> constructorArgs,
      Map<String, dynamic> props,
      Map<String, Function> getters,
      Map<String, Function> methods);
}

abstract class DynamicInstance {
  Map<String, dynamic> get props;

  Map<String, Function> get getters;

  Map<String, dynamic> get methods;

  dynamic get clazz;
}

dynamic isDynamicInstance(dynamic instance) {
  return instance is DynamicInstance;
}
