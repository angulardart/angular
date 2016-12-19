import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/template_compiler/template_compiler_outputs.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/src/tokens.dart';
import 'package:quiver/strings.dart' as strings;

String buildGeneratedCode(
    TemplateCompilerOutputs outputs, String sourceFile, String libraryName) {
  StringBuffer buffer = new StringBuffer();
  if (strings.isNotEmpty(libraryName)) {
    buffer.writeln('library $libraryName$TEMPLATE_EXTENSION;\n');
  }

  String templateCode = outputs.templatesSource.source;
  var model = outputs.ngDepsModel;

  var scope = new _NgScope(model);

  _writeImportExports(buffer, sourceFile, model, templateCode, scope);

  buffer.write(templateCode);

  var library = new LibraryBuilder.scope(scope: scope);

  if (strings.isNotEmpty(templateCode) && model.reflectables.isNotEmpty) {
    library
        .addMember(model.localMetadataMap as AstBuilder<CompilationUnitMember>);
  }

  model.setupMethod.forEach(library.addMember);

  buffer.write(prettyToSource(library.buildAst()));
  return buffer.toString();
}

void _writeImportExports(StringBuffer buffer, String sourceFile,
    NgDepsModel model, String templateCode, _NgScope scope) {
  // We need to import & export (see below) the source file.
  scope.addPrefixImport(sourceFile, '');
  List<ImportBuilder> imports = [new ImportModel(uri: sourceFile).asBuilder];

  if (model.reflectables.isNotEmpty) {
    scope.addPrefixImport(REFLECTOR_IMPORT, REFLECTOR_PREFIX);
    imports.add(new ImportModel(uri: REFLECTOR_IMPORT, prefix: REFLECTOR_PREFIX)
        .asBuilder);
  }

  // TODO(alorenzen): Once templateCompiler uses code_builder, handle this
  // completely in scope.
  imports.addAll(model.imports
      .where((import) =>
          !import.isDeferred && !templateCode.contains(import.asStatement))
      .map((imp) => imp.asBuilder));

  // This is primed with model.depImports, and sets the prefix accordingly.
  imports.addAll(scope.incrementingScope.toImports());

  List<ExportBuilder> exports = [new ExportModel(uri: sourceFile).asBuilder];
  exports.addAll(model.exports.map((model) => model.asBuilder));

  var library = new LibraryBuilder.scope(scope: scope)
    ..addDirectives(imports)
    ..addDirectives(exports);
  buffer.write(prettyToSource(library.buildAst()));
}

/// A custom [Scope] which simply delegates to other scopes based on where the
/// import came from.
class _NgScope implements Scope {
  final Map<String, Scope> _delegateScope = {};
  final _PrefixScope _prefixScope = new _PrefixScope();
  final Scope incrementingScope = new Scope();

  _NgScope(NgDepsModel model) {
    for (var import in model.depImports) {
      // Prime cache so that scope.toImports() will return.
      incrementingScope.identifier('', import.uri);
      _delegateScope[import.uri] = incrementingScope;
    }

    for (var import in model.imports) {
      _prefixScope.addImport(import.uri, import.prefix);
      _delegateScope[import.uri] = _prefixScope;
    }
  }

  void addPrefixImport(String uri, String prefix) {
    _prefixScope.addImport(uri, prefix);
    _delegateScope[uri] = _prefixScope;
  }

  @override
  Identifier identifier(String name, [String importFrom]) {
    if (importFrom == null) {
      return Scope.identity.identifier(name, importFrom);
    }
    var scope = _delegateScope.putIfAbsent(importFrom, () => Scope.identity);
    return scope.identifier(name, importFrom);
  }

  // For now, we handle imports separately from the rest of the generated code.
  // Otherwise, we would add the import statements after the output from the
  // template compiler.
  @override
  List<ImportBuilder> toImports() => const [];
}

/// A [Scope] which uses a prefix if one has already been set, otherwise none.
class _PrefixScope implements Scope {
  final Map<String, String> _prefixes = {};

  void addImport(String uri, String prefix) {
    _prefixes[uri] = prefix;
  }

  @override
  Identifier identifier(String name, String importFrom) {
    if (importFrom == null) {
      return Scope.identity.identifier(name, importFrom);
    }
    var prefix = _prefixes.putIfAbsent(importFrom, () => '');
    return astFactory.prefixedIdentifier(
      Scope.identity.identifier(prefix, null),
      $period,
      Scope.identity.identifier(name, null),
    );
  }

  @override
  List<ImportBuilder> toImports() => const [];
}
