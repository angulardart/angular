export "src/compiler/url_resolver.dart" show UrlResolver;
export "src/core/di.dart" hide MapInjector, MapInjectorFactory;
export "src/core/change_detection/pipe_transform.dart";
export "src/core/metadata.dart" show Component, Directive, Input, Output;
// TODO: move pipes into separate library target.
export "src/core/metadata.dart" show Pipe;
export "src/core/testability/testability.dart";
export "src/core/zone/ng_zone.dart";
// TODO: remove ExceptionHandler and WrappedException after deprecation.
export "src/facade/facade.dart"
    show EventEmitter, ExceptionHandler, WrappedException;
