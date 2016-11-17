import "dart:async";

import "package:angular2/src/core/di.dart" show Injectable, Injector;
import "package:angular2/src/core/linker/view_container.dart";
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory, NgViewFactory;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "compile_metadata.dart"
    show
        createHostComponentMeta,
        CompileDirectiveMetadata,
        CompilePipeMetadata,
        CompileIdentifierMetadata;
import "directive_normalizer.dart" show DirectiveNormalizer;
import "output/interpretive_view.dart" show InterpretiveAppViewInstanceFactory;
import "output/output_ast.dart" as ir;
import "output/output_interpreter.dart" show interpretStatements;
import "runtime_metadata.dart" show RuntimeMetadataResolver;
import "style_compiler.dart"
    show StyleCompiler, StylesCompileDependency, StylesCompileResult;
import "template_ast.dart" show TemplateAst;
import "template_parser.dart" show TemplateParser;
import "view_compiler/view_compiler.dart" show ViewCompiler;
import "xhr.dart" show XHR;

/// An internal module of the Angular compiler that begins with component types,
/// extracts templates, and eventually produces a compiled version of the component
/// ready for linking into an application.
@Injectable()
class RuntimeCompiler implements ComponentResolver {
  RuntimeMetadataResolver _runtimeMetadataResolver;
  DirectiveNormalizer _templateNormalizer;
  final TemplateParser _templateParser;
  final StyleCompiler _styleCompiler;
  final ViewCompiler _viewCompiler;
  XHR _xhr;
  Map<String, Future<String>> _styleCache = new Map<String, Future<String>>();
  var _hostCacheKeys = new Map<Type, dynamic>();
  var _compiledTemplateCache = new Map<dynamic, CompiledTemplate>();
  var _compiledTemplateDone = new Map<dynamic, Future<CompiledTemplate>>();

  RuntimeCompiler(
    this._runtimeMetadataResolver,
    this._templateNormalizer,
    this._templateParser,
    this._styleCompiler,
    this._viewCompiler,
    this._xhr,
  );

  Future<ComponentFactory> resolveComponent(Type componentType) {
    CompileDirectiveMetadata compMeta =
        this._runtimeMetadataResolver.getDirectiveMetadata(componentType);
    var hostCacheKey = this._hostCacheKeys[componentType];
    if (hostCacheKey == null) {
      hostCacheKey = new Object();
      this._hostCacheKeys[componentType] = hostCacheKey;
      assertComponent(compMeta);
      CompileDirectiveMetadata hostMeta = createHostComponentMeta(compMeta.type,
          compMeta.selector, compMeta.template.preserveWhitespace);
      this._loadAndCompileComponent(hostCacheKey, hostMeta, [compMeta], [], []);
    }
    return this._compiledTemplateDone[hostCacheKey].then(
        (CompiledTemplate compiledTemplate) => new ComponentFactory(
            compMeta.selector, compiledTemplate.viewFactory, componentType));
  }

  void clearCache() {
    this._styleCache.clear();
    this._compiledTemplateCache.clear();
    this._compiledTemplateDone.clear();
    this._hostCacheKeys.clear();
  }

  CompiledTemplate _loadAndCompileComponent(
      dynamic cacheKey,
      CompileDirectiveMetadata compMeta,
      List<CompileDirectiveMetadata> viewDirectives,
      List<CompilePipeMetadata> pipes,
      List<dynamic> compilingComponentsPath) {
    var compiledTemplate = this._compiledTemplateCache[cacheKey];
    var done = this._compiledTemplateDone[cacheKey];
    if (compiledTemplate == null) {
      compiledTemplate = new CompiledTemplate();
      this._compiledTemplateCache[cacheKey] = compiledTemplate;
      List<Future> futures =
          new List.from([(this._compileComponentStyles(compMeta) as dynamic)])
            ..addAll(viewDirectives
                .map((dirMeta) =>
                    this._templateNormalizer.normalizeDirective(dirMeta))
                .toList());
      done = Future.wait(futures).then/*<Future<CompiledTemplate>>*/(
          (List<dynamic> stylesAndNormalizedViewDirMetas) {
        _ResolvedStyles resolvedStyles = stylesAndNormalizedViewDirMetas[0];
        var normalizedViewDirMetas = stylesAndNormalizedViewDirMetas.sublist(1)
            as List<CompileDirectiveMetadata>;
        var styles = resolvedStyles.styles;
        var parsedTemplate = this._templateParser.parse(
            compMeta,
            compMeta.template.template,
            normalizedViewDirMetas,
            pipes,
            compMeta.type.name);
        var childPromises = <Future>[];
        compiledTemplate.init(_compileComponentViewFactory(
            compMeta,
            parsedTemplate,
            resolvedStyles.compileResult,
            styles,
            pipes,
            compilingComponentsPath,
            childPromises));
        return Future.wait(childPromises).then((_) {
          return compiledTemplate;
        });
      });
      this._compiledTemplateDone[cacheKey] = done;
    }
    return compiledTemplate;
  }

