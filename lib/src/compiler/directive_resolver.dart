library angular2.src.compiler.directive_resolver;

import "package:angular2/src/core/di.dart" show resolveForwardRef, Injectable;
import "package:angular2/src/facade/lang.dart"
    show Type, isPresent, isBlank, stringify;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/core/metadata.dart"
    show
        DirectiveMetadata,
        ComponentMetadata,
        InputMetadata,
        OutputMetadata,
        HostBindingMetadata,
        HostListenerMetadata,
        ContentChildrenMetadata,
        ViewChildrenMetadata,
        ContentChildMetadata,
        ViewChildMetadata;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;

bool _isDirectiveMetadata(dynamic type) {
  return type is DirectiveMetadata;
}

class NoDirectiveAnnotationError extends BaseException {
  NoDirectiveAnnotationError(Type type)
      : super('''No Directive annotation found on ${ stringify ( type )}''') {
    /* super call moved to initializer */;
  }
}

/*
 * Resolve a `Type` for [DirectiveMetadata].
 *
 * This interface can be overridden by the application developer to create custom behavior.
 *
 * See [Compiler]
 */
@Injectable()
class DirectiveResolver {
  ReflectorReader _reflector;
  DirectiveResolver([ReflectorReader _reflector]) {
    if (isPresent(_reflector)) {
      this._reflector = _reflector;
    } else {
      this._reflector = reflector;
    }
  }
  /**
   * Return [DirectiveMetadata] for a given `Type`.
   */
  DirectiveMetadata resolve(Type type) {
    var typeMetadata = this._reflector.annotations(resolveForwardRef(type));
    if (isPresent(typeMetadata)) {
      var metadata =
          typeMetadata.firstWhere(_isDirectiveMetadata, orElse: () => null);
      if (isPresent(metadata)) {
        var propertyMetadata = this._reflector.propMetadata(type);
        return this
            ._mergeWithPropertyMetadata(metadata, propertyMetadata, type);
      }
    }
    throw new NoDirectiveAnnotationError(type);
  }

  DirectiveMetadata _mergeWithPropertyMetadata(DirectiveMetadata dm,
      Map<String, List<dynamic>> propertyMetadata, Type directiveType) {
    var inputs = [];
    var outputs = [];
    Map<String, String> host = {};
    Map<String, dynamic> queries = {};
    StringMapWrapper.forEach(propertyMetadata,
        (List<dynamic> metadata, String propName) {
      metadata.forEach((a) {
        if (a is InputMetadata) {
          if (isPresent(a.bindingPropertyName)) {
            inputs.add('''${ propName}: ${ a . bindingPropertyName}''');
          } else {
            inputs.add(propName);
          }
        }
        if (a is OutputMetadata) {
          if (isPresent(a.bindingPropertyName)) {
            outputs.add('''${ propName}: ${ a . bindingPropertyName}''');
          } else {
            outputs.add(propName);
          }
        }
        if (a is HostBindingMetadata) {
          if (isPresent(a.hostPropertyName)) {
            host['''[${ a . hostPropertyName}]'''] = propName;
          } else {
            host['''[${ propName}]'''] = propName;
          }
        }
        if (a is HostListenerMetadata) {
          var args =
              isPresent(a.args) ? ((a.args as List<dynamic>)).join(", ") : "";
          host['''(${ a . eventName})'''] = '''${ propName}(${ args})''';
        }
        if (a is ContentChildrenMetadata) {
          queries[propName] = a;
        }
        if (a is ViewChildrenMetadata) {
          queries[propName] = a;
        }
        if (a is ContentChildMetadata) {
          queries[propName] = a;
        }
        if (a is ViewChildMetadata) {
          queries[propName] = a;
        }
      });
    });
    return this._merge(dm, inputs, outputs, host, queries, directiveType);
  }

  DirectiveMetadata _merge(
      DirectiveMetadata dm,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      Map<String, dynamic> queries,
      Type directiveType) {
    var mergedInputs =
        isPresent(dm.inputs) ? ListWrapper.concat(dm.inputs, inputs) : inputs;
    var mergedOutputs;
    if (isPresent(dm.outputs)) {
      dm.outputs.forEach((String propName) {
        if (ListWrapper.contains(outputs, propName)) {
          throw new BaseException(
              '''Output event \'${ propName}\' defined multiple times in \'${ stringify ( directiveType )}\'''');
        }
      });
      mergedOutputs = ListWrapper.concat(dm.outputs, outputs);
    } else {
      mergedOutputs = outputs;
    }
    var mergedHost =
        isPresent(dm.host) ? StringMapWrapper.merge(dm.host, host) : host;
    var mergedQueries = isPresent(dm.queries)
        ? StringMapWrapper.merge(dm.queries, queries)
        : queries;
    if (dm is ComponentMetadata) {
      return new ComponentMetadata(
          selector: dm.selector,
          inputs: mergedInputs,
          outputs: mergedOutputs,
          host: mergedHost,
          exportAs: dm.exportAs,
          moduleId: dm.moduleId,
          queries: mergedQueries,
          changeDetection: dm.changeDetection,
          providers: dm.providers,
          viewProviders: dm.viewProviders);
    } else {
      return new DirectiveMetadata(
          selector: dm.selector,
          inputs: mergedInputs,
          outputs: mergedOutputs,
          host: mergedHost,
          exportAs: dm.exportAs,
          queries: mergedQueries,
          providers: dm.providers);
    }
  }
}
