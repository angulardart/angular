import "package:angular2/src/compiler/selector.dart" show CssSelector;
import "package:angular2/src/core/change_detection/change_detection.dart"
    show ChangeDetectionStrategy, CHANGE_DETECTION_STRATEGY_VALUES;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks, LIFECYCLE_HOOKS_VALUES;
import "package:angular2/src/core/metadata/view.dart"
    show ViewEncapsulation, VIEW_ENCAPSULATION_VALUES;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show
        isPresent,
        isBlank,
        isNumber,
        isBoolean,
        normalizeBool,
        serializeEnum,
        isString,
        RegExpWrapper,
        isArray;

import "url_resolver.dart" show getUrlScheme;
import "util.dart" show splitAtColon, sanitizeIdentifier;

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

class CompileIdentifierMetadata implements CompileMetadataWithIdentifier {
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
  dynamic runtime;

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
    var value = isArray(data["value"])
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
        isArray(this.value) ? _arrayToJson(this.value) : _objToJson(this.value);
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
    this.isAttribute = normalizeBool(isAttribute);
    this.isSelf = normalizeBool(isSelf);
    this.isHost = normalizeBool(isHost);
    this.isSkipSelf = normalizeBool(isSkipSelf);
    this.isOptional = normalizeBool(isOptional);
    this.isValue = normalizeBool(isValue);
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
    this.multi = normalizeBool(multi);
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
    implements CompileIdentifierMetadata, CompileMetadataWithIdentifier {
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
    this.identifierIsInstance = normalizeBool(identifierIsInstance);
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

  dynamic get runtimeCacheKey {
    if (isPresent(this.identifier)) {
      return this.identifier.runtime;
    } else {
      return this.value;
    }
  }

  dynamic get assetCacheKey {
    if (isPresent(this.identifier)) {
      return isPresent(this.identifier.moduleUrl) &&
              isPresent(getUrlScheme(this.identifier.moduleUrl))
          ? '''${ this . identifier . name}|${ this . identifier . moduleUrl}|${ this . identifierIsInstance}'''
          : null;
    } else {
      return this.value;
    }
  }

  bool equalsTo(CompileTokenMetadata token2) {
    var rk = this.runtimeCacheKey;
    var ak = this.assetCacheKey;
    return (isPresent(rk) && rk == token2.runtimeCacheKey) ||
        (isPresent(ak) && ak == token2.assetCacheKey);
  }

  String get name {
    return isPresent(this.value)
        ? sanitizeIdentifier(this.value)
        : this.identifier.name;
  }
}

class CompileTokenMap<VALUE> {
  var _valueMap = new Map<dynamic, VALUE>();
  List<VALUE> _values = [];
  List<CompileTokenMetadata> _tokens = [];
  add(CompileTokenMetadata token, VALUE value) {
    var existing = this.get(token);
    if (isPresent(existing)) {
      throw new BaseException(
          '''Can only add to a TokenMap! Token: ${ token . name}''');
    }
    this._tokens.add(token);
    this._values.add(value);
    var rk = token.runtimeCacheKey;
    if (isPresent(rk)) {
      this._valueMap[rk] = value;
    }
    var ak = token.assetCacheKey;
    if (isPresent(ak)) {
      this._valueMap[ak] = value;
    }
  }

  VALUE get(CompileTokenMetadata token) {
    var rk = token.runtimeCacheKey;
    var ak = token.assetCacheKey;
    VALUE result;
    if (isPresent(rk)) {
      result = this._valueMap[rk];
    }
    if (isBlank(result) && isPresent(ak)) {
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

/**
 * Metadata regarding compilation of a type.
 */
class CompileTypeMetadata
    implements CompileIdentifierMetadata, CompileMetadataWithType {
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
    this.isHost = normalizeBool(isHost);
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
    this.descendants = normalizeBool(descendants);
    this.first = normalizeBool(first);
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
    this.preserveWhitespace = preserveWhitespace ?? false;
  }

  static CompileTemplateMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTemplateMetadata(
        encapsulation: isPresent(data["encapsulation"])
            ? VIEW_ENCAPSULATION_VALUES[data["encapsulation"]]
            : data["encapsulation"],
        template: data["template"],
        templateUrl: data["templateUrl"],
        preserveWhitespace: data["preserveWhitespace"] ?? false,
        styles: data["styles"] as List<String>,
        styleUrls: data["styleUrls"] as List<String>,
        ngContentSelectors: data["ngContentSelectors"] as List<String>);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {
      "encapsulation": this.encapsulation != null
          ? serializeEnum(this.encapsulation)
          : this.encapsulation,
      "template": this.template,
      "templateUrl": this.templateUrl,
      "styles": this.styles,
      "styleUrls": this.styleUrls,
      "ngContentSelectors": this.ngContentSelectors
    };
    if (preserveWhitespace) res["preserveWhitespace"] = true;
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
      var matches = RegExpWrapper.firstMatch(HOST_REG_EXP, key);
      if (isBlank(matches)) {
        hostAttributes[key] = value;
      } else if (matches[1] != null) {
        hostProperties[matches[1]] = value;
      } else if (matches[2] != null) {
        hostListeners[matches[2]] = value;
      }
    });

