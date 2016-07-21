import "package:angular2/src/compiler/url_resolver.dart" show getUrlScheme;
import "package:angular2/src/core/di.dart" show Injectable, Inject, Optional;
import "package:angular2/src/core/di/metadata.dart"
    show SelfMetadata, HostMetadata, SkipSelfMetadata;
import "package:angular2/src/core/di/provider.dart" show Provider;
import "package:angular2/src/core/di/reflective_provider.dart"
    show
        constructDependencies,
        ReflectiveDependency,
        getInjectorModuleProviders;
import "package:angular2/src/core/metadata/di.dart" as dimd;
import "package:angular2/src/core/metadata/di.dart" show AttributeMetadata;
import "package:angular2/src/core/metadata/directives.dart" as md;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LIFECYCLE_HOOKS_VALUES;
import "package:angular2/src/core/metadata/view.dart" show ViewMetadata;
import "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isPresent, isArray, stringify, isString;

import "compile_metadata.dart" as cpl;
import "directive_lifecycle_reflector.dart" show hasLifecycleHook;
import "directive_resolver.dart" show DirectiveResolver;
import "pipe_resolver.dart" show PipeResolver;
import "util.dart" show MODULE_SUFFIX, sanitizeIdentifier;
import "view_resolver.dart" show ViewResolver;

@Injectable()
class RuntimeMetadataResolver {
  DirectiveResolver _directiveResolver;
  PipeResolver _pipeResolver;
  ViewResolver _viewResolver;
  List<Type> _platformDirectives;
  List<Type> _platformPipes;
  var _directiveCache = new Map<Type, cpl.CompileDirectiveMetadata>();
  var _pipeCache = new Map<Type, cpl.CompilePipeMetadata>();
  var _anonymousTypes = new Map<Object, num>();
  var _anonymousTypeIndex = 0;
  RuntimeMetadataResolver(
      this._directiveResolver,
      this._pipeResolver,
      this._viewResolver,
      @Optional() @Inject(PLATFORM_DIRECTIVES) this._platformDirectives,
      @Optional() @Inject(PLATFORM_PIPES) this._platformPipes) {}
  String sanitizeTokenName(dynamic token) {
    var identifier = stringify(token);
    if (identifier.indexOf("(") >= 0) {
      // case: anonymous functions!
      var found = this._anonymousTypes[token];
      if (isBlank(found)) {
        this._anonymousTypes[token] = this._anonymousTypeIndex++;
        found = this._anonymousTypes[token];
      }
      identifier = '''anonymous_token_${ found}_''';
    }
    return sanitizeIdentifier(identifier);
  }

  cpl.CompileDirectiveMetadata getDirectiveMetadata(Type directiveType) {
    var meta = this._directiveCache[directiveType];
    if (isBlank(meta)) {
      var dirMeta = this._directiveResolver.resolve(directiveType);
      var moduleUrl = null;
      var templateMeta = null;
      var changeDetectionStrategy = null;
      var viewProviders = [];
      if (dirMeta is md.ComponentMetadata) {
        md.ComponentMetadata cmpMeta = dirMeta;
        moduleUrl = calcModuleUrl(directiveType, cmpMeta);
        var viewMeta = this._viewResolver.resolve(directiveType);
        templateMeta = new cpl.CompileTemplateMetadata(
            encapsulation: viewMeta.encapsulation,
            template: viewMeta.template,
            templateUrl: viewMeta.templateUrl,
            preserveWhitespace: cmpMeta.preserveWhitespace,
            styles: viewMeta.styles,
            styleUrls: viewMeta.styleUrls);
        changeDetectionStrategy = cmpMeta.changeDetection;
        if (isPresent(dirMeta.viewProviders)) {
          viewProviders = this.getProvidersMetadata(dirMeta.viewProviders);
        }
      }
      var providers = [];
      if (isPresent(dirMeta.providers)) {
        providers = this.getProvidersMetadata(dirMeta.providers);
      }
      var queries = [];
      var viewQueries = [];
      if (isPresent(dirMeta.queries)) {
        queries = getQueriesMetadata(
            dirMeta.queries as Map<String, dimd.QueryMetadata>, false);
        viewQueries = getQueriesMetadata(
            dirMeta.queries as Map<String, dimd.QueryMetadata>, true);
      }
      meta = cpl.CompileDirectiveMetadata.create(
          selector: dirMeta.selector,
          exportAs: dirMeta.exportAs,
          isComponent: isPresent(templateMeta),
          type: this.getTypeMetadata(directiveType, moduleUrl),
          template: templateMeta,
          changeDetection: changeDetectionStrategy,
          inputs: dirMeta.inputs,
          outputs: dirMeta.outputs,
          host: dirMeta.host,
          lifecycleHooks: LIFECYCLE_HOOKS_VALUES
              .where((hook) => hasLifecycleHook(hook, directiveType))
              .toList(),
          providers: providers,
          viewProviders: viewProviders,
          queries: queries as List<cpl.CompileQueryMetadata>,
          viewQueries: viewQueries as List<cpl.CompileQueryMetadata>);
      this._directiveCache[directiveType] = meta;
    }
    return meta;
  }