  NgViewFactory _compileComponentViewFactory(
      CompileDirectiveMetadata compMeta,
      List<TemplateAst> parsedTemplate,
      StylesCompileResult stylesCompileResult,
      List<String> styles,
      List<CompilePipeMetadata> pipes,
      List<dynamic> compilingComponentsPath,
      List<Future<dynamic>> childPromises) {
    var compileResult = this._viewCompiler.compileComponent(
        compMeta,
        parsedTemplate,
        stylesCompileResult,
        new ir.ExternalExpr(new CompileIdentifierMetadata(runtime: styles)),
        pipes);
    compileResult.dependencies.forEach((dep) {
      var childCompilingComponentsPath = new List.from(compilingComponentsPath);
      var childCacheKey = dep.comp.type.runtime;
      List<CompileDirectiveMetadata> childViewDirectives = this
          ._runtimeMetadataResolver
          .getViewDirectivesMetadata(dep.comp.type.runtime);
      List<CompilePipeMetadata> childViewPipes = this
          ._runtimeMetadataResolver
          .getViewPipesMetadata(dep.comp.type.runtime);
      var childIsRecursive =
          childCompilingComponentsPath.contains(childCacheKey);
      childCompilingComponentsPath.add(childCacheKey);
      var childComp = _loadAndCompileComponent(dep.comp.type.runtime, dep.comp,
          childViewDirectives, childViewPipes, childCompilingComponentsPath);
      // ComponentFactory init may not have been called yet, so assign
      // proxyViewFactory that will forward calls correctly after
      // initialization.
      dep.factoryPlaceholder.runtime = childComp.proxyViewFactory;
      dep.factoryPlaceholder.name = 'viewFactory_${dep.comp.type.name}';
      if (!childIsRecursive) {
        // Only wait for a child if it is not a cycle
        childPromises.add(this._compiledTemplateDone[childCacheKey]);
      }
    });
    // Returns NgViewFactory that interprets viewFactoryVar for the AppView.
    return interpretStatements(
        compileResult.statements,
        compileResult.viewFactoryVar,
        new InterpretiveAppViewInstanceFactory()) as NgViewFactory;
  }

  Future<_ResolvedStyles> _compileComponentStyles(
      CompileDirectiveMetadata compMeta) {
    var compileResult = this._styleCompiler.compileComponent(compMeta);
    return this
        ._resolveStylesCompileResult(compMeta.type.name, compileResult)
        .then((List<String> styles) {
      return new _ResolvedStyles(compileResult, styles);
    });
  }

  Future<List<String>> _resolveStylesCompileResult(
      String sourceUrl, StylesCompileResult result) {
    var promises =
        result.dependencies.map((dep) => this._loadStylesheetDep(dep)).toList();
    return Future.wait(promises).then((cssTexts) {
      var nestedCompileResultPromises = <Future>[];
      for (var i = 0; i < result.dependencies.length; i++) {
        var dep = result.dependencies[i];
        var cssText = cssTexts[i];
        var nestedCompileResult = this
            ._styleCompiler
            .compileStylesheet(dep.sourceUrl, cssText, dep.isShimmed);
        nestedCompileResultPromises.add(this
            ._resolveStylesCompileResult(dep.sourceUrl, nestedCompileResult));
      }
      return Future.wait(nestedCompileResultPromises);
    }).then((nestedStylesArr) {
      for (var i = 0; i < result.dependencies.length; i++) {
        var dep = result.dependencies[i];
        dep.valuePlaceholder.runtime = nestedStylesArr[i];
        dep.valuePlaceholder.name = '''importedStyles${ i}''';
      }
      return interpretStatements(result.statements, result.stylesVar,
          new InterpretiveAppViewInstanceFactory()) as List<String>;
    });
  }

  Future<String> _loadStylesheetDep(StylesCompileDependency dep) {
    var cacheKey = '''${ dep . sourceUrl}${ dep . isShimmed ? ".shim" : ""}''';
    var cssTextPromise = this._styleCache[cacheKey];
    if (cssTextPromise == null) {
      cssTextPromise = this._xhr.get(dep.sourceUrl);
      this._styleCache[cacheKey] = cssTextPromise;
    }
    return cssTextPromise;
  }
}

class CompiledTemplate {
  NgViewFactory viewFactory;

  /// Proxy to viewFactory that will eventually be available when viewFactory
  /// gets initialized.
  NgViewFactory proxyViewFactory;

  CompiledTemplate() {
    proxyViewFactory = (Injector childInjector, ViewContainer contextEl) =>
        viewFactory(childInjector, contextEl);
  }
  void init(NgViewFactory factory) {
    viewFactory = factory;
  }
}

void assertComponent(CompileDirectiveMetadata meta) {
  if (!meta.isComponent) {
    throw new BaseException(
        '''Could not compile \'${ meta . type . name}\' because it is not a component.''');
  }
}

class _ResolvedStyles {
  final List<String> styles;
  final StylesCompileResult compileResult;
  _ResolvedStyles(this.compileResult, this.styles);
}
