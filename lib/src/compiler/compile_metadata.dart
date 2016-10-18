import "package:angular2/src/compiler/selector.dart" show CssSelector;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectionStrategy;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks, LIFECYCLE_HOOKS_VALUES;
import "package:angular2/src/core/metadata/view.dart"
    show ViewEncapsulation, VIEW_ENCAPSULATION_VALUES;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "compiler_utils.dart";
import "url_resolver.dart" show getUrlScheme;

// group 1: "property" from "[property]"
// group 2: "event" from "(event)"
var HOST_REG_EXP = new RegExp(r'^(?:(?:\[([^\]]+)\])|(?:\(([^\)]+)\)))$');

abstract class CompileMetadataWithIdentifier {
  Map<String, dynamic> toJson();
  CompileIdentifierMetadata get identifier;
}

abstract class CompileMetadataWithType extends CompileMetadataWithIdentifier {
  Map<String, dynamic> toJson();
  CompileTypeMetadata get type {
    throw new UnimplementedError();
  }

  CompileIdentifierMetadata get identifier;
}

dynamic metadataFromJson(Map<String, dynamic> data) {
  return _COMPILE_METADATA_FROM_JSON[data["class"]](data);
}

class CompileIdentifierMetadata<TRuntime>
    implements CompileMetadataWithIdentifier {
  String name;
  String prefix;
  String moduleUrl;
  dynamic value;

  /// [runtime] and [runtimeCallback] are used for Identifiers based access.
  ///
  /// Angular creates code from output ast(s) and at the same time provides
  /// a dynamic interpreter. The Interpreter is used for tests that need to
  /// override templates at runtime.
  ///
  /// To allow the interpreter to access values that are not
  /// available through reflection, [runtime] is used as a way to provide this
  /// value for the output interpreter.
  ///
  /// Not marked final since tests modify value.
  TRuntime runtime;

  /// Same as runtime but evaluates function before using value.
  final Function runtimeCallback;

  CompileIdentifierMetadata(
      {this.runtime,
      this.runtimeCallback,
      this.name,
      this.moduleUrl,
      this.prefix,
      this.value});

  static CompileIdentifierMetadata fromJson(Map<String, dynamic> data) {
    var value = data["value"] is List
        ? _arrayFromJson(data["value"], metadataFromJson)
        : _objFromJson(data["value"], metadataFromJson);
    return new CompileIdentifierMetadata(
        name: data["name"],
        prefix: data["prefix"],
        moduleUrl: data["moduleUrl"],
        value: value);
  }

  Map<String, dynamic> toJson() {
    var value =
        this.value is List ? _arrayToJson(this.value) : _objToJson(this.value);
    return {
      // Note: Runtime type can't be serialized...
      "class": "Identifier", "name": this.name, "moduleUrl": this.moduleUrl,
      "prefix": this.prefix, "value": value
    };
  }

  CompileIdentifierMetadata get identifier {
    return this;
  }
}

