/**
 * 
 * 
 * The `di` module provides dependency injection container services.
 */
library angular2.src.core.di;

export "di/metadata.dart"
    show
        InjectMetadata,
        OptionalMetadata,
        InjectableMetadata,
        SelfMetadata,
        HostMetadata,
        SkipSelfMetadata,
        DependencyMetadata;
// we have to reexport * because Dart and TS export two different sets of types
export "di/decorators.dart";
export "di/forward_ref.dart" show forwardRef, resolveForwardRef, ForwardRefFn;
export "di/injector.dart" show Injector, InjectorFactory;
export "di/reflective_injector.dart" show ReflectiveInjector;
export "di/provider.dart"
    show Binding, ProviderBuilder, bind, Provider, provide;
export "di/reflective_provider.dart"
    show
        ResolvedReflectiveBinding,
        ResolvedReflectiveFactory,
        ReflectiveDependency,
        ResolvedReflectiveProvider;
export "di/reflective_key.dart" show ReflectiveKey;
export "di/reflective_exceptions.dart"
    show
        NoProviderError,
        AbstractProviderError,
        CyclicDependencyError,
        InstantiationError,
        InvalidProviderError,
        NoAnnotationError,
        OutOfBoundsError;
export "di/opaque_token.dart" show OpaqueToken;
export "di/map_injector.dart" show MapInjector, MapInjectorFactory;
