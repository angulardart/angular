library angular2.src.compiler.runtime_compiler;

import "dart:async";
import "package:angular2/src/facade/lang.dart"
    show
        IS_DART,
        Type,
        Json,
        isBlank,
        isPresent,
        isString,
        stringify,
        evalExpression;
import "package:angular2/src/facade/exceptions.dart"
    show BaseException, unimplemented;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, SetWrapper, MapWrapper, StringMapWrapper;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;
import "compile_metadata.dart"
    show
        createHostComponentMeta,
        CompileDirectiveMetadata,
        CompileTypeMetadata,
        CompileTemplateMetadata,
        CompilePipeMetadata,
        CompileMetadataWithType,
        CompileIdentifierMetadata;
import "template_ast.dart"
    show
        TemplateAst,
        TemplateAstVisitor,
        NgContentAst,
        EmbeddedTemplateAst,
        ElementAst,
        BoundEventAst,
        BoundElementPropertyAst,
        AttrAst,
        BoundTextAst,
        TextAst,
        DirectiveAst,
        BoundDirectivePropertyAst,
        templateVisitAll;
import "package:angular2/src/core/di.dart" show Injectable;
import "style_compiler.dart"
    show StyleCompiler, StylesCompileDependency, StylesCompileResult;
import "view_compiler/view_compiler.dart" show ViewCompiler;
import "view_compiler/injector_compiler.dart" show InjectorCompiler;
import "template_parser.dart" show TemplateParser;
import "directive_normalizer.dart" show DirectiveNormalizer;
import "runtime_metadata.dart" show RuntimeMetadataResolver;
import "package:angular2/src/core/linker/component_factory.dart"
    show ComponentFactory;
import "package:angular2/src/core/linker/injector_factory.dart"
    show CodegenInjectorFactory;
import "package:angular2/src/core/linker/component_resolver.dart"
    show ComponentResolver, ReflectorComponentResolver;
import "config.dart" show CompilerConfig;
import "output/output_ast.dart" as ir;
import "output/output_jit.dart" show jitStatements;
import "output/output_interpreter.dart" show interpretStatements;
import "output/interpretive_view.dart" show InterpretiveAppViewInstanceFactory;
import "output/interpretive_injector.dart"
    show InterpretiveInjectorInstanceFactory;
import "xhr.dart" show XHR;

/**
 * An internal module of the Angular compiler that begins with component types,
 * extracts templates, and eventually produces a compiled version of the component
 * ready for linking into an application.
 */
