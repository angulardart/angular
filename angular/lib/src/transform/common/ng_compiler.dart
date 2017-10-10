import 'package:angular/src/compiler/ast_template_parser.dart';
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

OfflineCompiler createTemplateCompiler(
  NgAssetReader reader,
  CompilerFlags flags,
) {
  final parser = new ng.Parser(new ng.Lexer());
  final htmlParser = new HtmlParser();
  final schemaRegistry = new DomElementSchemaRegistry();
  final templateParser = flags.useAstPkg
      ? new AstTemplateParser(schemaRegistry, parser)
      : new TemplateParserImpl(parser, schemaRegistry, htmlParser);
  return new OfflineCompiler(
      new DirectiveNormalizer(htmlParser, reader),
      templateParser,
      new StyleCompiler(flags),
      new ViewCompiler(flags, parser, schemaRegistry),
      new DartEmitter(), {});
}
