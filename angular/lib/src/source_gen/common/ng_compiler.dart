import 'package:build/build.dart' hide AssetReader;
import 'package:angular/src/compiler/angular_compiler.dart';
import 'package:angular/src/compiler/ast_directive_normalizer.dart';
import 'package:angular/src/compiler/semantic_analysis/directive_converter.dart';
import 'package:angular/src/compiler/template_parser/ast_template_parser.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart' as ng;
import 'package:angular/src/compiler/expression_parser/parser.dart' as ng;
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/compiler/output/dart_emitter.dart';
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular/src/compiler/stylesheet_compiler/style_compiler.dart';
import 'package:angular/src/compiler/view_compiler/directive_compiler.dart';
import 'package:angular/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

AngularCompiler createAngularCompiler(
    BuildStep buildStep, CompilerFlags flags) {
  final schemaRegistry = DomElementSchemaRegistry();
  final parser = ng.Parser(ng.Lexer());
  return AngularCompiler(
      OfflineCompiler(
        DirectiveCompiler(),
        StyleCompiler(flags),
        ViewCompiler(flags, parser, schemaRegistry),
        DartEmitter(),
        {},
      ),
      AstDirectiveNormalizer(NgAssetReader.fromBuildStep(buildStep)),
      DirectiveConverter(schemaRegistry),
      AstTemplateParser(schemaRegistry, parser, flags));
}

OfflineCompiler createOfflineCompiler(
  BuildStep buildStep,
  CompilerFlags flags,
) {
  final schemaRegistry = DomElementSchemaRegistry();
  return OfflineCompiler(
    DirectiveCompiler(),
    StyleCompiler(flags),
    ViewCompiler(flags, ng.Parser(ng.Lexer()), schemaRegistry),
    DartEmitter(),
    {},
  );
}
