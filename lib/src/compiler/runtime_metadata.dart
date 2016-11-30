import "package:angular2/src/compiler/url_resolver.dart" show getUrlScheme;
import "package:angular2/src/core/di.dart" show Injectable, Inject, Optional;
import "package:angular2/src/core/di/decorators.dart";
import "package:angular2/src/core/di/provider.dart" show Provider;
import "package:angular2/src/core/di/reflective_provider.dart"
    show constructDependencies, ReflectiveDependency;
import "package:angular2/src/core/metadata.dart"
    show View, Attribute, Query, Component;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LIFECYCLE_HOOKS_VALUES;
import "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart" show stringify;

import "compile_metadata.dart" as cpl;
import "compiler_utils.dart" show MODULE_SUFFIX, sanitizeIdentifier;
import "directive_lifecycle_reflector.dart" show hasLifecycleHook;
import "directive_resolver.dart" show DirectiveResolver;
import "pipe_resolver.dart" show PipeResolver;
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
      @Optional() @Inject(PLATFORM_PIPES) this._platformPipes);
  String sanitizeTokenName(dynamic token) {
    var identifier = stringify(token);
    if (identifier.indexOf("(") >= 0) {
      // case: anonymous functions!
      var found = this._anonymousTypes[token];
      if (found == null) {
        this._anonymousTypes[token] = this._anonymousTypeIndex++;
        found = this._anonymousTypes[token];
      }
      identifier = '''anonymous_token_${ found}_''';
    }
    return sanitizeIdentifier(identifier);
  }

  cpl.CompileDirectiveMetadata getDirectiveMetadata(Type directiveType) {
    var meta = this._directiveCache[directiveType];
    if (meta == null) {
      var dirMeta = this._directiveResolver.resolve(directiveType);
      var moduleUrl;
      var templateMeta;
      var changeDetectionStrategy;
      var viewProviders = [];
      if (dirMeta is Component) {
        Component cmpMeta = dirMeta;
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
        if (dirMeta.viewProviders != null) {
          viewProviders = this.getProvidersMetadata(dirMeta.viewProviders);
        }
      }
      var providers = [];
      if (dirMeta.providers != null) {
        providers = this.getProvidersMetadata(dirMeta.providers);
      }
      var queries = [];
      var viewQueries = [];
      if (dirMeta.queries != null) {
        queries =
            getQueriesMetadata(dirMeta.queries as Map<String, Query>, false);
        viewQueries =
            getQueriesMetadata(dirMeta.queries as Map<String, Query>, true);
      }
      meta = cpl.CompileDirectiveMetadata.create(
          selector: dirMeta.selector,
          exportAs: dirMeta.exportAs,
          isComponent: templateMeta != null,
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
    if (meta == null) {
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
      var p = (dep.properties
          .firstWhere((p) => p is Attribute, orElse: () => null) as Attribute);
      var isAttribute = false;
      if (p != null) {
        compileToken = this.getTokenMetadata(p.attributeName);
        isAttribute = true;
      } else {
        compileToken = this.getTokenMetadata(dep.key.token);
      }
      return new cpl.CompileDiDependencyMetadata(
          isAttribute: isAttribute,
          isHost: dep.upperBoundVisibility is Host,
          isSelf: dep.upperBoundVisibility is Self,
          isSkipSelf: dep.lowerBoundVisibility is SkipSelf,
          isOptional: dep.optional,
          token: compileToken);
    }).toList();
  }

  cpl.CompileTokenMetadata getTokenMetadata(dynamic token) {
    var compileToken;
    if (token is String) {
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
      if (provider is List) {
        return this.getProvidersMetadata(provider);
      } else if (provider is Provider) {
        return [
          this.getProviderMetadata(provider),
          const [],
        ];
      } else if (isValidType(provider)) {
        return [
          this.getTypeMetadata(provider, null),
          const [],
        ];
      } else {
        throw new BaseException(
            '''Invalid provider - only instances of Provider and Type are allowed, got: ${ stringify ( provider )}''');
      }
    }).toList();
  }

  cpl.CompileProviderMetadata getProviderMetadata(Provider provider) {
    List<cpl.CompileDiDependencyMetadata> compileDeps;
    if (provider.useClass != null) {
      compileDeps = this
          .getDependenciesMetadata(provider.useClass, provider.dependencies);
    } else if (provider.useFactory != null) {
      compileDeps = this
          .getDependenciesMetadata(provider.useFactory, provider.dependencies);
    }
    return new cpl.CompileProviderMetadata(
        token: this.getTokenMetadata(provider.token),
        useClass: provider.useClass != null
            ? this.getTypeMetadata(provider.useClass, null, compileDeps)
            : null,
        useValue: provider.useValue != null
            ? new cpl.CompileIdentifierMetadata(runtime: provider.useValue)
            : null,
        useFactory: provider.useFactory != null
            ? this.getFactoryMetadata(provider.useFactory, null, compileDeps)
            : null,
        useExisting: provider.useExisting != null
            ? this.getTokenMetadata(provider.useExisting)
            : null,
        useProperty: provider.useProperty,
        deps: compileDeps,
        multi: provider.multi);
  }

  List<cpl.CompileQueryMetadata> getQueriesMetadata(
      Map<String, Query> queries, bool isViewQuery) {
    var compileQueries = <cpl.CompileQueryMetadata>[];
    queries.forEach((propertyName, query) {
      if (identical(query.isViewQuery, isViewQuery)) {
        compileQueries.add(this.getQueryMetadata(query, propertyName));
      }
    });
    return compileQueries;
  }

  cpl.CompileQueryMetadata getQueryMetadata(Query q, String propertyName) {
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
        read: q.read != null ? this.getTokenMetadata(q.read) : null);
  }
}

List<Type> flattenDirectives(View view, List<dynamic> platformDirectives) {
  var directives = <Type>[];
  if (platformDirectives != null) {
    flattenArray(platformDirectives, directives);
  }
  if (view.directives != null) {
    flattenArray(view.directives, directives);
  }
  return directives;
}

List<Type> flattenPipes(View view, List<dynamic> platformPipes) {
  var pipes = <Type>[];
  if (platformPipes != null) {
    flattenArray(platformPipes, pipes);
  }
  if (view.pipes != null) {
    flattenArray(view.pipes, pipes);
  }
  return pipes;
}

void flattenArray(
    List<dynamic> tree, List<dynamic /* Type | List < dynamic > */ > out) {
  for (var i = 0; i < tree.length; i++) {
    var item = tree[i];
    if (item is List) {
      flattenArray(item, out);
    } else {
      out.add(item);
    }
  }
}

bool isValidType(Object value) => value is Type;

String calcModuleUrl(Type type, Component cmpMetadata) {
  var moduleId = cmpMetadata.moduleId;
  if (moduleId != null) {
    var scheme = getUrlScheme(moduleId);
    return scheme != null && scheme.length > 0
        ? moduleId
        : '''package:${ moduleId}${ MODULE_SUFFIX}''';
  } else {
    return reflector.importUri(type);
  }
}
