import 'package:angular2/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks, LIFECYCLE_HOOKS_VALUES;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/facade/exceptions.dart' show BaseException;

import 'compiler_utils.dart';
import 'selector.dart' show CssSelector;
import 'url_resolver.dart' show getUrlScheme;

// group 1: 'property' from '[property]'
// group 2: 'event' from '(event)'
var HOST_REG_EXP = new RegExp(r'^(?:(?:\[([^\]]+)\])|(?:\(([^\)]+)\)))$');

abstract class CompileMetadataWithIdentifier {
  Map<String, dynamic> toJson();
  CompileIdentifierMetadata get identifier;
}

abstract class CompileMetadataWithType extends CompileMetadataWithIdentifier {
  @override
  Map<String, dynamic> toJson();
  CompileTypeMetadata get type {
    throw new UnimplementedError();
  }

  @override
  CompileIdentifierMetadata get identifier;
}

dynamic metadataFromJson(Map<String, dynamic> data) {
  return _COMPILE_METADATA_FROM_JSON[data['class']](data);
}

class CompileIdentifierMetadata<T> implements CompileMetadataWithIdentifier {
  // TODO(het): remove this once we switch to codegen. The transformer version
  // includes prefixes that aren't supposed to be emitted because it can't tell
  // if a prefix is a class name or a qualified import name.
  final bool emitPrefix;
  final String prefix;

  String name;
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
  T runtime;

  /// Same as runtime but evaluates function before using value.
  Function runtimeCallback;

  CompileIdentifierMetadata(
      {this.runtime,
      this.runtimeCallback,
      this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix: false,
      this.value});

  static CompileIdentifierMetadata fromJson(Map<String, dynamic> data) {
    var value = data['value'] is List
        ? _arrayFromJson(data['value'], metadataFromJson)
        : _objFromJson(data['value'], metadataFromJson);
    return new CompileIdentifierMetadata(
        name: data['name'],
        prefix: data['prefix'],
        moduleUrl: data['moduleUrl'],
        value: value);
  }

  @override
  Map<String, dynamic> toJson() {
    var jsonValue = value is List ? _arrayToJson(value) : _objToJson(value);
    return {
      // Note: Runtime type can't be serialized...
      'class': 'Identifier', 'name': name, 'moduleUrl': moduleUrl,
      'prefix': prefix, 'value': jsonValue
    };
  }

  @override
  CompileIdentifierMetadata get identifier => this;
}

class CompileDiDependencyMetadata {
  final bool isAttribute;
  final bool isSelf;
  final bool isHost;
  final bool isSkipSelf;
  final bool isOptional;
  final bool isValue;
  CompileTokenMetadata token;
  dynamic value;
  CompileDiDependencyMetadata(
      {bool isAttribute,
      bool isSelf,
      bool isHost,
      bool isSkipSelf,
      bool isOptional,
      bool isValue,
      this.token,
      this.value})
      :
        // TODO: Make the defaults of the constructor 'false' instead of doing this.
        this.isAttribute = isAttribute == true,
        this.isSelf = isSelf == true,
        this.isHost = isHost == true,
        this.isSkipSelf = isSkipSelf == true,
        this.isOptional = isOptional == true,
        this.isValue = isValue == true;

  static CompileDiDependencyMetadata fromJson(Map<String, dynamic> data) {
    return new CompileDiDependencyMetadata(
        token: _objFromJson(data['token'], CompileTokenMetadata.fromJson),
        value: data['value'],
        isAttribute: data['isAttribute'],
        isSelf: data['isSelf'],
        isHost: data['isHost'],
        isSkipSelf: data['isSkipSelf'],
        isOptional: data['isOptional'],
        isValue: data['isValue']);
  }

  Map<String, dynamic> toJson() {
    return {
      'token': _objToJson(token),
      'value': value,
      'isAttribute': isAttribute,
      'isSelf': isSelf,
      'isHost': isHost,
      'isSkipSelf': isSkipSelf,
      'isOptional': isOptional,
      'isValue': isValue
    };
  }
}

class CompileProviderMetadata {
  CompileTokenMetadata token;
  CompileTypeMetadata useClass;
  dynamic useValue;
  CompileTokenMetadata useExisting;
  CompileFactoryMetadata useFactory;
  List<CompileDiDependencyMetadata> deps;
  bool multi;
  CompileProviderMetadata(
      {this.token,
      this.useClass,
      this.useValue,
      this.useExisting,
      this.useFactory,
      this.deps,
      bool multi})
      : this.multi = multi == true;

