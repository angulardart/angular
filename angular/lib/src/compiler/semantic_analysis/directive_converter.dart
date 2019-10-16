import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/analyzed_class.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/expression_parser/ast.dart' as ast;
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/parse_util.dart';
import 'package:angular/src/compiler/schema/element_schema_registry.dart';
import 'package:angular/src/compiler/semantic_analysis/binding_converter.dart';
import 'package:angular/src/compiler/template_ast.dart' as ast;
import 'package:angular/src/compiler/template_parser.dart';
import 'package:angular_compiler/cli.dart';

/// Converts [CompileDirectiveMetadata] objects into
/// [ir.Directive] instances.
///
/// This is part of the semantic analysis phase of the Angular compiler.
class DirectiveConverter {
  final ElementSchemaRegistry _schemaRegistry;

  DirectiveConverter(this._schemaRegistry);

  ir.Directive convertDirectiveToIR(CompileDirectiveMetadata directiveMeta) =>
      ir.Directive(
        name: directiveMeta.identifier.name,
        typeParameters: directiveMeta.originType.typeParameters,
        hostProperties: _hostProperties(
            directiveMeta.hostProperties, directiveMeta.analyzedClass),
        metadata: directiveMeta,
      );

  List<ir.Binding> _hostProperties(
      Map<String, ast.AST> hostProps, AnalyzedClass analyzedClass) {
    // TODO(b/130184376): Create better HostProperties representation in
    //  CompileMetadata.
    final hostProperties = hostProps.entries.map((entry) {
      final property = entry.key;
      final expression = entry.value;
      return createElementPropertyAst(
        _securityContextElementName,
        property,
        ast.BoundExpression(ast.ASTWithSource.missingSource(expression)),
        _emptySpan,
        _schemaRegistry,
        _reportError,
      );
    }).toList();

    return convertAllToBinding(hostProperties, analyzedClass: analyzedClass);
  }

  static void _reportError(
    String message,
    SourceSpan sourceSpan, [
    ParseErrorLevel level,
  ]) {
    if (level == ParseErrorLevel.FATAL) {
      throwFailure(message);
    } else {
      logWarning(message);
    }
  }

  static const _securityContextElementName = 'div';
  static final _emptySpan = SourceSpan(
    SourceLocation(0),
    SourceLocation(0),
    '',
  );
}