class CompileDiDependencyMetadata {
  bool isAttribute;
  bool isSelf;
  bool isHost;
  bool isSkipSelf;
  bool isOptional;
  bool isValue;
  CompileQueryMetadata query;
  CompileQueryMetadata viewQuery;
  CompileTokenMetadata token;
  dynamic value;
  CompileDiDependencyMetadata(
      {bool isAttribute,
      bool isSelf,
      bool isHost,
      bool isSkipSelf,
      bool isOptional,
      bool isValue,
      CompileQueryMetadata query,
      CompileQueryMetadata viewQuery,
      CompileTokenMetadata token,
      dynamic value}) {
    // TODO: Make the defaults of the constructor 'false' instead of doing this.
    // This is to prevent any breaking changes while cleaing up TS facades.
    this.isAttribute = isAttribute == true;
    this.isSelf = isSelf == true;
    this.isHost = isHost == true;
    this.isSkipSelf = isSkipSelf == true;
    this.isOptional = isOptional == true;
    this.isValue = isValue == true;
    this.query = query;
    this.viewQuery = viewQuery;
    this.token = token;
    this.value = value;
  }
  static CompileDiDependencyMetadata fromJson(Map<String, dynamic> data) {
    return new CompileDiDependencyMetadata(
        token: _objFromJson(data["token"], CompileTokenMetadata.fromJson),
        query: _objFromJson(data["query"], CompileQueryMetadata.fromJson),
        viewQuery:
            _objFromJson(data["viewQuery"], CompileQueryMetadata.fromJson),
        value: data["value"],
        isAttribute: data["isAttribute"],
        isSelf: data["isSelf"],
        isHost: data["isHost"],
        isSkipSelf: data["isSkipSelf"],
        isOptional: data["isOptional"],
        isValue: data["isValue"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "token": _objToJson(this.token),
      "query": _objToJson(this.query),
      "viewQuery": _objToJson(this.viewQuery),
      "value": this.value,
      "isAttribute": this.isAttribute,
      "isSelf": this.isSelf,
      "isHost": this.isHost,
      "isSkipSelf": this.isSkipSelf,
      "isOptional": this.isOptional,
      "isValue": this.isValue
    };
  }
}

class CompileProviderMetadata {
  CompileTokenMetadata token;
  CompileTypeMetadata useClass;
  dynamic useValue;
  CompileTokenMetadata useExisting;
  CompileFactoryMetadata useFactory;
  String useProperty;
  List<CompileDiDependencyMetadata> deps;
  bool multi;
  CompileProviderMetadata(
      {CompileTokenMetadata token,
      CompileTypeMetadata useClass,
      dynamic useValue,
      CompileTokenMetadata useExisting,
      CompileFactoryMetadata useFactory,
      String useProperty,
      List<CompileDiDependencyMetadata> deps,
      bool multi}) {
    this.token = token;
    this.useClass = useClass;
    this.useValue = useValue;
    this.useExisting = useExisting;
    this.useFactory = useFactory;
    this.useProperty = useProperty;
    this.deps = deps;
    this.multi = multi == true;
  }
  static CompileProviderMetadata fromJson(Map<String, dynamic> data) {
    return new CompileProviderMetadata(
        token: _objFromJson(data["token"], CompileTokenMetadata.fromJson),
        useClass: _objFromJson(data["useClass"], CompileTypeMetadata.fromJson),
        useExisting:
            _objFromJson(data["useExisting"], CompileTokenMetadata.fromJson),
        useValue:
            _objFromJson(data["useValue"], CompileIdentifierMetadata.fromJson),
        useFactory:
            _objFromJson(data["useFactory"], CompileFactoryMetadata.fromJson),
        useProperty: data["useProperty"],
        multi: data["multi"],
        deps: _arrayFromJson(data["deps"], CompileDiDependencyMetadata.fromJson)
            as List<CompileDiDependencyMetadata>);
  }

  Map<String, dynamic> toJson() {
    return {
      // Note: Runtime type can't be serialized...
      "class": "Provider",
      "token": _objToJson(this.token),
      "useClass": _objToJson(this.useClass),
      "useExisting": _objToJson(this.useExisting),
      "useValue": _objToJson(this.useValue),
      "useFactory": _objToJson(this.useFactory),
      "useProperty": this.useProperty,
      "multi": this.multi,
      "deps": _arrayToJson(this.deps)
    };
  }
}

class CompileFactoryMetadata
    implements
        CompileIdentifierMetadata<Function>,
        CompileMetadataWithIdentifier {
  Function runtime;
  Function runtimeCallback;
  String name;
  String prefix;
  String moduleUrl;
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  CompileFactoryMetadata(
      {Function runtime,
      String name,
      String moduleUrl,
      String prefix,
      List<CompileDiDependencyMetadata> diDeps,
      bool value}) {
    this.runtime = runtime;
    this.name = name;
    this.prefix = prefix;
    this.moduleUrl = moduleUrl;
    this.diDeps = diDeps ?? [];
    this.value = value;
  }
  CompileIdentifierMetadata get identifier {
    return this;
  }

  static CompileFactoryMetadata fromJson(Map<String, dynamic> data) {
    return new CompileFactoryMetadata(
        name: data["name"],
        prefix: data["prefix"],
        moduleUrl: data["moduleUrl"],
        value: data["value"],
        diDeps: (_arrayFromJson(
                data["diDeps"], CompileDiDependencyMetadata.fromJson))
            as List<CompileDiDependencyMetadata>);
  }

  Map<String, dynamic> toJson() {
    return {
      "class": "Factory",
      "name": this.name,
      "prefix": this.prefix,
      "moduleUrl": this.moduleUrl,
      "value": this.value,
      "diDeps": _arrayToJson(this.diDeps)
    };
  }
}

class CompileTokenMetadata implements CompileMetadataWithIdentifier {
  dynamic value;
  CompileIdentifierMetadata identifier;
  bool identifierIsInstance;
  CompileTokenMetadata(
      {dynamic value,
      CompileIdentifierMetadata identifier,
      bool identifierIsInstance}) {
    this.value = value;
    this.identifier = identifier;
    this.identifierIsInstance = identifierIsInstance == true;
  }
  static CompileTokenMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTokenMetadata(
        value: data["value"],
        identifier: _objFromJson(
            data["identifier"], CompileIdentifierMetadata.fromJson),
        identifierIsInstance: data["identifierIsInstance"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "value": this.value,
      "identifier": _objToJson(this.identifier),
      "identifierIsInstance": this.identifierIsInstance
    };
  }

