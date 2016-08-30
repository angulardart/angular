export "package:angular2/src/core/di/decorators.dart";
export "package:angular2/src/core/di/injector.dart"
    show Injector, InjectorFactory;
export "package:angular2/src/core/di/reflective_injector.dart"
    show ReflectiveInjector;
export "package:angular2/src/core/di/provider.dart"
    show Provider, provide, noValueProvided;
export "package:angular2/src/core/di/reflective_provider.dart"
    show
        ResolvedReflectiveBinding,
        ResolvedReflectiveFactory,
        ReflectiveDependency,
        ResolvedReflectiveProvider;
export "package:angular2/src/core/di/reflective_key.dart" show ReflectiveKey;
export "package:angular2/src/core/di/reflective_exceptions.dart"
    show
        NoProviderError,
        AbstractProviderError,
        CyclicDependencyError,
        InstantiationError,
        InvalidProviderError,
        NoAnnotationError,
        OutOfBoundsError;
export "package:angular2/src/core/di/opaque_token.dart" show OpaqueToken;
export "package:angular2/src/core/testability/testability.dart";
// TODO: remove after deprecation.
export "package:angular2/src/facade/exception_handler.dart"
    show ExceptionHandler;
export 'package:angular2/src/core/zone/ng_zone.dart';
export "package:angular2/src/core/change_detection/pipe_transform.dart";
export 'package:angular2/src/core/metadata.dart'
    show Component, Directive, Input, Output;
// TODO: move pipes into separate library target.
export "package:angular2/src/core/metadata.dart" show Pipe;
// TODO: Remove after usage is deprecated.
export "package:angular2/src/facade/exceptions.dart" show WrappedException;
export "package:angular2/src/facade/async.dart" show EventEmitter;
export "package:angular2/src/compiler/url_resolver.dart" show UrlResolver;
