import 'package:build/build.dart' hide AssetReader;
import 'package:angular/src/compiler/ast_template_parser.dart';
import 'package:angular/src/compiler/directive_normalizer.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart' as ng;
import 'package:angular/src/compiler/expression_parser/parser.dart' as ng;
import 'package:angular/src/compiler/html_parser.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular/src/compiler/style_compiler.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

OfflineCompiler createTemplateCompiler(
    BuildStep buildStep, CompilerFlags flags) {
  var parser = new ng.Parser(new ng.Lexer());
  var htmlParser = new HtmlParser();
  var schemaRegistry = new DomElementSchemaRegistry();
  var templateParser = new AstTemplateParser(schemaRegistry, parser, flags);
  final reader = new NgAssetReader.fromBuildStep(buildStep);
  return new OfflineCompiler(
      new DirectiveNormalizer(htmlParser, reader),
      templateParser,
      new StyleCompiler(flags),
      new ViewCompiler(flags, parser, schemaRegistry),
      new DartEmitter(), {});
}
