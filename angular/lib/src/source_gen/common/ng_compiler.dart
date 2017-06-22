import 'package:build/build.dart' hide AssetReader;
import 'package:angular/src/compiler/config.dart';
import 'package:angular/src/compiler/directive_normalizer.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart' as ng;
import 'package:angular/src/compiler/expression_parser/parser.dart' as ng;
import 'package:angular/src/compiler/html_parser.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular/src/compiler/style_compiler.dart';
import 'package:angular/src/compiler/template_parser.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular/src/core/url_resolver.dart';

import 'xhr_impl.dart';

OfflineCompiler createTemplateCompiler(
    BuildStep buildStep, CompilerConfig compilerConfig) {
  var reader = new XhrImpl(buildStep);
  var urlResolver = createOfflineCompileUrlResolver();

  // TODO(yjbanov): add router AST transformer when ready
  var parser = new ng.Parser(new ng.Lexer());
  var htmlParser = new HtmlParser();

  var templateParser =
      new TemplateParser(parser, new DomElementSchemaRegistry(), htmlParser);
  return new OfflineCompiler(
      new DirectiveNormalizer(reader, urlResolver, htmlParser),
      templateParser,
      new StyleCompiler(compilerConfig, urlResolver),
      new ViewCompiler(compilerConfig, parser),
      new DartEmitter(), {});
}