  dynamic get runtimeCacheKey =>
      identifier != null ? identifier.runtime : value;

  dynamic get assetCacheKey {
    if (identifier != null) {
      return identifier.moduleUrl != null &&
              getUrlScheme(identifier.moduleUrl) != null
          ? '${identifier.name}|${identifier.moduleUrl}|${identifierIsInstance}'
          : null;
    } else {
      return this.value;
    }
  }

  bool equalsTo(CompileTokenMetadata token2) {
    var rk = this.runtimeCacheKey;
    var ak = this.assetCacheKey;
    return (rk != null && rk == token2.runtimeCacheKey) ||
        (ak != null && ak == token2.assetCacheKey);
  }

  String get name {
    return value != null ? sanitizeIdentifier(value) : identifier.name;
  }
}

class CompileTokenMap<VALUE> {
  var _valueMap = new Map<dynamic, VALUE>();
  List<VALUE> _values = [];
  List<CompileTokenMetadata> _tokens = [];
  void add(CompileTokenMetadata token, VALUE value) {
    var existing = this.get(token);
    if (existing != null) {
      throw new BaseException(
          '''Can only add to a TokenMap! Token: ${ token . name}''');
    }
    this._tokens.add(token);
    this._values.add(value);
    var rk = token.runtimeCacheKey;
    if (rk != null) {
      this._valueMap[rk] = value;
    }
    var ak = token.assetCacheKey;
    if (ak != null) {
      this._valueMap[ak] = value;
    }
  }

  VALUE get(CompileTokenMetadata token) {
    var rk = token.runtimeCacheKey;
    var ak = token.assetCacheKey;
    VALUE result;
    if (rk != null) {
      result = this._valueMap[rk];
    }
    if (result == null && ak != null) {
      result = this._valueMap[ak];
    }
    return result;
  }

  List<CompileTokenMetadata> keys() {
    return this._tokens;
  }

  List<VALUE> values() {
    return this._values;
  }

  num get size {
    return this._values.length;
  }
}

/// Metadata regarding compilation of a type.
class CompileTypeMetadata
    implements CompileIdentifierMetadata<Type>, CompileMetadataWithType {
  Type runtime;
  Function runtimeCallback;
  String name;
  String prefix;
  String moduleUrl;
  bool isHost;
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  CompileTypeMetadata(
      {Type runtime,
      String name,
      String moduleUrl,
      String prefix,
      bool isHost,
      dynamic value,
      List<CompileDiDependencyMetadata> diDeps}) {
    this.runtime = runtime;
    this.name = name;
    this.moduleUrl = moduleUrl;
    this.prefix = prefix;
    this.isHost = isHost == true;
    this.value = value;
    this.diDeps = diDeps ?? [];
  }
  static CompileTypeMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTypeMetadata(
        name: data["name"],
        moduleUrl: data["moduleUrl"],
        prefix: data["prefix"],
        isHost: data["isHost"],
        value: data["value"],
        diDeps:
            _arrayFromJson(data["diDeps"], CompileDiDependencyMetadata.fromJson)
            as List<CompileDiDependencyMetadata>);
  }

