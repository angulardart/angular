import 'src/core/reflection/reflection_capabilities.dart';
import 'src/core/reflection/reflection.dart';

/// Setup Angular to use runtime (`dart:mirrors`-based) reflection.
///
/// This is required when:
///
/// 1. You are using `TestComponentBuilder` or other old testing infrastructure
///    that does not support code generation. We are gradually moving to a
///    code-generation-only testing model, but this is not deprecated yet.
///
/// 2. **Deprecated**: You are relying on runtime reflection for your
///    development cycle inside of Dartium, and use pub transformers at build
///    time to replace them with code generation. All development should be done
///    using code generation or a bug should be filed.
void allowRuntimeReflection() {
  reflector.reflectionCapabilities = new ReflectionCapabilities();
}

/// Whether [allowRuntimeReflection] has been previously used.
bool get isReflectionEnabled {
  return reflector.reflectionCapabilities is! NoReflectionCapabilities;
}
