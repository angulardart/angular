import 'package:build/build.dart' hide AssetReader;
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/angular_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/ast_directive_normalizer.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/parser.dart'
    as ng;
import 'package:angular_compiler/v1/src/compiler/output/dart_emitter.dart';
import 'package:angular_compiler/v1/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular_compiler/v1/src/compiler/semantic_analysis/directive_converter.dart';
import 'package:angular_compiler/v1/src/compiler/stylesheet_compiler/style_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/template_parser/ast_template_parser.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/directive_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/view_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

/// Creates the elements necessary to parse HTML templates and compile them.
AngularCompiler createTemplateCompiler(
  BuildStep buildStep,
  CompilerFlags flags,
) {
  // Historically, this function was backed by dependency injection at
  // compile-time. In practice today these elements are rarely overriden or only
  // are during specific unit tests.
  final schemaRegistry = DomElementSchemaRegistry();
  final parser = ng.ExpressionParser();
  return AngularCompiler(
    TemplateCompiler(
      DirectiveCompiler(),
      StyleCompiler(flags),
      ViewCompiler(flags, parser, schemaRegistry),
      DartEmitter(
        emitNullSafeSyntax: CompileContext.current.emitNullSafeCode,
      ),
    ),
    AstDirectiveNormalizer(NgAssetReader.fromBuildStep(buildStep)),
    DirectiveConverter(schemaRegistry),
    AstTemplateParser(schemaRegistry, parser, flags),
    buildStep.resolver,
  );
}

/// Creates the elements necessary to implement view classes.
///
/// **NOTE**: This is seperate from [createTemplateCompiler], because some of
/// the functionality provided by [TemplateViewCompiler] is currently used by
/// other sub-systems, such as the stylesheet compiler.
TemplateCompiler createViewCompiler(
  BuildStep buildStep,
  CompilerFlags flags,
) {
  final schemaRegistry = DomElementSchemaRegistry();
  return TemplateCompiler(
    DirectiveCompiler(),
    StyleCompiler(flags),
    ViewCompiler(flags, ng.ExpressionParser(), schemaRegistry),
    DartEmitter(),
  );
}
