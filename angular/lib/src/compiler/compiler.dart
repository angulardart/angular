import 'package:angular/src/core/url_resolver.dart'
    show UrlResolver, DEFAULT_PACKAGE_URL_PROVIDER;

export 'package:angular/src/core/platform_directives_and_pipes.dart'
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;

export 'compile_metadata.dart';
export 'offline_compiler.dart';
export 'source_module.dart' show SourceModule;
export 'template_ast.dart';

/// A set of providers that provide `Compiler` and its dependencies to use for
/// template compilation.
const List<dynamic> COMPILER_PROVIDERS = const [
  DEFAULT_PACKAGE_URL_PROVIDER,
  UrlResolver,
];
