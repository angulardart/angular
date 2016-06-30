library angular2.src.compiler.offline_compiler;

import "dart:async";
import "compile_metadata.dart"
    show
        CompileDirectiveMetadata,
        CompileIdentifierMetadata,
        CompilePipeMetadata,
        createHostComponentMeta,
        CompileInjectorModuleMetadata,
        CompileTypeMetadata;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, unimplemented;
import "package:angular2/src/facade/collection.dart" show ListWrapper;
import "style_compiler.dart"
    show StyleCompiler, StylesCompileDependency, StylesCompileResult;
import "view_compiler/view_compiler.dart" show ViewCompiler, ViewCompileResult;
import "view_compiler/injector_compiler.dart"
    show InjectorCompiler, InjectorCompileResult;
import "template_parser.dart" show TemplateParser;
import "directive_normalizer.dart" show DirectiveNormalizer;
import "output/abstract_emitter.dart" show OutputEmitter;
import "output/output_ast.dart" as o;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "util.dart" show MODULE_SUFFIX;

var _COMPONENT_FACTORY_IDENTIFIER = new CompileIdentifierMetadata(
    name: "ComponentFactory",
    runtime: ComponentFactory,
    moduleUrl:
        '''asset:angular2/lib/src/core/linker/component_factory${ MODULE_SUFFIX}''');

class SourceModule {
  String moduleUrl;
  String source;
  SourceModule(this.moduleUrl, this.source) {}
}

class NormalizedComponentWithViewDirectives {
  CompileDirectiveMetadata component;
  List<CompileDirectiveMetadata> directives;
  List<CompilePipeMetadata> pipes;
  NormalizedComponentWithViewDirectives(
      this.component, this.directives, this.pipes) {}
}

class OfflineCompiler {
  DirectiveNormalizer _directiveNormalizer;
  TemplateParser _templateParser;
  StyleCompiler _styleCompiler;
  ViewCompiler _viewCompiler;
  InjectorCompiler _injectorCompiler;
  OutputEmitter _outputEmitter;
  OfflineCompiler(
      this._directiveNormalizer,
      this._templateParser,
      this._styleCompiler,
      this._viewCompiler,
      this._injectorCompiler,
      this._outputEmitter) {}
  Future<CompileDirectiveMetadata> normalizeDirectiveMetadata(
      CompileDirectiveMetadata directive) {
    return this._directiveNormalizer.normalizeDirective(directive);
  }

  SourceModule compile(List<NormalizedComponentWithViewDirectives> components,
      List<CompileInjectorModuleMetadata> injectorModules) {
    String moduleUrl;
    if (components.length > 0) {
      moduleUrl = _templateModuleUrl(components[0].component.type);
    } else if (injectorModules.length > 0) {
      moduleUrl = _templateModuleUrl(injectorModules[0].type);
    } else {
      throw new BaseException("No components nor injectorModules given");
    }
    var statements = [];
    var exportedVars = [];
    components.forEach((componentWithDirs) {
      var compMeta = (componentWithDirs.component as CompileDirectiveMetadata);
      _assertComponent(compMeta);
      var compViewFactoryVar = this._compileComponent(compMeta,
          componentWithDirs.directives, componentWithDirs.pipes, statements);
      exportedVars.add(compViewFactoryVar);
      var hostMeta = createHostComponentMeta(compMeta.type, compMeta.selector);
      var hostViewFactoryVar =
          this._compileComponent(hostMeta, [compMeta], [], statements);
      var compFactoryVar = '''${ compMeta . type . name}NgFactory''';
      statements.add(o
          .variable(compFactoryVar)
          .set(o.importExpr(_COMPONENT_FACTORY_IDENTIFIER).instantiate(
              [
                o.literal(compMeta.selector),
                o.variable(hostViewFactoryVar),
                o.importExpr(compMeta.type),
                o.METADATA_MAP
              ],
              o.importType(
                  _COMPONENT_FACTORY_IDENTIFIER, null, [o.TypeModifier.Const])))
          .toDeclStmt(null, [o.StmtModifier.Final]));
      exportedVars.add(compFactoryVar);
    });
    injectorModules.forEach((injectorModuleMeta) {
      var compileResult =
          this._injectorCompiler.compileInjector(injectorModuleMeta);
      compileResult.statements.forEach((stmt) => statements.add(stmt));
      exportedVars.add(compileResult.injectorFactoryVar);
    });
    return this._codegenSourceModule(moduleUrl, statements, exportedVars);
  }

  List<SourceModule> compileStylesheet(String stylesheetUrl, String cssText) {
    var plainStyles =
        this._styleCompiler.compileStylesheet(stylesheetUrl, cssText, false);
    var shimStyles =
        this._styleCompiler.compileStylesheet(stylesheetUrl, cssText, true);
    return [
      this._codegenSourceModule(_stylesModuleUrl(stylesheetUrl, false),
          _resolveStyleStatements(plainStyles), [plainStyles.stylesVar]),
      this._codegenSourceModule(_stylesModuleUrl(stylesheetUrl, true),
          _resolveStyleStatements(shimStyles), [shimStyles.stylesVar])
    ];
  }

  String _compileComponent(
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> directives,
      List<CompilePipeMetadata> pipes,
      List<o.Statement> targetStatements) {
    var styleResult = this._styleCompiler.compileComponent(compMeta);
    var parsedTemplate = this._templateParser.parse(compMeta,
        compMeta.template.template, directives, pipes, compMeta.type.name);
    var viewResult = this._viewCompiler.compileComponent(
        compMeta, parsedTemplate, o.variable(styleResult.stylesVar), pipes);
    ListWrapper.addAll(targetStatements, _resolveStyleStatements(styleResult));
    ListWrapper.addAll(targetStatements, _resolveViewStatements(viewResult));
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
  return '''${ urlWithoutSuffix}.template${ MODULE_SUFFIX}''';
}

String _stylesModuleUrl(String stylesheetUrl, bool shim) {
  return shim
      ? '''${ stylesheetUrl}.shim${ MODULE_SUFFIX}'''
      : '''${ stylesheetUrl}${ MODULE_SUFFIX}''';
}

_assertComponent(CompileDirectiveMetadata meta) {
  if (!meta.isComponent) {
    throw new BaseException(
        '''Could not compile \'${ meta . type . name}\' because it is not a component.''');
  }
}