  cpl.CompileTypeMetadata getTypeMetadata(Type type, String moduleUrl,
      [List<dynamic> deps = null]) {
    return new cpl.CompileTypeMetadata(
        name: this.sanitizeTokenName(type),
        moduleUrl: moduleUrl,
        runtime: type,
        diDeps: this.getDependenciesMetadata(type, deps));
  }

  cpl.CompileFactoryMetadata getFactoryMetadata(
      Function factory, String moduleUrl, List<dynamic> deps) {
    return new cpl.CompileFactoryMetadata(
        name: this.sanitizeTokenName(factory),
        moduleUrl: moduleUrl,
        runtime: factory,
        diDeps: this.getDependenciesMetadata(factory, deps));
  }

  cpl.CompilePipeMetadata getPipeMetadata(Type pipeType) {
    var meta = this._pipeCache[pipeType];
    if (isBlank(meta)) {
      var pipeMeta = this._pipeResolver.resolve(pipeType);
      var moduleUrl = reflector.importUri(pipeType);
      meta = new cpl.CompilePipeMetadata(
          type: this.getTypeMetadata(pipeType, moduleUrl),
          name: pipeMeta.name,
          pure: pipeMeta.pure,
          lifecycleHooks: LIFECYCLE_HOOKS_VALUES
              .where((hook) => hasLifecycleHook(hook, pipeType))
              .toList());
      this._pipeCache[pipeType] = meta;
    }
    return meta;
  }

  List<cpl.CompileDirectiveMetadata> getViewDirectivesMetadata(Type component) {
    var view = this._viewResolver.resolve(component);
    var directives = flattenDirectives(view, this._platformDirectives);
    for (var i = 0; i < directives.length; i++) {
      if (!isValidType(directives[i])) {
        throw new BaseException(
            '''Unexpected directive value \'${ stringify ( directives [ i ] )}\' on the View of component \'${ stringify ( component )}\'''');
      }
    }
    return directives.map((type) => this.getDirectiveMetadata(type)).toList();
  }

  List<cpl.CompilePipeMetadata> getViewPipesMetadata(Type component) {
    var view = this._viewResolver.resolve(component);
    var pipes = flattenPipes(view, this._platformPipes);
    for (var i = 0; i < pipes.length; i++) {
      if (!isValidType(pipes[i])) {
        throw new BaseException(
            '''Unexpected piped value \'${ stringify ( pipes [ i ] )}\' on the View of component \'${ stringify ( component )}\'''');
      }
    }
    return pipes.map((type) => this.getPipeMetadata(type)).toList();
  }

  List<cpl.CompileDiDependencyMetadata> getDependenciesMetadata(
      dynamic /* Type | Function */ typeOrFunc, List<dynamic> dependencies) {
    List<ReflectiveDependency> deps =
        constructDependencies(typeOrFunc, dependencies);
    return deps.map((dep) {
      var compileToken;
      var p = (dep.properties.firstWhere((p) => p is AttributeMetadata,
          orElse: () => null) as AttributeMetadata);
      var isAttribute = false;
      if (isPresent(p)) {
        compileToken = this.getTokenMetadata(p.attributeName);
        isAttribute = true;
      } else {
        compileToken = this.getTokenMetadata(dep.key.token);
      }
      var compileQuery = null;
      var q = (dep.properties.firstWhere((p) => p is dimd.QueryMetadata,
          orElse: () => null) as dimd.QueryMetadata);
      if (isPresent(q)) {
        compileQuery = this.getQueryMetadata(q, null);
      }
      return new cpl.CompileDiDependencyMetadata(
          isAttribute: isAttribute,
          isHost: dep.upperBoundVisibility is HostMetadata,
          isSelf: dep.upperBoundVisibility is SelfMetadata,
          isSkipSelf: dep.lowerBoundVisibility is SkipSelfMetadata,
          isOptional: dep.optional,
          query: isPresent(q) && !q.isViewQuery ? compileQuery : null,
          viewQuery: isPresent(q) && q.isViewQuery ? compileQuery : null,
          token: compileToken);
    }).toList();
  }

  cpl.CompileTokenMetadata getTokenMetadata(dynamic token) {
    var compileToken;
    if (isString(token)) {
      compileToken = new cpl.CompileTokenMetadata(value: token);
    } else {
      compileToken = new cpl.CompileTokenMetadata(
          identifier: new cpl.CompileIdentifierMetadata(
              runtime: token, name: this.sanitizeTokenName(token)));
    }
    return compileToken;
  }

