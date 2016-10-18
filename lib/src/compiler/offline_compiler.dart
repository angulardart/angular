import 'dart:async';

import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'compile_metadata.dart'
    show
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        CompileInjectorModuleMetadata,
        CompileTypeMetadata;
import 'compiler_utils.dart' show MODULE_SUFFIX;
import 'directive_normalizer.dart' show DirectiveNormalizer;
import 'identifiers.dart';
import 'output/abstract_emitter.dart' show OutputEmitter;
import 'output/output_ast.dart' as o;
import 'style_compiler.dart' show StyleCompiler, StylesCompileResult;
import 'template_parser.dart' show TemplateParser;
import 'view_compiler/injector_compiler.dart' show InjectorCompiler;
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
}

/// Compiles a view template.
class OfflineCompiler {
  DirectiveNormalizer _directiveNormalizer;
  final TemplateParser _templateParser;
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  InjectorCompiler _injectorCompiler;
  OutputEmitter _outputEmitter;
  OfflineCompiler(
      this._directiveNormalizer,
      this._templateParser,
      this._styleCompiler,
      this._viewCompiler,
      this._injectorCompiler,
      this._outputEmitter);
  Future<CompileDirectiveMetadata> normalizeDirectiveMetadata(
      CompileDirectiveMetadata directive) {
    return _directiveNormalizer.normalizeDirective(directive);
  }

  SourceModule compile(List<NormalizedComponentWithViewDirectives> components,
      List<CompileInjectorModuleMetadata> injectorModules) {
    String moduleUrl;
    if (components.isNotEmpty) {
      moduleUrl = _templateModuleUrl(components[0].component.type);
    } else if (injectorModules.isNotEmpty) {
      moduleUrl = _templateModuleUrl(injectorModules[0].type);
    } else {
      throw new BaseException('No components nor injectorModules given');
    }
    var statements = <o.Statement>[];
    var exportedVars = <String>[];
    components.forEach((componentWithDirs) {
      CompileDirectiveMetadata compMeta = componentWithDirs.component;
      _assertComponent(compMeta);
      var compViewFactoryVar = _compileComponent(compMeta,
          componentWithDirs.directives, componentWithDirs.pipes, statements);
      exportedVars.add(compViewFactoryVar);
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
    injectorModules.forEach((injectorModuleMeta) {
      var compileResult = _injectorCompiler.compileInjector(injectorModuleMeta);
      compileResult.statements.forEach((stmt) => statements.add(stmt));
      exportedVars.add(compileResult.injectorFactoryVar);
    });
    return _codegenSourceModule(moduleUrl, statements, exportedVars);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        _styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      _codegenSourceModule(_stylesModuleUrl(stylesheetUrl, false),
          _resolveStyleStatements(plainStyles), [plainStyles.stylesVar]),
      _codegenSourceModule(_stylesModuleUrl(stylesheetUrl, true),
          _resolveStyleStatements(shimStyles), [shimStyles.stylesVar])
    ];
  }

  String _compileComponent(
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      List<o.Statement> targetStatements) {
    var styleResult = _styleCompiler.compileComponent(compMeta);
    var parsedTemplate = _templateParser.parse(compMeta,
        compMeta.template.template, directives, pipes, compMeta.type.name);
    var viewResult = _viewCompiler.compileComponent(compMeta, parsedTemplate,
        styleResult, o.variable(styleResult.stylesVar), pipes);
    targetStatements.addAll(_resolveStyleStatements(styleResult));
    targetStatements.addAll(_resolveViewStatements(viewResult));
    return viewResult.viewFactoryVar;
  }

  SourceModule _codegenSourceModule(String moduleUrl,
      List<o.Statement> statements, List<String> exportedVars) {
    return new SourceModule(
        moduleUrl,
        this
            ._outputEmitter
            .emitStatements(moduleUrl, statements, exportedVars));
  }
}

List<o.Statement> _resolveViewStatements(ViewCompileResult compileResult) {
  compileResult.dependencies.forEach((dep) {
    dep.factoryPlaceholder.moduleUrl = _templateModuleUrl(dep.comp.type);
  });
  return compileResult.statements;
}

List<o.Statement> _resolveStyleStatements(StylesCompileResult compileResult) {
  compileResult.dependencies.forEach((dep) {
    dep.valuePlaceholder.moduleUrl =
        _stylesModuleUrl(dep.sourceUrl, dep.isShimmed);
  });
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