@Injectable()
class RuntimeCompiler implements ComponentResolver {
  RuntimeMetadataResolver _runtimeMetadataResolver;
  DirectiveNormalizer _templateNormalizer;
  TemplateParser _templateParser;
  StyleCompiler _styleCompiler;
  ViewCompiler _viewCompiler;
  XHR _xhr;
  InjectorCompiler _injectorCompiler;
  CompilerConfig _genConfig;
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
      this._injectorCompiler,
      this._genConfig) {}
  CodegenInjectorFactory<dynamic> createInjectorFactory(Type moduleClass,
      [List<dynamic> extraProviders = const []]) {
    var injectorModuleMeta = this
        ._runtimeMetadataResolver
        .getInjectorModuleMetadata(moduleClass, extraProviders);
    var compileResult =
        this._injectorCompiler.compileInjector(injectorModuleMeta);
    dynamic factory;
    if (IS_DART || !this._genConfig.useJit) {
      factory = interpretStatements(
          compileResult.statements,
          compileResult.injectorFactoryVar,
          new InterpretiveInjectorInstanceFactory());
    } else {
      factory = jitStatements(
          '''${ injectorModuleMeta . type . name}.ngfactory.js''',
          compileResult.statements,
          compileResult.injectorFactoryVar);
    }
    return factory;
  }

  Future<ComponentFactory> resolveComponent(Type componentType) {
    CompileDirectiveMetadata compMeta =
        this._runtimeMetadataResolver.getDirectiveMetadata(componentType);
    var hostCacheKey = this._hostCacheKeys[componentType];
    if (isBlank(hostCacheKey)) {
      hostCacheKey = new Object();
      this._hostCacheKeys[componentType] = hostCacheKey;
      assertComponent(compMeta);
      CompileDirectiveMetadata hostMeta =
          createHostComponentMeta(compMeta.type, compMeta.selector);
      this._loadAndCompileComponent(hostCacheKey, hostMeta, [compMeta], [], []);
    }
    return this._compiledTemplateDone[hostCacheKey].then(
        (CompiledTemplate compiledTemplate) => new ComponentFactory(
            compMeta.selector, compiledTemplate.viewFactory, componentType));
  }

  clearCache() {
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
    if (isBlank(compiledTemplate)) {
      compiledTemplate = new CompiledTemplate();
      this._compiledTemplateCache[cacheKey] = compiledTemplate;
      done = PromiseWrapper
          .all((new List.from(
              [(this._compileComponentStyles(compMeta) as dynamic)])
            ..addAll(viewDirectives
                .map((dirMeta) =>
                    this._templateNormalizer.normalizeDirective(dirMeta))
                .toList())))
          .then((List<dynamic> stylesAndNormalizedViewDirMetas) {
        var normalizedViewDirMetas =
            ListWrapper.slice(stylesAndNormalizedViewDirMetas, 1);
        var styles = stylesAndNormalizedViewDirMetas[0];
        var parsedTemplate = this._templateParser.parse(
            compMeta,
            compMeta.template.template,
            normalizedViewDirMetas,
            pipes,
            compMeta.type.name);
        var childPromises = [];
        compiledTemplate.init(this._compileComponent(compMeta, parsedTemplate,
            styles, pipes, compilingComponentsPath, childPromises));
        return PromiseWrapper.all(childPromises).then((_) {
          return compiledTemplate;
        });
      });
      this._compiledTemplateDone[cacheKey] = done;
    }
    return compiledTemplate;
  }

  Function _compileComponent(
      CompileDirectiveMetadata compMeta,
      List<TemplateAst> parsedTemplate,
      List<String> styles,
      List<CompilePipeMetadata> pipes,
      List<dynamic> compilingComponentsPath,
      List<Future<dynamic>> childPromises) {
    var compileResult = this._viewCompiler.compileComponent(
        compMeta,
        parsedTemplate,
        new ir.ExternalExpr(new CompileIdentifierMetadata(runtime: styles)),
        pipes);
    compileResult.dependencies.forEach((dep) {
      var childCompilingComponentsPath =
          ListWrapper.clone(compilingComponentsPath);
      var childCacheKey = dep.comp.type.runtime;
      List<CompileDirectiveMetadata> childViewDirectives = this
          ._runtimeMetadataResolver
          .getViewDirectivesMetadata(dep.comp.type.runtime);
      List<CompilePipeMetadata> childViewPipes = this
          ._runtimeMetadataResolver
          .getViewPipesMetadata(dep.comp.type.runtime);
      var childIsRecursive =
          ListWrapper.contains(childCompilingComponentsPath, childCacheKey);
      childCompilingComponentsPath.add(childCacheKey);
      var childComp = this._loadAndCompileComponent(
          dep.comp.type.runtime,
          dep.comp,
          childViewDirectives,
          childViewPipes,
          childCompilingComponentsPath);
      dep.factoryPlaceholder.runtime = childComp.proxyViewFactory;
      dep.factoryPlaceholder.name =
          '''viewFactory_${ dep . comp . type . name}''';
      if (!childIsRecursive) {
        // Only wait for a child if it is not a cycle
        childPromises.add(this._compiledTemplateDone[childCacheKey]);
      }
    });
    var factory;
    if (IS_DART || !this._genConfig.useJit) {
      factory = interpretStatements(
          compileResult.statements,
          compileResult.viewFactoryVar,
          new InterpretiveAppViewInstanceFactory());
    } else {
      factory = jitStatements('''${ compMeta . type . name}.template.js''',
          compileResult.statements, compileResult.viewFactoryVar);
    }
    return factory;
  }

  Future<List<String>> _compileComponentStyles(
      CompileDirectiveMetadata compMeta) {
    var compileResult = this._styleCompiler.compileComponent(compMeta);
    return this._resolveStylesCompileResult(compMeta.type.name, compileResult);
  }

  Future<List<String>> _resolveStylesCompileResult(
      String sourceUrl, StylesCompileResult result) {
    var promises =
        result.dependencies.map((dep) => this._loadStylesheetDep(dep)).toList();
    return PromiseWrapper.all(promises).then((cssTexts) {
      var nestedCompileResultPromises = [];
      for (var i = 0; i < result.dependencies.length; i++) {
        var dep = result.dependencies[i];
        var cssText = cssTexts[i];
        var nestedCompileResult = this
            ._styleCompiler
            .compileStylesheet(dep.sourceUrl, cssText, dep.isShimmed);
        nestedCompileResultPromises.add(this
            ._resolveStylesCompileResult(dep.sourceUrl, nestedCompileResult));
      }
      return PromiseWrapper.all(nestedCompileResultPromises);
    }).then((nestedStylesArr) {
      for (var i = 0; i < result.dependencies.length; i++) {
        var dep = result.dependencies[i];
        dep.valuePlaceholder.runtime = nestedStylesArr[i];
        dep.valuePlaceholder.name = '''importedStyles${ i}''';
      }
      if (IS_DART || !this._genConfig.useJit) {
        return interpretStatements(result.statements, result.stylesVar,
            new InterpretiveAppViewInstanceFactory());
      } else {
        return jitStatements(
            '''${ sourceUrl}.css.js''', result.statements, result.stylesVar);
      }
    });
  }

  Future<String> _loadStylesheetDep(StylesCompileDependency dep) {
    var cacheKey = '''${ dep . sourceUrl}${ dep . isShimmed ? ".shim" : ""}''';
    var cssTextPromise = this._styleCache[cacheKey];
    if (isBlank(cssTextPromise)) {
      cssTextPromise = this._xhr.get(dep.sourceUrl);
      this._styleCache[cacheKey] = cssTextPromise;
    }
    return cssTextPromise;
  }
}

class CompiledTemplate {
  Function viewFactory = null;
  Function proxyViewFactory;
  CompiledTemplate() {
    this.proxyViewFactory = (viewUtils, childInjector, contextEl) =>
        this.viewFactory(viewUtils, childInjector, contextEl);
  }
  init(Function viewFactory) {
    this.viewFactory = viewFactory;
  }
}

assertComponent(CompileDirectiveMetadata meta) {
  if (!meta.isComponent) {
    throw new BaseException(
        '''Could not compile \'${ meta . type . name}\' because it is not a component.''');
  }
}
