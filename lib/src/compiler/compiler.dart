library angular2.src.compiler.compiler;

export "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;
export "package:angular2/src/compiler/template_ast.dart";
export "package:angular2/src/compiler/template_parser.dart"
    show TEMPLATE_TRANSFORMS;
export "config.dart" show CompilerConfig, RenderTypes;
export "compile_metadata.dart";
export "offline_compiler.dart";
export "runtime_compiler.dart" show RuntimeCompiler;
export "package:angular2/src/compiler/url_resolver.dart";
export "package:angular2/src/compiler/xhr.dart";
export "view_resolver.dart" show ViewResolver;
export "directive_resolver.dart" show DirectiveResolver;
export "pipe_resolver.dart" show PipeResolver;
import "package:angular2/src/facade/lang.dart" show assertionsEnabled;
import "package:angular2/src/core/di.dart" show Provider;
import "package:angular2/src/compiler/template_parser.dart" show TemplateParser;
import "package:angular2/src/compiler/html_parser.dart" show HtmlParser;
import "package:angular2/src/compiler/directive_normalizer.dart"
    show DirectiveNormalizer;
import "package:angular2/src/compiler/runtime_metadata.dart"
    show RuntimeMetadataResolver;
import "package:angular2/src/compiler/style_compiler.dart" show StyleCompiler;
import "package:angular2/src/compiler/view_compiler/view_compiler.dart"
    show ViewCompiler;
import "package:angular2/src/compiler/view_compiler/injector_compiler.dart"
    show InjectorCompiler;
import "config.dart" show CompilerConfig;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver;
import "package:angular2/src/compiler/runtime_compiler.dart"
    show RuntimeCompiler;
import "package:angular2/src/compiler/schema/element_schema_registry.dart"
    show ElementSchemaRegistry;
import "package:angular2/src/compiler/schema/dom_element_schema_registry.dart"
    show DomElementSchemaRegistry;
import "package:angular2/src/compiler/url_resolver.dart"
    show UrlResolver, DEFAULT_PACKAGE_URL_PROVIDER;
import "expression_parser/parser.dart" show Parser;
import "expression_parser/lexer.dart" show Lexer;
import "view_resolver.dart" show ViewResolver;
import "directive_resolver.dart" show DirectiveResolver;
import "pipe_resolver.dart" show PipeResolver;

CompilerConfig createCompilerConfig() {
  return new CompilerConfig(assertionsEnabled(), false, true);
}

/**
 * A set of providers that provide `RuntimeCompiler` and its dependencies to use for
 * template compilation.
 */
const List<dynamic /* Type | Provider | List < dynamic > */ >
    COMPILER_PROVIDERS = const [
  Lexer,
  Parser,
  HtmlParser,
  TemplateParser,
  DirectiveNormalizer,
  RuntimeMetadataResolver,
  DEFAULT_PACKAGE_URL_PROVIDER,
  StyleCompiler,
  ViewCompiler,
  InjectorCompiler,
  const Provider(CompilerConfig,
      useFactory: createCompilerConfig, deps: const []),
  RuntimeCompiler,
  const Provider(ComponentResolver, useExisting: RuntimeCompiler),
  DomElementSchemaRegistry,
  const Provider(ElementSchemaRegistry, useExisting: DomElementSchemaRegistry),
  UrlResolver,
  ViewResolver,
  DirectiveResolver,
  PipeResolver
];