  CompileIdentifierMetadata get identifier {
    return this;
  }

  CompileTypeMetadata get type {
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      // Note: Runtime type can't be serialized...
      "class": "Type",
      "name": this.name,
      "moduleUrl": this.moduleUrl,
      "prefix": this.prefix,
      "isHost": this.isHost,
      "value": this.value,
      "diDeps": _arrayToJson(this.diDeps)
    };
  }
}

class CompileQueryMetadata {
  List<CompileTokenMetadata> selectors;
  bool descendants;
  bool first;
  String propertyName;
  CompileTokenMetadata read;
  CompileQueryMetadata(
      {List<CompileTokenMetadata> selectors,
      bool descendants,
      bool first,
      String propertyName,
      CompileTokenMetadata read}) {
    this.selectors = selectors;
    this.descendants = descendants == true;
    this.first = first == true;
    this.propertyName = propertyName;
    this.read = read;
  }
  static CompileQueryMetadata fromJson(Map<String, dynamic> data) {
    return new CompileQueryMetadata(
        selectors:
            _arrayFromJson(data["selectors"], CompileTokenMetadata.fromJson)
            as List<CompileTokenMetadata>,
        descendants: data["descendants"],
        first: data["first"],
        propertyName: data["propertyName"],
        read: _objFromJson(data["read"], CompileTokenMetadata.fromJson));
  }

  Map<String, dynamic> toJson() {
    return {
      "selectors": _arrayToJson(this.selectors),
      "descendants": this.descendants,
      "first": this.first,
      "propertyName": this.propertyName,
      "read": _objToJson(this.read)
    };
  }
}

/// Metadata regarding compilation of a template.
class CompileTemplateMetadata {
  ViewEncapsulation encapsulation;
  String template;
  String templateUrl;
  bool preserveWhitespace;
  List<String> styles;
  List<String> styleUrls;
  List<String> ngContentSelectors;
  CompileTemplateMetadata(
      {ViewEncapsulation encapsulation,
      this.template,
      this.templateUrl,
      bool preserveWhitespace,
      List<String> styles,
      List<String> styleUrls,
      List<String> ngContentSelectors}) {
    this.encapsulation = encapsulation ?? ViewEncapsulation.Emulated;
    this.styles = styles ?? <String>[];
    this.styleUrls = styleUrls ?? <String>[];
    this.ngContentSelectors = ngContentSelectors ?? <String>[];
    this.preserveWhitespace = preserveWhitespace ?? true;
  }

  static CompileTemplateMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTemplateMetadata(
        encapsulation: data["encapsulation"] != null
            ? VIEW_ENCAPSULATION_VALUES[data["encapsulation"]]
            : data["encapsulation"],
        template: data["template"],
        templateUrl: data["templateUrl"],
        preserveWhitespace: data["preserveWhitespace"] ?? true,
        styles: data["styles"] as List<String>,
        styleUrls: data["styleUrls"] as List<String>,
        ngContentSelectors: data["ngContentSelectors"] as List<String>);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {
      "encapsulation": encapsulation?.index,
      "template": this.template,
      "templateUrl": this.templateUrl,
      "styles": this.styles,
      "styleUrls": this.styleUrls,
      "ngContentSelectors": this.ngContentSelectors
    };
    if (preserveWhitespace == false) res["preserveWhitespace"] = false;
    return res;
  }
}

