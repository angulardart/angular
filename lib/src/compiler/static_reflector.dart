import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/facade/lang.dart' show isPrimitive;

/// The host of the static resolver is expected to be able to provide module metadata in the form of
/// ModuleMetadata. Angular 2 CLI will produce this metadata for a module whenever a .d.ts files is
/// produced and the module has exported variables or classes with decorators. Module metadata can
/// also be produced directly from TypeScript sources by using MetadataCollector in tools/metadata.
abstract class StaticReflectorHost {
  /// Return a ModuleMetadata for the give module.
  /// module import of an import statement.
  Map<String, dynamic> getMetadataFor(String moduleId);
}

/// A token representing the a reference to a static type.
///
/// This token is unique for a moduleId and name and can be used as a hash table key.
class StaticType {
  String moduleId;
  String name;
  StaticType(this.moduleId, this.name);
}

/// A static reflector implements enough of the Reflector API that is necessary to compile
/// templates statically.
class StaticReflector {
  StaticReflectorHost host;
  var typeCache = new Map<String, StaticType>();
  var annotationCache = new Map<StaticType, List<dynamic>>();
  var propertyCache = new Map<StaticType, Map<String, dynamic>>();
  var parameterCache = new Map<StaticType, List<dynamic>>();
  var metadataCache = new Map<String, Map<String, dynamic>>();
  StaticReflector(this.host) {
    this.initializeConversionMap();
  }

  /// getStatictype produces a Type whose metadata is known but whose implementation is not loaded.
  /// All types passed to the StaticResolver should be pseudo-types returned by this method.
  StaticType getStaticType(String moduleId, String name) {
    var key = '''"${ moduleId}".${ name}''';
    var result = this.typeCache[key];
    if (result == null) {
      result = new StaticType(moduleId, name);
      this.typeCache[key] = result;
    }
    return result;
  }

  List<dynamic> annotations(StaticType type) {
    var annotations = this.annotationCache[type];
    if (annotations == null) {
      var classMetadata = this.getTypeMetadata(type);
      if (classMetadata["decorators"] != null) {
        annotations = ((classMetadata["decorators"] as List<dynamic>))
            .map((Map<String, dynamic> decorator) =>
                this.convertKnownDecorator(type.moduleId, decorator))
            .toList()
            .where((decorator) => decorator != null)
            .toList();
      } else {
        annotations = [];
      }
      this.annotationCache[type] = annotations;
    }
    return annotations;
  }

  Map<String, dynamic> propMetadata(StaticType type) {
    var propMetadata = this.propertyCache[type];
    if (propMetadata == null) {
      var classMetadata = this.getTypeMetadata(type);
      propMetadata = this.getPropertyMetadata(type.moduleId,
              classMetadata["members"] as Map<String, dynamic>) ??
          {};
      this.propertyCache[type] = propMetadata;
    }
    return propMetadata;
  }

  List<dynamic> parameters(StaticType type) {
    var parameters = this.parameterCache[type];
    if (parameters == null) {
      var classMetadata = this.getTypeMetadata(type);
      if (classMetadata != null) {
        var members = classMetadata["members"];
        if (members != null) {
          var ctorData = members["___ctor__"];
          if (ctorData != null) {
            var ctor = ((ctorData as List<dynamic>)).firstWhere(
                (a) => identical(a["___symbolic"], "constructor"),
                orElse: () => null);
            parameters = this.simplify(type.moduleId, ctor["parameters"]);
          }
        }
      }
      if (parameters == null) {
        parameters = [];
      }
      this.parameterCache[type] = parameters;
    }
    return parameters;
  }

