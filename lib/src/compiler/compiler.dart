import 'package:angular2/src/core/di.dart' show Provider;
import 'package:angular2/src/core/url_resolver.dart'
    show UrlResolver, DEFAULT_PACKAGE_URL_PROVIDER;
import 'package:angular2/src/facade/lang.dart' show assertionsEnabled;

import 'config.dart' show CompilerConfig;
import 'directive_normalizer.dart' show DirectiveNormalizer;
import 'directive_resolver.dart' show DirectiveResolver;
import 'pipe_resolver.dart' show PipeResolver;
import 'style_compiler.dart' show StyleCompiler;
import 'view_compiler/view_compiler.dart' show ViewCompiler;
import 'view_resolver.dart' show ViewResolver;

export 'package:angular2/src/core/platform_directives_and_pipes.dart'
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;

export 'compile_metadata.dart';
export 'config.dart' show CompilerConfig;
export 'directive_resolver.dart' show DirectiveResolver;
export 'offline_compiler.dart';
export 'pipe_resolver.dart' show PipeResolver;
export 'source_module.dart' show SourceModule;
export 'template_ast.dart';
export 'view_resolver.dart' show ViewResolver;
export 'xhr.dart';

CompilerConfig createCompilerConfig() => new CompilerConfig(
    genDebugInfo: assertionsEnabled(), useLegacyStyleEncapsulation: true);

/// A set of providers that provide `Compiler` and its dependencies to use for
/// template compilation.
const List<dynamic /* Type | Provider | List < dynamic > */ >
    COMPILER_PROVIDERS = const [
  DirectiveNormalizer,
  DEFAULT_PACKAGE_URL_PROVIDER,
  StyleCompiler,
  ViewCompiler,
  const Provider(CompilerConfig,
      useFactory: createCompilerConfig, deps: const []),
  UrlResolver,
  ViewResolver,
  DirectiveResolver,
  PipeResolver
];
