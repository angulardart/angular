import 'package:build/build.dart' hide AssetReader;
import 'package:angular/src/compiler/ast_directive_normalizer.dart';
import 'package:angular/src/compiler/ast_template_parser.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart' as ng;
import 'package:angular/src/compiler/expression_parser/parser.dart' as ng;
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular/src/compiler/style_compiler.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

OfflineCompiler createTemplateCompiler(
  BuildStep buildStep,
  CompilerFlags flags,
) {
  final reader = NgAssetReader.fromBuildStep(buildStep);
  final parser = ng.Parser(ng.Lexer());
  final schemaRegistry = DomElementSchemaRegistry();
  final templateParser = AstTemplateParser(schemaRegistry, parser, flags);
  return OfflineCompiler(
    AstDirectiveNormalizer(reader),
    templateParser,
    StyleCompiler(flags),
    ViewCompiler(flags, parser, schemaRegistry),
    DartEmitter(),
    {},
  );
}