  var conversionMap = new Map<StaticType,
      dynamic /* (moduleContext: string, expression: any) => any */ >();
  dynamic initializeConversionMap() {
    var core_metadata = "angular2/src/core/metadata";
    var conversionMap = this.conversionMap;
    conversionMap[this.getStaticType(core_metadata, "Directive")] =
        (moduleContext, expression) {
      var p0 = getDecoratorParameter(
              moduleContext, expression as Map<String, dynamic>, 0) ??
          {};
      return new Directive(
          selector: p0["selector"],
          inputs: p0["inputs"] as List<String>,
          outputs: p0["outputs"] as List<String>,
          host: p0["host"] as Map<String, String>,
          providers: p0["providers"],
          exportAs: p0["exportAs"],
          queries: p0["queries"] as Map<String, dynamic>);
    };
    conversionMap[this.getStaticType(core_metadata, "Component")] =
        (moduleContext, Map<String, dynamic> expression) {
      var p0 = getDecoratorParameter(moduleContext, expression, 0);
      p0 ??= {};
      return new Component(
          selector: p0["selector"],
          inputs: p0["inputs"] as List<String>,
          outputs: p0["outputs"] as List<String>,
          host: p0["host"] as Map<String, String>,
          exportAs: p0["exportAs"],
          moduleId: p0["moduleId"],
          providers: p0["providers"],
          viewBindings: p0["viewBindings"],
          viewProviders: p0["viewProviders"],
          changeDetection: p0["changeDetection"],
          queries: p0["queries"] as Map<String, dynamic>,
          templateUrl: p0["templateUrl"],
          template: p0["template"],
          preserveWhitespace: p0["preserveWhitespace"] ?? true,
          styleUrls: p0["styleUrls"] as List<String>,
          styles: p0["styles"] as List<String>,
          directives: p0["directives"],
          pipes: p0["pipes"],
          encapsulation: p0["encapsulation"]);
    };
    conversionMap[this.getStaticType(core_metadata, "Input")] =
        (moduleContext, Map<String, dynamic> expression) =>
            new Input(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "Output")] =
        (moduleContext, Map<String, dynamic> expression) =>
            new Output(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "View")] =
        (moduleContext, Map<String, dynamic> expression) {
      var p0 = getDecoratorParameter(moduleContext, expression, 0) ?? {};
      return new View(
          templateUrl: p0["templateUrl"],
          template: p0["template"],
          directives: p0["directives"],
          pipes: p0["pipes"],
          encapsulation: p0["encapsulation"],
          styles: p0["styles"] as List<String>);
    };
    conversionMap[this.getStaticType(core_metadata, "Attribute")] =
        (moduleContext, Map<String, dynamic> expression) =>
            new Attribute(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "Query")] =
        (moduleContext, Map<String, dynamic> expression) {
      var p0 = getDecoratorParameter(moduleContext, expression, 0);
      var p1 = getDecoratorParameter(moduleContext, expression, 1) ?? {};
      return new Query(p0, descendants: p1.descendants, first: p1.first);
    };
    conversionMap[this.getStaticType(core_metadata, "ContentChildren")] =
        (moduleContext, Map<String, dynamic> expression) => new ContentChildren(
            getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[
        this.getStaticType(core_metadata, "ContentChild")] = (moduleContext,
            Map<String, dynamic> expression) =>
        new ContentChild(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[
        this.getStaticType(core_metadata, "ViewChildren")] = (moduleContext,
            Map<String, dynamic> expression) =>
        new ViewChildren(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "ViewChild")] =
        (moduleContext, Map<String, dynamic> expression) =>
            new ViewChild(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "ViewQuery")] =
        (moduleContext, Map<String, dynamic> expression) {
      var p0 = getDecoratorParameter(moduleContext, expression, 0);
      var p1 = getDecoratorParameter(moduleContext, expression, 1) ?? {};
      return new ViewQuery(p0,
          descendants: p1["descendants"], first: p1["first"]);
    };
    conversionMap[this.getStaticType(core_metadata, "Pipe")] =
        (moduleContext, Map<String, dynamic> expression) {
      var p0 = getDecoratorParameter(moduleContext, expression, 0) ?? {};
      return new Pipe(name: p0["name"], pure: p0["pure"]);
    };
    conversionMap[
        this.getStaticType(core_metadata, "HostBinding")] = (moduleContext,
            Map<String, dynamic> expression) =>
        new HostBinding(getDecoratorParameter(moduleContext, expression, 0));
    conversionMap[this.getStaticType(core_metadata, "HostListener")] =
        (moduleContext, Map<String, dynamic> expression) => new HostListener(
            getDecoratorParameter(moduleContext, expression, 0),
            getDecoratorParameter(moduleContext, expression, 1)
            as List<String>);
    return null;
  }

  dynamic convertKnownDecorator(
      String moduleContext, Map<String, dynamic> expression) {
    var converter =
        this.conversionMap[this.getDecoratorType(moduleContext, expression)];
    if (converter != null) return converter(moduleContext, expression);
    return null;
  }

  StaticType getDecoratorType(
      String moduleContext, Map<String, dynamic> expression) {
    if (isMetadataSymbolicCallExpression(expression)) {
      var target = expression["expression"];
      if (isMetadataSymbolicReferenceExpression(target)) {
        var moduleId =
            this.normalizeModuleName(moduleContext, target["module"]);
        return this.getStaticType(moduleId, target["name"]);
      }
    }
    return null;
  }

  dynamic getDecoratorParameter(
      String moduleContext, Map<String, dynamic> expression, num index) {
    if (isMetadataSymbolicCallExpression(expression) &&
        expression["arguments"] != null &&
        ((expression["arguments"] as List<dynamic>)).length <= index + 1) {
      return this.simplify(
          moduleContext, ((expression["arguments"] as List<dynamic>))[index]);
    }
    return null;
  }

  Map<String, dynamic> getPropertyMetadata(
      String moduleContext, Map<String, dynamic> value) {
    if (value != null) {
      var result = <String, List>{};
      value.forEach((name, List<Map<String, dynamic>> value) {
        var data = this.getMemberData(moduleContext, value);
        if (data != null) {
          var propertyData = data
              .where((d) => d["kind"] == "property")
              .toList()
              .map((d) => d["directives"])
              .toList()
              .fold([],
                  (p, c) => (new List.from(p)..addAll((c as List<dynamic>))));
          if (propertyData.length != 0) {
            result[name] = propertyData;
          }
        }
      });
      return result;
    }
    return {};
  }

  // clang-format off
  List<Map<String, dynamic>> getMemberData(
      String moduleContext, List<Map<String, dynamic>> member) {
    // clang-format on
    var result = <Map<String, dynamic>>[];
    if (member != null) {
      for (var item in member) {
        result.add({
          "kind": item["___symbolic"],
          "directives": item["decorators"] != null
              ? ((item["decorators"] as List<dynamic>))
                  .map((Map<String, dynamic> decorator) =>
                      this.convertKnownDecorator(moduleContext, decorator))
                  .toList()
                  .where((d) => d != null)
                  .toList()
              : null
        });
      }
    }
    return result;
  }

  /** @internal */
  dynamic simplify(String moduleContext, dynamic value) {
    var _this = this;
    dynamic simplify(dynamic expression) {
      if (isPrimitive(expression)) {
        return expression;
      }
      if (expression is List) {
        var result = [];
        for (var item in ((expression as dynamic))) {
          result.add(simplify(item));
        }
        return result;
      }
      if (expression != null) {
        String symbol = expression["___symbolic"];
        if (symbol != null) {
          switch (symbol) {
            case "binop":
              var left = simplify(expression["left"]);
              var right = simplify(expression["right"]);
              switch (expression["operator"]) {
                case "&&":
                  return left && right;
                case "||":
                  return left || right;
                case "|":
                  return (left as int) | (right as int);
                case "^":
                  return (left as int) ^ (right as int);
                case "&":
                  return (left as int) & (right as int);
                case "==":
                  return left == right;
                case "!=":
                  return left != right;
                case "===":
                  return identical(left, right);
                case "!==":
                  return !identical(left, right);
                case "<":
                  return left < right;
                case ">":
                  return left > right;
                case "<=":
                  return left <= right;
                case ">=":
                  return left >= right;
                case "<<":
                  return (left as int) << (right as int);
                case ">>":
                  return (left as int) >> (right as int);
                case "+":
                  return left + right;
                case "-":
                  return left - right;
                case "*":
                  return left * right;
                case "/":
                  return left / right;
                case "%":
                  return left % right;
              }
              return null;
            case "pre":
              var operand = simplify(expression["operand"]);
              switch (expression["operator"]) {
                case "+":
                  return operand;
                case "-":
                  return -operand;
                case "!":
                  return !operand;
                case "~":
                  return ~(operand as int);
              }
              return null;
            case "index":
              var indexTarget = simplify(expression["expression"]);
              var index = simplify(expression["index"]);
              if (indexTarget != null && isPrimitive(index))
                return indexTarget[index];
              return null;
            case "select":
              var selectTarget = simplify(expression["expression"]);
              var member = simplify(expression["member"]);
              if (selectTarget != null && isPrimitive(member))
                return selectTarget[member];
              return null;
            case "reference":
              var referenceModuleName = _this.normalizeModuleName(
                  moduleContext, expression["module"]);
              var referenceModule =
                  _this.getModuleMetadata(referenceModuleName);
              var referenceValue =
                  referenceModule["metadata"][expression["name"]];
              if (isClassMetadata(referenceValue)) {
                // Convert to a pseudo type
                return _this.getStaticType(
                    referenceModuleName, expression["name"]);
              }
              return _this.simplify(referenceModuleName, referenceValue);
            case "call":
              return null;
          }
          return null;
        }
        var result = {};
        expression.forEach((name, value) {
          result[name] = simplify(value);
        });
        return result;
      }
      return null;
    }

    return simplify(value);
  }

  Map<String, dynamic> getModuleMetadata(String module) {
    var moduleMetadata = this.metadataCache[module];
    if (moduleMetadata == null) {
      moduleMetadata = this.host.getMetadataFor(module);
      if (moduleMetadata == null) {
        moduleMetadata = {
          "___symbolic": "module",
          "module": module,
          "metadata": {}
        };
      }
      this.metadataCache[module] = moduleMetadata;
    }
    return moduleMetadata;
  }

  Map<String, dynamic> getTypeMetadata(StaticType type) {
    var moduleMetadata = this.getModuleMetadata(type.moduleId);
    var result = moduleMetadata["metadata"][type.name] as Map<String, dynamic>;
    return result ?? {"___symbolic": "class"};
  }

  String normalizeModuleName(String from, String to) {
    if (to.startsWith(".")) {
      return pathTo(from, to);
    }
    return to;
  }
}

bool isMetadataSymbolicCallExpression(dynamic expression) {
  return !isPrimitive(expression) &&
      expression is! List &&
      expression["___symbolic"] == "call";
}

bool isMetadataSymbolicReferenceExpression(dynamic expression) {
  return !isPrimitive(expression) &&
      expression is! List &&
      expression["___symbolic"] == "reference";
}

bool isClassMetadata(dynamic expression) {
  return !isPrimitive(expression) &&
      expression is! List &&
      expression["___symbolic"] == "class";
}

List<String> splitPath(String path) {
  return path.split(new RegExp(r'\/|\\'));
}

String resolvePath(List<String> pathParts) {
  var result = [];
  var index = -1;
  pathParts.forEach((part) {
    index++;
    switch (part) {
      case "":
      case ".":
        if (index > 0) return;
        break;
      case "..":
        if (index > 0 && result.length != 0) result.removeLast();
        return;
    }
    result.add(part);
  });
  return result.join("/");
}

String pathTo(String from, String to) {
  var result = to;
  if (to.startsWith(".")) {
    var fromParts = splitPath(from);
    fromParts.removeLast();
    var toParts = splitPath(to);
    result = resolvePath((new List.from(fromParts)..addAll(toParts)));
  }
  return result;
}
