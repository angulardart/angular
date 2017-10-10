import 'compile_metadata.dart';
import 'schema/element_schema_registry.dart';
import 'template_ast.dart';
import 'template_parser.dart';

/// A [TemplateParser] which uses the `angular_ast` package to parse angular
/// templates.
class AstTemplateParser implements TemplateParser {
  @override
  final ElementSchemaRegistry schemaRegistry;

  AstTemplateParser(this.schemaRegistry);

  @override
  List<TemplateAst> parse(
      CompileDirectiveMetadata compMeta,
      String template,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      String name) {
    throw new UnimplementedError();
  }
}