  static CompileProviderMetadata fromJson(Map<String, dynamic> data) {
    return new CompileProviderMetadata(
        token: _objFromJson(data['token'], CompileTokenMetadata.fromJson),
        useClass: _objFromJson(data['useClass'], CompileTypeMetadata.fromJson),
        useExisting:
            _objFromJson(data['useExisting'], CompileTokenMetadata.fromJson),
        useValue:
            _objFromJson(data['useValue'], CompileIdentifierMetadata.fromJson),
        useFactory:
            _objFromJson(data['useFactory'], CompileFactoryMetadata.fromJson),
        multi: data['multi'],
        deps: _arrayFromJson(data['deps'], CompileDiDependencyMetadata.fromJson)
            as List<CompileDiDependencyMetadata>);
  }

  Map<String, dynamic> toJson() {
    return {
      // Note: Runtime type can't be serialized...
      'class': 'Provider',
      'token': _objToJson(token),
      'useClass': _objToJson(useClass),
      'useExisting': _objToJson(useExisting),
      'useValue': _objToJson(useValue),
      'useFactory': _objToJson(useFactory),
      'multi': multi,
      'deps': _arrayToJson(deps)
    };
  }
}

class CompileFactoryMetadata
    implements
        CompileIdentifierMetadata<Function>,
        CompileMetadataWithIdentifier {
  @override
  Function runtime;
  @override
  Function runtimeCallback;
  @override
  String name;
  @override
  String prefix;
  @override
  bool emitPrefix;
  @override
  String moduleUrl;
  @override
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  CompileFactoryMetadata(
      {this.runtime,
      this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix: false,
      List<CompileDiDependencyMetadata> diDeps,
      this.value})
      : this.diDeps = diDeps ?? const [];

  @override
  CompileIdentifierMetadata get identifier => this;

  static CompileFactoryMetadata fromJson(Map<String, dynamic> data) {
    return new CompileFactoryMetadata(
        name: data['name'],
        prefix: data['prefix'],
        moduleUrl: data['moduleUrl'],
        value: data['value'],
        diDeps: (_arrayFromJson(
                data['diDeps'], CompileDiDependencyMetadata.fromJson))
            as List<CompileDiDependencyMetadata>);
  }

  @override
  Map<String, dynamic> toJson() => {
        'class': 'Factory',
        'name': name,
        'prefix': prefix,
        'moduleUrl': moduleUrl,
        'value': value,
        'diDeps': _arrayToJson(diDeps)
      };
}

class CompileTokenMetadata implements CompileMetadataWithIdentifier {
  dynamic value;
  @override
  CompileIdentifierMetadata identifier;
  bool identifierIsInstance;

  CompileTokenMetadata({this.value, this.identifier, bool identifierIsInstance})
      : this.identifierIsInstance = identifierIsInstance == true;

  static CompileTokenMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTokenMetadata(
        value: data['value'],
        identifier: _objFromJson(
            data['identifier'], CompileIdentifierMetadata.fromJson),
        identifierIsInstance: data['identifierIsInstance']);
  }

  @override
  Map<String, dynamic> toJson() => {
        'value': value,
        'identifier': _objToJson(identifier),
        'identifierIsInstance': identifierIsInstance
      };

  dynamic get runtimeCacheKey =>
      identifier != null ? identifier.runtime : value;

  dynamic get assetCacheKey {
    if (identifier != null) {
      return identifier.moduleUrl != null &&
              getUrlScheme(identifier.moduleUrl) != null
          ? '${identifier.name}|${identifier.moduleUrl}|${identifierIsInstance}'
          : null;
    } else {
      return value;
    }
  }

  bool equalsTo(CompileTokenMetadata token2) {
    var rk = runtimeCacheKey;
    var ak = assetCacheKey;
    return (rk != null && rk == token2.runtimeCacheKey) ||
        (ak != null && ak == token2.assetCacheKey);
  }

  String get name {
    return value != null ? sanitizeIdentifier(value) : identifier?.name;
  }
}

class CompileTokenMap<V> {
  final _valueMap = new Map<dynamic, V>();
  List<V> _values = [];
  List<CompileTokenMetadata> _tokens = [];

