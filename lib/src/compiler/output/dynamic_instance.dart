/// Creates an instance of a class in interpretive mode.
abstract class InstanceFactory {
  DynamicInstance createInstance(
      dynamic superClass,
      dynamic clazz,
      List<dynamic> constructorArgs,
      Map<String, dynamic> props,
      Map<String, Function> getters,
      Map<String, Function> methods);
}

/// Dynamic instance created by output interpreter.
abstract class DynamicInstance {
  Map<String, dynamic> get props;
  Map<String, Function> get getters;
  Map<String, dynamic> get methods;
  dynamic get clazz;
}
