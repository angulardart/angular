import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/directive_normalizer.dart';
import 'package:angular2/src/compiler/expression_parser/lexer.dart' as ng;
import 'package:angular2/src/compiler/expression_parser/parser.dart' as ng;
import 'package:angular2/src/compiler/html_parser.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/compiler/output/dart_emitter.dart';
import 'package:angular2/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular2/src/compiler/style_compiler.dart';
import 'package:angular2/src/compiler/template_parser.dart';
import 'package:angular2/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular2/src/transform/common/asset_reader.dart';

import 'url_resolver.dart';
import 'xhr_impl.dart';

OfflineCompiler createTemplateCompiler(AssetReader reader,
    {CompilerConfig compilerConfig}) {
  var xhr = new XhrImpl(reader);
  var urlResolver = createOfflineCompileUrlResolver();

  // TODO(yjbanov): add router AST transformer when ready
  var parser = new ng.Parser(new ng.Lexer());
  var htmlParser = new HtmlParser();

  var templateParser =
      new TemplateParser(parser, new DomElementSchemaRegistry(), htmlParser);

  return new OfflineCompiler(
      new DirectiveNormalizer(xhr, urlResolver, htmlParser),
      templateParser,
      new StyleCompiler(urlResolver),
      new ViewCompiler(compilerConfig),
      new DartEmitter());
}
