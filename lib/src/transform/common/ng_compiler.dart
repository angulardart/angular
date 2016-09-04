import 'package:angular2/router/router_link_dsl.dart';
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
import 'package:angular2/src/compiler/view_compiler/injector_compiler.dart';
import 'package:angular2/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular2/src/core/console.dart';
import 'package:angular2/src/transform/common/asset_reader.dart';

import 'logging.dart' as logging;
import 'url_resolver.dart';
import 'xhr_impl.dart';

/// Implementation of [Console] for transformers.
class _LoggerConsole implements Console {
  @override
  void log(String message) {
    logging.log.info(message);
  }

  @override
  void warn(String message) {
    logging.log.warning(message);
  }
}

OfflineCompiler createTemplateCompiler(AssetReader reader,
    {CompilerConfig compilerConfig}) {
  var xhr = new XhrImpl(reader);
  var urlResolver = createOfflineCompileUrlResolver();

  // TODO(yjbanov): add router AST transformer when ready
  var parser = new ng.Parser(new ng.Lexer());
  var htmlParser = new HtmlParser();

  var templateParser = new TemplateParser(
      parser,
      new DomElementSchemaRegistry(),
      htmlParser,
      new _LoggerConsole(),
      [new RouterLinkTransform(parser)]);

  return new OfflineCompiler(
      new DirectiveNormalizer(xhr, urlResolver, htmlParser),
      templateParser,
      new StyleCompiler(urlResolver),
      new ViewCompiler(compilerConfig),
      new InjectorCompiler(),
      new DartEmitter());
}
