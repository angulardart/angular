import 'dart:async';

import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        CompileTypeMetadata;
import 'compiler_utils.dart' show MODULE_SUFFIX;
import 'directive_normalizer.dart' show DirectiveNormalizer;
import 'identifiers.dart';
import 'output/abstract_emitter.dart' show OutputEmitter;
import 'output/output_ast.dart' as o;
import 'style_compiler.dart' show StyleCompiler, StylesCompileResult;
import 'template_ast.dart';
import 'template_parser.dart' show TemplateParser;
import 'view_compiler/view_compiler.dart' show ViewCompiler, ViewCompileResult;

class SourceModule {
  final String moduleUrl;
  final String source;
  SourceModule(this.moduleUrl, this.source);
}

class NormalizedComponentWithViewDirectives {
  CompileDirectiveMetadata component;
  List<CompileDirectiveMetadata> directives;
  List<CompilePipeMetadata> pipes;
  NormalizedComponentWithViewDirectives(
      this.component, this.directives, this.pipes);

  Map<String, dynamic> toJson() => {
        'class': 'NormalizedComponentWithViewDirectives',
        'component': component,
        'directives': directives,
        'pipes': pipes,
      };
}

/// Compiles a view template.
class OfflineCompiler {
  DirectiveNormalizer _directiveNormalizer;
  final TemplateParser _templateParser;
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  OutputEmitter _outputEmitter;
  OfflineCompiler(this._directiveNormalizer, this._templateParser,
      this._styleCompiler, this._viewCompiler, this._outputEmitter);
  Future<CompileDirectiveMetadata> normalizeDirectiveMetadata(
      CompileDirectiveMetadata directive) {
    return _directiveNormalizer.normalizeDirective(directive);
  }

  SourceModule compile(List<NormalizedComponentWithViewDirectives> components) {
    String moduleUrl;
    if (components.isNotEmpty) {
      moduleUrl = _templateModuleUrl(components[0].component.type);
    } else {
      throw new BaseException('No components nor injectorModules given');
    }
    var statements = <o.Statement>[];
    var exportedVars = <String>[];
    components.forEach((componentWithDirs) {
      CompileDirectiveMetadata compMeta = componentWithDirs.component;
      _assertComponent(compMeta);

      // Compile Component View and Embedded templates.
      var compViewFactoryVar = _compileComponent(compMeta,
          componentWithDirs.directives, componentWithDirs.pipes, statements);
      exportedVars.add(compViewFactoryVar);

      // Compile ComponentHost to be able to use dynamic component loader at
      // runtime.
      var hostMeta = createHostComponentMeta(compMeta.type, compMeta.selector,
          compMeta.template.preserveWhitespace);
      var hostViewFactoryVar =
          _compileComponent(hostMeta, [compMeta], [], statements);
      var compFactoryVar = '${compMeta.type.name}NgFactory';

      statements.add(o
          .variable(compFactoryVar)
          .set(o.importExpr(Identifiers.ComponentFactory).instantiate(
              <o.Expression>[
                o.literal(compMeta.selector),
                o.variable(hostViewFactoryVar),
                o.importExpr(compMeta.type),
                o.METADATA_MAP
              ],
              o.importType(
                  Identifiers.ComponentFactory, null, [o.TypeModifier.Const])))
          .toDeclStmt(null, [o.StmtModifier.Final]));
      exportedVars.add(compFactoryVar);
    });
    return _createSourceModule(moduleUrl, statements, exportedVars);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _createSourceModule(_stylesModuleUrl(stylesheetUrl, false),
          _resolveStyleStatements(plainStyles), [plainStyles.stylesVar]),
      _createSourceModule(_stylesModuleUrl(stylesheetUrl, true),
          _resolveStyleStatements(shimStyles), [shimStyles.stylesVar])
    ];
  }

  String _compileComponent(
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      List<o.Statement> targetStatements) {
    var styleResult = _styleCompiler.compileComponent(compMeta);
    List<TemplateAst> parsedTemplate = _templateParser.parse(compMeta,
        compMeta.template.template, directives, pipes, compMeta.type.name);
    var viewResult = _viewCompiler.compileComponent(compMeta, parsedTemplate,
        styleResult, o.variable(styleResult.stylesVar), pipes);
    targetStatements.addAll(_resolveStyleStatements(styleResult));
    targetStatements.addAll(_resolveViewStatements(viewResult));
    return viewResult.viewFactoryVar;
  }

  SourceModule _createSourceModule(String moduleUrl,
      List<o.Statement> statements, List<String> exportedVars) {
    String sourceCode =
        _outputEmitter.emitStatements(moduleUrl, statements, exportedVars);
    return new SourceModule(moduleUrl, sourceCode);
  }
}

List<o.Statement> _resolveViewStatements(ViewCompileResult compileResult) {
  for (var dep in compileResult.dependencies) {
    dep.factoryPlaceholder.moduleUrl = _templateModuleUrl(dep.comp.type);
  }
  return compileResult.statements;
}

List<o.Statement> _resolveStyleStatements(StylesCompileResult compileResult) {
  for (var dep in compileResult.dependencies) {
    dep.valuePlaceholder.moduleUrl =
        _stylesModuleUrl(dep.sourceUrl, dep.isShimmed);
  }
  return compileResult.statements;
}

String _templateModuleUrl(CompileTypeMetadata type) {
  var moduleUrl = type.moduleUrl;
  var urlWithoutSuffix =
      moduleUrl.substring(0, moduleUrl.length - MODULE_SUFFIX.length);
  return '${urlWithoutSuffix}.template${MODULE_SUFFIX}';
}

String _stylesModuleUrl(String stylesheetUrl, bool shim) {
  return shim
      ? '${stylesheetUrl}.shim${MODULE_SUFFIX}'
      : '${stylesheetUrl}${MODULE_SUFFIX}';
}

void _assertComponent(CompileDirectiveMetadata meta) {
  if (!meta.isComponent) {
    throw new BaseException(
        "Could not compile '${meta.type.name}' because it is not a component.");
  }
}
