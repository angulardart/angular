import "package:angular2/src/core/di.dart" show Injectable;
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
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

bool _isDirectiveMetadata(dynamic type) {
  return type is DirectiveMetadata;
}

class NoDirectiveAnnotationError extends BaseException {
  NoDirectiveAnnotationError(Type type)
      : super('No Directive annotation found on $type') {}
}

/// Resolve a [Type] for [DirectiveMetadata].
///
/// This interface can be overridden by the application developer
/// to create custom behavior.
///
/// See [Compiler]
///
@Injectable()
class DirectiveResolver {
  ReflectorReader _reflector;
  DirectiveResolver([ReflectorReader _reflector]) {
    this._reflector = _reflector ?? reflector;
  }

  /// Return [DirectiveMetadata] for a given `Type`.
  DirectiveMetadata resolve(Type type) {
    var typeMetadata = _reflector.annotations(type);
    if (typeMetadata != null) {
      var metadata =
          typeMetadata.firstWhere(_isDirectiveMetadata, orElse: () => null);
      if (metadata != null) {
        var propertyMetadata = _reflector.propMetadata(type);
        return _mergeWithPropertyMetadata(metadata, propertyMetadata, type);
      }
    }
    throw new NoDirectiveAnnotationError(type);
  }

  DirectiveMetadata _mergeWithPropertyMetadata(DirectiveMetadata dm,
      Map<String, List<dynamic>> propertyMetadata, Type directiveType) {
    var inputs = <String>[];
    var outputs = <String>[];
    Map<String, String> host = {};
    Map<String, dynamic> queries = {};
    propertyMetadata.forEach((String propName, List<dynamic> metadata) {
      metadata.forEach((a) {
        if (a is InputMetadata) {
          if (a.bindingPropertyName != null) {
            inputs.add('${propName}: ${a.bindingPropertyName}');
          } else {
            inputs.add(propName);
          }
        }
        if (a is OutputMetadata) {
          if (a.bindingPropertyName != null) {
            outputs.add('${propName}: ${a.bindingPropertyName}');
          } else {
            outputs.add(propName);
          }
        }
        if (a is HostBindingMetadata) {
          if (a.hostPropertyName != null) {
            host['[${a.hostPropertyName}]'] = propName;
          } else {
            host['[$propName]'] = propName;
          }
        }
        if (a is HostListenerMetadata) {
          var args = a.args?.join(", ") ?? '';
          host['(${a.eventName})'] = '${propName}(${args})';
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
    List<String> mergedInputs =
        dm.inputs != null ? ListWrapper.concat(dm.inputs, inputs) : inputs;
    List<String> mergedOutputs;
    if (dm.outputs != null) {
      dm.outputs.forEach((String propName) {
        if (outputs.contains(propName)) {
          throw new BaseException(
              "Output event '${ propName}' defined multiple times "
              "in '${directiveType}'");
        }
      });
      mergedOutputs = ListWrapper.concat(dm.outputs, outputs);
    } else {
      mergedOutputs = outputs;
    }
    var mergedHost =
        dm.host != null ? StringMapWrapper.merge(dm.host, host) : host;
    var mergedQueries = dm.queries != null
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
          viewProviders: dm.viewProviders,
          preserveWhitespace: dm.preserveWhitespace);
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
