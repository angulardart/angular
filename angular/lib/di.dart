/// NOTE: As of 2020-08-12, this library is DEPRECATED.
///
/// The actual deprecation notice is on the user-visible import located in
/// //third_party/dart/angular/lib/di.dart, which exports this file.
///
/// See go/angular-di.dart-deprecated.
export 'src/di/injector.dart' show Injector, InjectorFactory;
export 'src/di/injector/runtime.dart' show ReflectiveInjector;
export 'src/meta.dart'
    show
        ClassProvider,
        Component,
        Directive,
        ExistingProvider,
        FactoryProvider,
        GenerateInjector,
        Host,
        Input,
        Inject,
        Injectable,
        Module,
        MultiToken,
        OpaqueToken,
        Optional,
        Output,
        Pipe,
        Provider,
        Self,
        SkipSelf,
        ValueProvider,
        provide,
        noValueProvided;