  void add(CompileTokenMetadata token, V value) {
    var existing = get(token);
    if (existing != null) {
      throw new BaseException(
          'Add failed. Token already exists. Token: ${token.name}');
    }
    _tokens.add(token);
    _values.add(value);
    var rk = token.runtimeCacheKey;
    if (rk != null) {
      _valueMap[rk] = value;
    }
    var ak = token.assetCacheKey;
    if (ak != null) {
      _valueMap[ak] = value;
    }
  }

  V get(CompileTokenMetadata token) {
    var rk = token.runtimeCacheKey;
    var ak = token.assetCacheKey;
    V result;
    if (rk != null) {
      result = _valueMap[rk];
    }
    if (result == null && ak != null) {
      result = _valueMap[ak];
    }
    return result;
  }

  bool containsKey(CompileTokenMetadata token) => get(token) != null;

  List<CompileTokenMetadata> get keys => _tokens;

  List<V> get values => _values;

  int get size => _values.length;
}

/// Metadata regarding compilation of a type.
class CompileTypeMetadata
    implements CompileIdentifierMetadata<Type>, CompileMetadataWithType {
  @override
  Type runtime;
  @override
  Function runtimeCallback;
  @override
  String name;
  @override
  String prefix;
  @override
  bool emitPrefix = false;
  @override
  String moduleUrl;
  bool isHost;
  @override
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  CompileTypeMetadata(
      {this.runtime,
      this.name,
      this.moduleUrl,
      this.prefix,
      bool isHost,
      this.value,
      List<CompileDiDependencyMetadata> diDeps})
      : this.isHost = isHost == true,
        this.diDeps = diDeps ?? const [];

  static CompileTypeMetadata fromJson(Map<String, dynamic> data) {
    return new CompileTypeMetadata(
        name: data['name'],
        moduleUrl: data['moduleUrl'],
        prefix: data['prefix'],
        isHost: data['isHost'],
        value: data['value'],
        diDeps:
            _arrayFromJson(data['diDeps'], CompileDiDependencyMetadata.fromJson)
                as List<CompileDiDependencyMetadata>);
  }

  @override
  CompileIdentifierMetadata get identifier => this;

  @override
  CompileTypeMetadata get type => this;

  @override
  Map<String, dynamic> toJson() => {
        // Note: Runtime type can't be serialized...
        'class': 'Type',
        'name': name,
        'moduleUrl': moduleUrl,
        'prefix': prefix,
        'isHost': isHost,
        'value': value,
        'diDeps': _arrayToJson(diDeps)
      };
}

/// Provides metadata for Query, ViewQuery, ViewChildren,
/// ContentChild and ContentChildren decorators.
class CompileQueryMetadata {
  /// List of types or tokens to match.
  List<CompileTokenMetadata> selectors;

  /// TODO: unused, deprecate.
  bool descendants;

  /// Set when querying for first instance that matches selectors.
  bool first;

  /// Name of class member on the component to update with query result.
  String propertyName;

  /// Optional type to read for given match.
  ///
  /// When we match an element in the template, it typically returns the
  /// component. Using read: parameter we can specifically query for
  /// ViewContainer or TemplateRef for the node.
  CompileTokenMetadata read;

  CompileQueryMetadata(
      {this.selectors,
      bool descendants,
      bool first,
      this.propertyName,
      this.read})
      : this.descendants = descendants == true,
        this.first = first == true;

  static CompileQueryMetadata fromJson(Map<String, dynamic> data) {
    return new CompileQueryMetadata(
        selectors:
            _arrayFromJson(data['selectors'], CompileTokenMetadata.fromJson)
                as List<CompileTokenMetadata>,
        descendants: data['descendants'],
        first: data['first'],
        propertyName: data['propertyName'],
        read: _objFromJson(data['read'], CompileTokenMetadata.fromJson));
  }