    Map<String, String> inputsMap = {};
    inputs?.forEach((String bindConfig) {
      // canonical syntax: [dirProp: elProp]
      // if there is no [:], use dirProp = elProp
      var parts = splitAtColon(bindConfig, [bindConfig, bindConfig]);
      inputsMap[parts[0]] = parts[1];
    });

    Map<String, String> outputsMap = {};
    outputs?.forEach((String bindConfig) {
      // canonical syntax: [dirProp: elProp]
      // if there is no [:], use dirProp = elProp
      var parts = splitAtColon(bindConfig, [bindConfig, bindConfig]);
      outputsMap[parts[0]] = parts[1];
    });

    return new CompileDirectiveMetadata(
        type: type,
        isComponent: normalizeBool(isComponent),
        selector: selector,
        exportAs: exportAs,
        changeDetection: changeDetection,
        inputs: inputsMap,
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
      {CompileTypeMetadata type,
      bool isComponent,
      String selector,
      String exportAs,
      ChangeDetectionStrategy changeDetection,
      Map<String, String> inputs,
      Map<String, String> outputs,
      Map<String, String> hostListeners,
      Map<String, String> hostProperties,
      Map<String, String> hostAttributes,
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
    this.type = type;
    this.isComponent = isComponent;
    this.selector = selector;
    this.exportAs = exportAs;
    this.changeDetection = changeDetection;
    this.inputs = inputs;
    this.outputs = outputs;
    this.hostListeners = hostListeners;
    this.hostProperties = hostProperties;
    this.hostAttributes = hostAttributes;
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
        type: isPresent(data["type"])
            ? CompileTypeMetadata.fromJson(data["type"] as Map<String, dynamic>)
            : data["type"],
        changeDetection: isPresent(data["changeDetection"])
            ? CHANGE_DETECTION_STRATEGY_VALUES[data["changeDetection"]]
            : data["changeDetection"],
        inputs: data["inputs"] as Map<String, String>,
        outputs: data["outputs"] as Map<String, String>,
        hostListeners: data["hostListeners"] as Map<String, String>,
        hostProperties: data["hostProperties"] as Map<String, String>,
        hostAttributes: data["hostAttributes"] as Map<String, String>,
        lifecycleHooks: ((data["lifecycleHooks"] as List<dynamic>))
            .map((hookValue) => LIFECYCLE_HOOKS_VALUES[hookValue])
            .toList(),
        template: isPresent(data["template"])
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
      "isComponent": this.isComponent,
      "selector": this.selector,
      "exportAs": this.exportAs,
      "type": isPresent(this.type) ? this.type.toJson() : this.type,
      "changeDetection": isPresent(this.changeDetection)
          ? serializeEnum(this.changeDetection)
          : this.changeDetection,
      "inputs": this.inputs,
      "outputs": this.outputs,
      "hostListeners": this.hostListeners,
      "hostProperties": this.hostProperties,
      "hostAttributes": this.hostAttributes,
      "lifecycleHooks":
          this.lifecycleHooks.map((hook) => serializeEnum(hook)).toList(),
      "template":
          isPresent(this.template) ? this.template.toJson() : this.template,
      "providers": _arrayToJson(this.providers),
      "viewProviders": _arrayToJson(this.viewProviders),
      "queries": _arrayToJson(this.queries),
      "viewQueries": _arrayToJson(this.viewQueries)
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
          name: '''${ componentType . name}_Host''',
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
    this.pure = normalizeBool(pure);
    this.lifecycleHooks = lifecycleHooks ?? [];
  }
  CompileIdentifierMetadata get identifier {
    return this.type;
  }

  static CompilePipeMetadata fromJson(Map<String, dynamic> data) {
    return new CompilePipeMetadata(
        type: isPresent(data["type"])
            ? CompileTypeMetadata.fromJson(data["type"] as Map<String, dynamic>)
            : data["type"],
        name: data["name"],
        pure: data["pure"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "class": "Pipe",
      "type": isPresent(this.type) ? this.type.toJson() : null,
      "name": this.name,
      "pure": this.pure
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
    this.injectable = normalizeBool(injectable);
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
  return isBlank(obj) ? null : obj.map((o) => _objFromJson(o, fn)).toList();
}

dynamic /* String | Map < String , dynamic > */ _arrayToJson(
    List<dynamic> obj) {
  return isBlank(obj) ? null : obj.map(_objToJson).toList();
}

dynamic _objFromJson(dynamic obj, dynamic fn(Map<String, dynamic> a)) {
  if (isArray(obj)) return _arrayFromJson(obj, fn);
  if (isString(obj) || isBlank(obj) || isBoolean(obj) || isNumber(obj))
    return obj;
  return fn(obj as Map<String, dynamic>);
}

dynamic /* String | Map < String , dynamic > */ _objToJson(dynamic obj) {
  if (isArray(obj)) return _arrayToJson(obj);
  if (isString(obj) || isBlank(obj) || isBoolean(obj) || isNumber(obj))
    return obj;
  return obj.toJson();
}
