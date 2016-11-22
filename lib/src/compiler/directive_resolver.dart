import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/metadata.dart";
import "package:angular2/src/core/reflection/reflection.dart"
    show Reflector, reflector;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

bool _isDirectiveMetadata(dynamic type) {
  return type is Directive;
}

class NoDirectiveAnnotationError extends BaseException {
  NoDirectiveAnnotationError(Type type)
      : super('No Directive annotation found on $type');
}

/// Resolve a [Type] for [Directive].
///
/// This interface can be overridden by the application developer
/// to create custom behavior.
///
/// See [Compiler]
///
@Injectable()
class DirectiveResolver {
  Reflector _reflector;

  DirectiveResolver([Reflector _reflector]) {
    this._reflector = _reflector ?? reflector;
  }

  /// Return [Directive] for a given `Type`.
  Directive resolve(Type type) {
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

  Directive _mergeWithPropertyMetadata(Directive dm,
      Map<String, List<dynamic>> propertyMetadata, Type directiveType) {
    var inputs = <String>[];
    var outputs = <String>[];
    Map<String, String> host = {};
    Map<String, dynamic> queries = {};
    propertyMetadata.forEach((String propName, List<dynamic> metadata) {
      metadata.forEach((a) {
        if (a is Input) {
          if (a.bindingPropertyName != null) {
            inputs.add('${propName}: ${a.bindingPropertyName}');
          } else {
            inputs.add(propName);
          }
        }
        if (a is Output) {
          if (a.bindingPropertyName != null) {
            outputs.add('${propName}: ${a.bindingPropertyName}');
          } else {
            outputs.add(propName);
          }
        }
        if (a is HostBinding) {
          if (a.hostPropertyName != null) {
            if (a.hostPropertyName.startsWith('(')) {
              throw new Exception('@HostBinding can not bind to events. '
                  'Use @HostListener instead.');
            } else if (a.hostPropertyName.startsWith('[')) {
              throw new Exception(
                  '@HostBinding parameter should be a property name, '
                  '\'class.<name>\', or \'attr.<name>\'.');
            }
            host['[${a.hostPropertyName}]'] = propName;
          } else {
            host['[$propName]'] = propName;
          }
        }
        if (a is HostListener) {
          var args = a.args?.join(", ") ?? '';
          host['(${a.eventName})'] = '${propName}(${args})';
        }
        if (a is ContentChildren) {
          queries[propName] = a;
        }
        if (a is ViewChildren) {
          queries[propName] = a;
        }
        if (a is ContentChild) {
          queries[propName] = a;
        }
        if (a is ViewChild) {
          queries[propName] = a;
        }
      });
    });
    return this._merge(dm, inputs, outputs, host, queries, directiveType);
  }

  Directive _merge(
      Directive dm,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      Map<String, dynamic> queries,
      Type directiveType) {
    List<String> mergedInputs =
        dm.inputs != null ? (new List.from(dm.inputs)..addAll(inputs)) : inputs;
    List<String> mergedOutputs;
    if (dm.outputs != null) {
      dm.outputs.forEach((String propName) {
        if (outputs.contains(propName)) {
          throw new BaseException(
              "Output event '${ propName}' defined multiple times "
              "in '${directiveType}'");
        }
      });
      mergedOutputs = new List.from(dm.outputs)..addAll(outputs);
    } else {
      mergedOutputs = outputs;
    }
    var mergedHost = new Map<String, String>.from(dm.host ?? const {});
    mergedHost.addAll(host);
    var mergedQueries = new Map<String, dynamic>.from(dm.queries ?? const {});
    mergedQueries.addAll(queries);
    if (dm is Component) {
      return new Component(
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
      return new Directive(
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