/// Metadata regarding compilation of a directive.
class CompileDirectiveMetadata implements CompileMetadataWithType {
  static CompileDirectiveMetadata create(
      {CompileTypeMetadata type,
      bool isComponent,
      String selector,
      String exportAs,
      ChangeDetectionStrategy changeDetection,
      List<String> inputs,
      List<String> outputs,
      Map<String, String> host,
      List<LifecycleHooks> lifecycleHooks,
      // CompileProviderMetadata | CompileTypeMetadata |
      // CompileIdentifierMetadata | List
      List providers,
      // CompileProviderMetadata | CompileTypeMetadata |
      // CompileIdentifierMetadata | List
      List viewProviders,
      List<CompileQueryMetadata> queries,
      List<CompileQueryMetadata> viewQueries,
      CompileTemplateMetadata template}) {
    var hostListeners = <String, String>{};
    var hostProperties = <String, String>{};
    var hostAttributes = <String, String>{};
    host?.forEach((String key, String value) {
      var matches = HOST_REG_EXP.firstMatch(key);
      if (matches == null) {
        hostAttributes[key] = value;
      } else if (matches[1] != null) {
        hostProperties[matches[1]] = value;
      } else if (matches[2] != null) {
        hostListeners[matches[2]] = value;
      }
    });

    Map<String, String> inputsMap = {};
    Map<String, String> inputTypeMap = {};
    inputs?.forEach((String bindConfig) {
      // Syntax: dirProp [; type] | dirProp : elProp [; type]
      // if there is no [:], use dirProp = elProp
      var parts = bindConfig.split(';');
      String typeName = parts.length > 1 ? parts[1] : null;
      String inputName = parts[0];
      var inputParts = splitAtColon(inputName, [inputName, inputName]);
      inputsMap[inputParts[0]] = inputParts[1];
      if (typeName != null) {
        inputTypeMap[inputParts[0]] = typeName;
      }
    });

    Map<String, String> outputsMap = {};
    outputs?.forEach((String bindConfig) {
      // canonical syntax: dirProp | dirProp : elProp
      // if there is no [:], use dirProp = elProp
      var parts = splitAtColon(bindConfig, [bindConfig, bindConfig]);
      outputsMap[parts[0]] = parts[1];
    });

    return new CompileDirectiveMetadata(
        type: type,
        isComponent: isComponent == true,
        selector: selector,
        exportAs: exportAs,
        changeDetection: changeDetection,
        inputs: inputsMap,
        inputTypes: inputTypeMap,
        outputs: outputsMap,
        hostListeners: hostListeners,
        hostProperties: hostProperties,
        hostAttributes: hostAttributes,
        lifecycleHooks: lifecycleHooks ?? <LifecycleHooks>[],
        providers: providers,
        viewProviders: viewProviders,
        queries: queries,
        viewQueries: viewQueries,
        template: template);
  }

  CompileTypeMetadata type;
  bool isComponent;
  String selector;
  String exportAs;
  ChangeDetectionStrategy changeDetection;
  Map<String, String> inputs;
  Map<String, String> inputTypes;
  Map<String, String> outputs;
  Map<String, String> hostListeners;
  Map<String, String> hostProperties;
  Map<String, String> hostAttributes;
  List<LifecycleHooks> lifecycleHooks;
  List<CompileProviderMetadata> providers;
  List<CompileProviderMetadata> viewProviders;
  List<CompileQueryMetadata> queries;
  List<CompileQueryMetadata> viewQueries;
  CompileTemplateMetadata template;
  CompileDirectiveMetadata(
      {this.type,
      this.isComponent,
      this.selector,
      this.exportAs,
      this.changeDetection,
      this.inputs,
      this.inputTypes,
      this.outputs,
      this.hostListeners,
      this.hostProperties,
      this.hostAttributes,
      List<LifecycleHooks> lifecycleHooks,
      // CompileProviderMetadata | CompileTypeMetadata |
      // CompileIdentifierMetadata | List
      List providers,
      // CompileProviderMetadata | CompileTypeMetadata |
      // CompileIdentifierMetadata | List
      List viewProviders,
      List<CompileQueryMetadata> queries,
      List<CompileQueryMetadata> viewQueries,
      CompileTemplateMetadata template}) {
    this.lifecycleHooks = lifecycleHooks ?? [];
    this.providers = providers as List<CompileProviderMetadata> ?? [];
    this.viewProviders = viewProviders as List<CompileProviderMetadata> ?? [];
    this.queries = queries ?? [];
    this.viewQueries = viewQueries ?? [];
    this.template = template;
  }

