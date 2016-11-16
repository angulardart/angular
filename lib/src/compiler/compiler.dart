import "package:angular2/src/compiler/directive_normalizer.dart"
    show DirectiveNormalizer;
import "package:angular2/src/compiler/html_parser.dart" show HtmlParser;
import "package:angular2/src/compiler/runtime_metadata.dart"
    show RuntimeMetadataResolver;
import "package:angular2/src/compiler/schema/dom_element_schema_registry.dart"
    show DomElementSchemaRegistry;
import "package:angular2/src/compiler/schema/element_schema_registry.dart"
    show ElementSchemaRegistry;
import "package:angular2/src/compiler/style_compiler.dart" show StyleCompiler;
import "package:angular2/src/compiler/template_parser.dart" show TemplateParser;
import "package:angular2/src/compiler/url_resolver.dart"
    show UrlResolver, DEFAULT_PACKAGE_URL_PROVIDER;
import "package:angular2/src/compiler/view_compiler/view_compiler.dart"
    show ViewCompiler;
import "package:angular2/src/core/di.dart" show Provider;
import "package:angular2/src/facade/lang.dart" show assertionsEnabled;

import "config.dart" show CompilerConfig;
import "directive_resolver.dart" show DirectiveResolver;
import "expression_parser/lexer.dart" show Lexer;
import "expression_parser/parser.dart" show Parser;
import "pipe_resolver.dart" show PipeResolver;
import "view_resolver.dart" show ViewResolver;

export "package:angular2/src/compiler/template_ast.dart";
export "package:angular2/src/compiler/url_resolver.dart";
export "package:angular2/src/compiler/xhr.dart";
export "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;

export "compile_metadata.dart";
export "config.dart" show CompilerConfig;
export "directive_resolver.dart" show DirectiveResolver;
export "offline_compiler.dart";
export "pipe_resolver.dart" show PipeResolver;
export "view_resolver.dart" show ViewResolver;

CompilerConfig createCompilerConfig() {
  return new CompilerConfig(assertionsEnabled(), false, true);
}

/// A set of providers that provide `Compiler` and its dependencies to use for
/// template compilation.
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
  const Provider(CompilerConfig,
      useFactory: createCompilerConfig, deps: const []),
  DomElementSchemaRegistry,
  const Provider(ElementSchemaRegistry, useExisting: DomElementSchemaRegistry),
  UrlResolver,
  ViewResolver,
  DirectiveResolver,
  PipeResolver
];
