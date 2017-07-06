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
import 'package:angular_compiler/angular_compiler.dart';

import 'asset_reader.dart';
import 'url_resolver.dart';
import 'xhr_impl.dart';

OfflineCompiler createTemplateCompiler(
    AssetReader reader, CompilerFlags flags) {
  var xhr = new XhrImpl(reader);
  var urlResolver = createOfflineCompileUrlResolver();

  // TODO(yjbanov): add router AST transformer when ready
  var parser = new ng.Parser(new ng.Lexer());
  var htmlParser = new HtmlParser();
  var schemaRegistry = new DomElementSchemaRegistry();

  var templateParser = new TemplateParser(parser, schemaRegistry, htmlParser);

  return new OfflineCompiler(
      new DirectiveNormalizer(xhr, urlResolver, htmlParser),
      templateParser,
      new StyleCompiler(flags, urlResolver),
      new ViewCompiler(flags, parser, schemaRegistry),
      new DartEmitter(), {});
}