  CompileIdentifierMetadata get identifier => type;

  static CompileDirectiveMetadata fromJson(Map<String, dynamic> data) {
    return new CompileDirectiveMetadata(
        isComponent: data["isComponent"],
        selector: data["selector"],
        exportAs: data["exportAs"],
        type: data["type"] != null
            ? CompileTypeMetadata.fromJson(data["type"] as Map<String, dynamic>)
            : data["type"],
        changeDetection: data["changeDetection"] != null
            ? ChangeDetectionStrategy.values[data["changeDetection"]]
            : null,
        inputs: data["inputs"] as Map<String, String>,
        inputTypes: data["inputTypes"] as Map<String, String>,
        outputs: data["outputs"] as Map<String, String>,
        hostListeners: data["hostListeners"] as Map<String, String>,
        hostProperties: data["hostProperties"] as Map<String, String>,
        hostAttributes: data["hostAttributes"] as Map<String, String>,
        lifecycleHooks: ((data["lifecycleHooks"] as List<dynamic>))
            .map((hookValue) => LIFECYCLE_HOOKS_VALUES[hookValue])
            .toList(),
        template: data["template"] != null
            ? CompileTemplateMetadata
                .fromJson(data["template"] as Map<String, dynamic>)
            : data["template"],
        providers: _arrayFromJson(data["providers"], metadataFromJson),
        viewProviders: _arrayFromJson(data["viewProviders"], metadataFromJson),
        queries: _arrayFromJson(data["queries"], CompileQueryMetadata.fromJson)
            as List<CompileQueryMetadata>,
        viewQueries:
            _arrayFromJson(data["viewQueries"], CompileQueryMetadata.fromJson)
            as List<CompileQueryMetadata>);
  }

  Map<String, dynamic> toJson() {
    return {
      "class": "Directive",
      "isComponent": isComponent,
      "selector": selector,
      "exportAs": exportAs,
      "type": type?.toJson(),
      "changeDetection": changeDetection?.index,
      "inputs": inputs,
      "inputTypes": inputTypes,
      "outputs": outputs,
      "hostListeners": hostListeners,
      "hostProperties": hostProperties,
      "hostAttributes": hostAttributes,
      "lifecycleHooks": lifecycleHooks.map((hook) => hook.index).toList(),
      "template": template?.toJson(),
      "providers": _arrayToJson(providers),
      "viewProviders": _arrayToJson(viewProviders),
      "queries": _arrayToJson(queries),
      "viewQueries": _arrayToJson(viewQueries)
    };
  }
}

/// Construct [CompileDirectiveMetadata] from [ComponentTypeMetadata] and a
/// selector.
CompileDirectiveMetadata createHostComponentMeta(
    CompileTypeMetadata componentType,
    String componentSelector,
    bool preserveWhitespace) {
  var template =
      CssSelector.parse(componentSelector)[0].getMatchingElementTemplate();
  return CompileDirectiveMetadata.create(
      type: new CompileTypeMetadata(
          runtime: Object,
          name: '${componentType.name}Host',
          moduleUrl: componentType.moduleUrl,
          isHost: true),
      template: new CompileTemplateMetadata(
          template: template,
          templateUrl: "",
          preserveWhitespace: preserveWhitespace,
          styles: [],
          styleUrls: [],
          ngContentSelectors: []),
      changeDetection: ChangeDetectionStrategy.Default,
      inputs: [],
      outputs: [],
      host: {},
      lifecycleHooks: [],
      isComponent: true,
      selector: "*",
      providers: [],
      viewProviders: [],
      queries: [],
      viewQueries: []);
}

class CompilePipeMetadata implements CompileMetadataWithType {
  CompileTypeMetadata type;
  String name;
  bool pure;
  List<LifecycleHooks> lifecycleHooks;
  CompilePipeMetadata(
      {CompileTypeMetadata type,
      String name,
      bool pure,
      List<LifecycleHooks> lifecycleHooks}) {
    this.type = type;
    this.name = name;
    this.pure = pure ?? true;
    this.lifecycleHooks = lifecycleHooks ?? [];
  }
  CompileIdentifierMetadata get identifier {
    return this.type;
  }