  List<dynamic /* cpl . CompileProviderMetadata | cpl . CompileTypeMetadata | List < dynamic > */ >
      getProvidersMetadata(List<dynamic> providers) {
    return providers.map((provider) {
      if (isArray(provider)) {
        return this.getProvidersMetadata(provider);
      } else if (provider is Provider) {
        return [
          this.getProviderMetadata(provider),
          isValidType(provider.token)
              ? this.getProvidersMetadata(
                  getInjectorModuleProviders(provider.token))
              : []
        ];
      } else if (isValidType(provider)) {
        return [
          this.getTypeMetadata(provider, null),
          this.getProvidersMetadata(getInjectorModuleProviders(provider))
        ];
      } else {
        throw new BaseException(
            '''Invalid provider - only instances of Provider and Type are allowed, got: ${ stringify ( provider )}''');
      }
    }).toList();
  }

  cpl.CompileProviderMetadata getProviderMetadata(Provider provider) {
    List<cpl.CompileDiDependencyMetadata> compileDeps;
    if (isPresent(provider.useClass)) {
      compileDeps = this
          .getDependenciesMetadata(provider.useClass, provider.dependencies);
    } else if (isPresent(provider.useFactory)) {
      compileDeps = this
          .getDependenciesMetadata(provider.useFactory, provider.dependencies);
    }
    return new cpl.CompileProviderMetadata(
        token: this.getTokenMetadata(provider.token),
        useClass: isPresent(provider.useClass)
            ? this.getTypeMetadata(provider.useClass, null, compileDeps)
            : null,
        useValue: isPresent(provider.useValue)
            ? new cpl.CompileIdentifierMetadata(runtime: provider.useValue)
            : null,
        useFactory: isPresent(provider.useFactory)
            ? this.getFactoryMetadata(provider.useFactory, null, compileDeps)
            : null,
        useExisting: isPresent(provider.useExisting)
            ? this.getTokenMetadata(provider.useExisting)
            : null,
        useProperty: provider.useProperty,
        deps: compileDeps,
        multi: provider.multi);
  }

  List<cpl.CompileQueryMetadata> getQueriesMetadata(
      Map<String, dimd.QueryMetadata> queries, bool isViewQuery) {
    var compileQueries = <cpl.CompileQueryMetadata>[];
    StringMapWrapper.forEach(queries, (query, propertyName) {
      if (identical(query.isViewQuery, isViewQuery)) {
        compileQueries.add(this.getQueryMetadata(query, propertyName));
      }
    });
    return compileQueries;
  }

  cpl.CompileQueryMetadata getQueryMetadata(
      dimd.QueryMetadata q, String propertyName) {
    List<cpl.CompileTokenMetadata> selectors;
    if (q.isVarBindingQuery) {
      selectors = q.varBindings
          .map((varName) => this.getTokenMetadata(varName))
          .toList();
    } else {
      selectors = [this.getTokenMetadata(q.selector)];
    }
    return new cpl.CompileQueryMetadata(
        selectors: selectors,
        first: q.first,
        descendants: q.descendants,
        propertyName: propertyName,
        read: isPresent(q.read) ? this.getTokenMetadata(q.read) : null);
  }

  cpl.CompileInjectorModuleMetadata getInjectorModuleMetadata(
      Type config, List<dynamic> extraProviders) {
    var providers = getInjectorModuleProviders(config);
    if (isPresent(extraProviders)) {
      providers = (new List.from(providers)..addAll(extraProviders));
    }
    return new cpl.CompileInjectorModuleMetadata(
        name: this.sanitizeTokenName(config),
        moduleUrl: null,
        runtime: config,
        diDeps: [],
        providers: this.getProvidersMetadata(providers));
  }
}

List<Type> flattenDirectives(
    ViewMetadata view, List<dynamic> platformDirectives) {
  var directives = <Type>[];
  if (isPresent(platformDirectives)) {
    flattenArray(platformDirectives, directives);
  }
  if (isPresent(view.directives)) {
    flattenArray(view.directives, directives);
  }
  return directives;
}

List<Type> flattenPipes(ViewMetadata view, List<dynamic> platformPipes) {
  var pipes = <Type>[];
  if (isPresent(platformPipes)) {
    flattenArray(platformPipes, pipes);
  }
  if (isPresent(view.pipes)) {
    flattenArray(view.pipes, pipes);
  }
  return pipes;
}

void flattenArray(
    List<dynamic> tree, List<dynamic /* Type | List < dynamic > */ > out) {
  for (var i = 0; i < tree.length; i++) {
    var item = tree[i];
    if (isArray(item)) {
      flattenArray(item, out);
    } else {
      out.add(item);
    }
  }
}

bool isValidType(dynamic value) {
  return isPresent(value) && (value is Type);
}

String calcModuleUrl(Type type, md.ComponentMetadata cmpMetadata) {
  var moduleId = cmpMetadata.moduleId;
  if (isPresent(moduleId)) {
    var scheme = getUrlScheme(moduleId);
    return isPresent(scheme) && scheme.length > 0
        ? moduleId
        : '''package:${ moduleId}${ MODULE_SUFFIX}''';
  } else {
    return reflector.importUri(type);
  }
}