  Map<String, dynamic> toJson() {
    return {
      'selectors': _arrayToJson(selectors),
      'descendants': descendants,
      'first': first,
      'propertyName': propertyName,
      'read': _objToJson(read)
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
        encapsulation: data['encapsulation'] != null
            ? ViewEncapsulation.values[data['encapsulation']]
            : data['encapsulation'],
        template: data['template'],
        templateUrl: data['templateUrl'],
        preserveWhitespace: data['preserveWhitespace'] ?? true,
        styles: data['styles'] as List<String>,
        styleUrls: data['styleUrls'] as List<String>,
        ngContentSelectors: data['ngContentSelectors'] as List<String>);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> res = {
      'encapsulation': encapsulation?.index,
      'template': template,
      'templateUrl': templateUrl,
      'styles': styles,
      'styleUrls': styleUrls,
      'ngContentSelectors': ngContentSelectors
    };
    if (preserveWhitespace == false) res['preserveWhitespace'] = false;
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

  @override
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

  @override
  CompileIdentifierMetadata get identifier => type;

  static CompileDirectiveMetadata fromJson(Map<String, dynamic> data) {
    return new CompileDirectiveMetadata(
        isComponent: data['isComponent'],
        selector: data['selector'],
        exportAs: data['exportAs'],
        type: data['type'] != null
            ? CompileTypeMetadata.fromJson(data['type'] as Map<String, dynamic>)
            : data['type'],
        changeDetection: data['changeDetection'] != null
            ? ChangeDetectionStrategy.values[data['changeDetection']]
            : null,
        inputs: data['inputs'] as Map<String, String>,
        inputTypes: data['inputTypes'] as Map<String, String>,
        outputs: data['outputs'] as Map<String, String>,
        hostListeners: data['hostListeners'] as Map<String, String>,
        hostProperties: data['hostProperties'] as Map<String, String>,
        hostAttributes: data['hostAttributes'] as Map<String, String>,
        lifecycleHooks: ((data['lifecycleHooks'] as List<dynamic>))
            .map((hookValue) => LIFECYCLE_HOOKS_VALUES[hookValue])
            .toList(),
        template: data['template'] != null
            ? CompileTemplateMetadata
                .fromJson(data['template'] as Map<String, dynamic>)
            : data['template'],
        providers: _arrayFromJson(data['providers'], metadataFromJson),
        viewProviders: _arrayFromJson(data['viewProviders'], metadataFromJson),
        queries: _arrayFromJson(data['queries'], CompileQueryMetadata.fromJson)
            as List<CompileQueryMetadata>,
        viewQueries:
            _arrayFromJson(data['viewQueries'], CompileQueryMetadata.fromJson)
                as List<CompileQueryMetadata>);
  }

  @override
  Map<String, dynamic> toJson() => {
        'class': 'Directive',
        'isComponent': isComponent,
        'selector': selector,
        'exportAs': exportAs,
        'type': type?.toJson(),
        'changeDetection': changeDetection?.index,
        'inputs': inputs,
        'inputTypes': inputTypes,
        'outputs': outputs,
        'hostListeners': hostListeners,
        'hostProperties': hostProperties,
        'hostAttributes': hostAttributes,
        'lifecycleHooks': lifecycleHooks.map((hook) => hook.index).toList(),
        'template': template?.toJson(),
        'providers': _arrayToJson(providers),
        'viewProviders': _arrayToJson(viewProviders),
        'queries': _arrayToJson(queries),
        'viewQueries': _arrayToJson(viewQueries)
      };
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
          templateUrl: '',
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
      selector: '*',
      providers: [],
      viewProviders: [],
      queries: [],
      viewQueries: []);
}

class CompilePipeMetadata implements CompileMetadataWithType {
  @override
  final CompileTypeMetadata type;
  final String name;
  final bool pure;
  final List<LifecycleHooks> lifecycleHooks;

  CompilePipeMetadata(
      {this.type, this.name, bool pure, List<LifecycleHooks> lifecycleHooks})
      : this.pure = pure ?? true,
        this.lifecycleHooks = lifecycleHooks ?? const [];

  @override
  CompileIdentifierMetadata get identifier => this.type;

  static CompilePipeMetadata fromJson(Map<String, dynamic> data) {
    return new CompilePipeMetadata(
        type: data['type'] != null
            ? CompileTypeMetadata.fromJson(data['type'] as Map<String, dynamic>)
            : data['type'],
        name: data['name'],
        pure: data['pure']);
  }

  @override
  Map<String, dynamic> toJson() =>
      {'class': 'Pipe', 'type': type?.toJson(), 'name': name, 'pure': pure};
}

var _COMPILE_METADATA_FROM_JSON = {
  'Directive': CompileDirectiveMetadata.fromJson,
  'Pipe': CompilePipeMetadata.fromJson,
  'Type': CompileTypeMetadata.fromJson,
  'Provider': CompileProviderMetadata.fromJson,
  'Identifier': CompileIdentifierMetadata.fromJson,
  'Factory': CompileFactoryMetadata.fromJson,
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
