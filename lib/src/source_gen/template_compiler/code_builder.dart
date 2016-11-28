import 'package:analyzer/dart/ast/ast.dart';
import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/template_compiler/template_compiler_outputs.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:code_builder/code_builder.dart';
import 'package:quiver/strings.dart' as strings;

String buildGeneratedCode(
    TemplateCompilerOutputs outputs, String sourceFile, String libraryName) {
  StringBuffer buffer = new StringBuffer();
  if (strings.isNotEmpty(libraryName)) {
    buffer.writeln('library $libraryName$TEMPLATE_EXTENSION;\n');
  }

  String templateCode = outputs.templatesSource.source;
  var model = outputs.ngDepsModel;

  _writeImportExports(buffer, sourceFile, model, templateCode);

  buffer.write(templateCode);

  var library = new LibraryBuilder();

  if (strings.isNotEmpty(templateCode) && model.reflectables.isNotEmpty) {
    library
        .addMember(model.localMetadataMap as AstBuilder<CompilationUnitMember>);
  }

  model.setupMethod.forEach(library.addMember);

  // TODO(alorenzen): Use scope mapped to imports.
  buffer.write(prettyToSource(library.buildAst()));
  return buffer.toString();
}

void _writeImportExports(StringBuffer buffer, String sourceFile,
    NgDepsModel model, String templateCode) {
  // We need to import & export (see below) the source file.
  List<ImportBuilder> imports = [new ImportModel(uri: sourceFile).asBuilder];

  if (model.reflectables.isNotEmpty) {
    imports.add(new ImportModel(uri: REFLECTOR_IMPORT, prefix: REFLECTOR_PREFIX)
        .asBuilder);
  }

  imports.addAll(model.allImports
      .where((import) =>
          !import.isDeferred && !templateCode.contains(import.asStatement))
      .map((imp) => imp.asBuilder));

  List<ExportBuilder> exports = [new ExportModel(uri: sourceFile).asBuilder];
  exports.addAll(model.exports.map((model) => model.asBuilder));

  var library = new LibraryBuilder()
    ..addDirectives(imports)
    ..addDirectives(exports);
  buffer.write(prettyToSource(library.buildAst()));
}