  static CompilePipeMetadata fromJson(Map<String, dynamic> data) {
    return new CompilePipeMetadata(
        type: data["type"] != null
            ? CompileTypeMetadata.fromJson(data["type"] as Map<String, dynamic>)
            : data["type"],
        name: data["name"],
        pure: data["pure"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "class": "Pipe",
      "type": type?.toJson(),
      "name": name,
      "pure": pure
    };
  }
}

/// Metadata regarding compilation of an InjectorModule.
class CompileInjectorModuleMetadata
    implements CompileMetadataWithType, CompileTypeMetadata {
  Type runtime;
  Function runtimeCallback;
  String name;
  String prefix;
  String moduleUrl;
  var isHost = false;
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  bool injectable;
  // CompileProviderMetadata | CompileTypeMetadata | CompileIdentifierMetadata
  // | List
  List<dynamic /*  < dynamic > */ > providers;
  CompileInjectorModuleMetadata(
      {Type runtime,
      String name,
      String moduleUrl,
      String prefix,
      dynamic value,
      List<CompileDiDependencyMetadata> diDeps,
      // CompileProviderMetadata | CompileTypeMetadata |
      // CompileIdentifierMetadata | List
      List providers,
      bool injectable}) {
    this.runtime = runtime;
    this.name = name;
    this.moduleUrl = moduleUrl;
    this.prefix = prefix;
    this.value = value;
    this.diDeps = diDeps ?? [];
    this.providers = providers ?? [];
    this.injectable = injectable == true;
  }
  static CompileInjectorModuleMetadata fromJson(Map<String, dynamic> data) {
    return new CompileInjectorModuleMetadata(
        name: data["name"],
        moduleUrl: data["moduleUrl"],
        prefix: data["prefix"],
        value: data["value"],
        diDeps:
            _arrayFromJson(data["diDeps"], CompileDiDependencyMetadata.fromJson)
            as List<CompileDiDependencyMetadata>,
        providers: _arrayFromJson(data["providers"], metadataFromJson),
        injectable: data["injectable"]);
  }

  CompileIdentifierMetadata get identifier {
    return this;
  }

  CompileInjectorModuleMetadata get type {
    return this;
  }

  Map<String, dynamic> toJson() {
    return {
      // Note: Runtime type can't be serialized...
      "class": "InjectorModule",
      "name": this.name,
      "moduleUrl": this.moduleUrl,
      "prefix": this.prefix,
      "isHost": this.isHost,
      "value": this.value,
      "diDeps": _arrayToJson(this.diDeps),
      "providers": _arrayToJson(this.providers),
      "injectable": this.injectable
    };
  }
}

var _COMPILE_METADATA_FROM_JSON = {
  "Directive": CompileDirectiveMetadata.fromJson,
  "Pipe": CompilePipeMetadata.fromJson,
  "Type": CompileTypeMetadata.fromJson,
  "Provider": CompileProviderMetadata.fromJson,
  "Identifier": CompileIdentifierMetadata.fromJson,
  "Factory": CompileFactoryMetadata.fromJson,
  "InjectorModule": CompileInjectorModuleMetadata.fromJson
};

dynamic _arrayFromJson(List<dynamic> obj, dynamic fn(Map<String, dynamic> a)) {
  return obj == null ? null : obj.map((o) => _objFromJson(o, fn)).toList();
}

dynamic /* String | Map < String , dynamic > */ _arrayToJson(
    List<dynamic> obj) {
  return obj == null ? null : obj.map(_objToJson).toList();
}

dynamic _objFromJson(dynamic obj, dynamic fn(Map<String, dynamic> a)) {
  if (obj is List) return _arrayFromJson(obj, fn);
  if (obj is String || obj == null || obj is bool || obj is num) return obj;
  return fn(obj as Map<String, dynamic>);
}

dynamic /* String | Map < String , dynamic > */ _objToJson(dynamic obj) {
  if (obj is List) return _arrayToJson(obj);
  if (obj is String || obj == null || obj is bool || obj is num) return obj;
  return obj.toJson();
}
