import 'package:quiver/collection.dart';

import '../core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import '../core/metadata/lifecycle_hooks.dart' show LifecycleHooks;
import '../core/metadata/view.dart';
import '../core/metadata/visibility.dart';
import '../facade/exceptions.dart' show BaseException;
import 'analyzed_class.dart';
import 'compiler_utils.dart';
import 'selector.dart' show CssSelector;

// group 1: 'property' from '[property]'
// group 2: 'event' from '(event)'
var HOST_REG_EXP = new RegExp(r'^(?:(?:\[([^\]]+)\])|(?:\(([^\)]+)\)))$');

abstract class CompileMetadataWithIdentifier<T> {
  CompileIdentifierMetadata<T> get identifier;
}

abstract class CompileMetadataWithType<T>
    extends CompileMetadataWithIdentifier<T> {
  CompileTypeMetadata get type;
}

class CompileIdentifierMetadata<T> implements CompileMetadataWithIdentifier<T> {
  // TODO(het): remove this once we switch to codegen. The transformer version
  // includes prefixes that aren't supposed to be emitted because it can't tell
  // if a prefix is a class name or a qualified import name.
  final bool emitPrefix;
  final String prefix;

  String name;
  String moduleUrl;
  dynamic value;

  CompileIdentifierMetadata(
      {this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix: false,
      this.value});

  @override
  CompileIdentifierMetadata<T> get identifier => this;
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
}

class CompileProviderMetadata {
  CompileTokenMetadata token;
  CompileTypeMetadata useClass;
  dynamic useValue;
  CompileTokenMetadata useExisting;
  CompileFactoryMetadata useFactory;
  List<CompileDiDependencyMetadata> deps;
  bool multi;

  /// Restricts where the provider is injectable.
  final Visibility visibility;

  CompileProviderMetadata({
    this.token,
    this.useClass,
    this.useValue,
    this.useExisting,
    this.useFactory,
    this.deps,
    this.visibility,
    bool multi,
  })
      : this.multi = multi == true;

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is! CompileProviderMetadata) return false;
    return token == other.token &&
        useClass == other.useClass &&
        useValue == other.useValue &&
        useExisting == other.useExisting &&
        useFactory == other.useFactory &&
        listsEqual(deps, other.deps) &&
        multi == other.multi;
  }

  @override
  String toString() => '{\n'
      'token:$token,\n'
      'useClass:$useClass,\n'
      'useValue:$useValue,\n'
      'useExisting:$useExisting,\n'
      'useFactory:$useFactory,\n'
      'deps:$deps,\n'
      'multi:$multi,\n'
      '}';
}

class CompileFactoryMetadata implements CompileIdentifierMetadata<Function> {
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
      {this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix: false,
      List<CompileDiDependencyMetadata> diDeps,
      this.value})
      : this.diDeps = diDeps ?? const [];

  @override
  CompileIdentifierMetadata<Function> get identifier => this;
}

class CompileTokenMetadata implements CompileMetadataWithIdentifier {
  dynamic value;
  @override
  CompileIdentifierMetadata identifier;
  bool identifierIsInstance;

  CompileTokenMetadata({this.value, this.identifier, bool identifierIsInstance})
      : this.identifierIsInstance = identifierIsInstance == true;

  dynamic get assetCacheKey {
    if (identifier != null) {
      return identifier.moduleUrl != null &&
              Uri.parse(identifier.moduleUrl).scheme != null
          ? '${identifier.name}|${identifier.moduleUrl}|$identifierIsInstance'
          : null;
    } else {
      return value;
    }
  }

  bool equalsTo(CompileTokenMetadata token2) {
    var ak = assetCacheKey;
    return (ak != null && ak == token2.assetCacheKey);
  }

  String get name {
    return value != null ? sanitizeIdentifier(value) : identifier?.name;
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is! CompileTokenMetadata) return false;
    return value == other.value &&
        identifier == other.identifier &&
        identifierIsInstance == other.identifierIsInstance;
  }

  @override
  String toString() => '{\n'
      'value:$value,\n'
      'identifier:$identifier,\n'
      'identifierIsInstance:$identifierIsInstance,\n'
      '}';
}

class CompileTokenMap<V> {
  final _valueMap = new Map<dynamic, V>();
  final List<V> _values = [];
  final List<CompileTokenMetadata> _tokens = [];

  void add(CompileTokenMetadata token, V value) {
    var existing = get(token);
    if (existing != null) {
      throw new BaseException(
          'Add failed. Token already exists. Token: ${token.name}');
    }
    _tokens.add(token);
    _values.add(value);
    var ak = token.assetCacheKey;
    if (ak != null) {
      _valueMap[ak] = value;
    }
  }

  V get(CompileTokenMetadata token) {
    var ak = token.assetCacheKey;
    return ak != null ? _valueMap[ak] : null;
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
  String name;
  @override
  String prefix;
  @override
  final bool emitPrefix = false;
  @override
  String moduleUrl;
  bool isHost;
  @override
  dynamic value;
  List<CompileDiDependencyMetadata> diDeps;
  CompileTypeMetadata(
      {this.name,
      this.moduleUrl,
      this.prefix,
      bool isHost,
      this.value,
      List<CompileDiDependencyMetadata> diDeps})
      : this.isHost = isHost == true,
        this.diDeps = diDeps ?? const [];

  @override
  CompileIdentifierMetadata<Type> get identifier => this;

  @override
  CompileTypeMetadata get type => this;

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is! CompileTypeMetadata) return false;
    return name == other.name &&
        prefix == other.prefix &&
        emitPrefix == other.emitPrefix &&
        moduleUrl == other.moduleUrl &&
        isHost == other.isHost &&
        value == other.value &&
        listsEqual(diDeps, other.diDeps);
  }

  @override
  String toString() => '{\n'
      'name:$name,\n'
      'prefix:$prefix,\n'
      'emitPrefix:$emitPrefix,\n'
      'moduleUrl:$moduleUrl,\n'
      'isHost:$isHost,\n'
      'value:$value,\n'
      'diDeps:$diDeps,\n'
      '}';
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
}

enum CompileDirectiveMetadataType {
  /// Metadata type for a class annotated with `@Component`.
  Component,

  /// Metadata type for a class annotated with `@Directive`.
  Directive,

  /// Metadata type for a function annotated with `@Directive`.
  FunctionalDirective,
}

/// Metadata regarding compilation of a directive.
class CompileDirectiveMetadata implements CompileMetadataWithType {
  /// Maps host attributes, listeners, and properties from a serialized map.
  ///
  /// Serialized host key grammar:
  ///
  ///     <key> :=
  ///         <attribute-key> |
  ///         <listener-key> |
  ///         <property-key>
  ///
  ///     <attribute-key> :=
  ///         <identifier>
  ///
  ///     <listener-key> :=
  ///         '(' <identifier> ')'
  ///
  ///     <property-key> :=
  ///         '[' <identifier> ']'
  ///
  /// For each (<key>, <value>) in [host], (<identifier>, <value>) is added to
  ///
  /// * [outAttributes] if <key> is an <attribute-key>,
  /// * [outListeners] if <key> is a <listener-key>, or
  /// * [outProperties] if <key> is a <property-key>.
  static void deserializeHost(
    Map<String, String> host,
    Map<String, String> outAttributes,
    Map<String, String> outListeners,
    Map<String, String> outProperties,
  ) {
    assert(outAttributes != null);
    assert(outListeners != null);
    assert(outProperties != null);

    host?.forEach((key, value) {
      final matches = HOST_REG_EXP.firstMatch(key);
      if (matches == null) {
        outAttributes[key] = value;
      } else if (matches[1] != null) {
        outProperties[matches[1]] = value;
      } else if (matches[2] != null) {
        outListeners[matches[2]] = value;
      }
    });
  }

  /// Maps binding names and types from a list of serialized inputs.
  ///
  /// Serialized input grammar:
  ///
  ///     <input> :=
  ///         <input-binding> [; <type>]
  ///
  ///     <input-binding> :=
  ///         <dirProp> |
  ///         <dirProp> ':' <elProp>
  ///
  /// For each <input> in [inputs], (<dirProp>, <elProp>) is added to
  /// [outBindingNames], and (<dirProp>, <type>) is added to [outTypes]. If
  /// omitted, <elProp> defaults to <dirProp>.
  static void deserializeInputs(
    List<String> inputs,
    Map<String, String> outBindingNames,
    Map<String, CompileTypeMetadata> outTypes,
  ) {
    assert(outBindingNames != null);
    assert(outTypes != null);

    inputs?.forEach((input) {
      final inputParts = input.split(';');
      final inputName = inputParts[0];
      final bindingParts = splitAtColon(inputName, [inputName, inputName]);

      outBindingNames[bindingParts[0]] = bindingParts[1];

      if (inputParts.length > 1) {
        outTypes[bindingParts[0]] =
            new CompileTypeMetadata(name: inputParts[1]);
      }
    });
  }

  @override
  CompileTypeMetadata type;
  final CompileDirectiveMetadataType metadataType;
  String selector;
  String exportAs;
  int changeDetection;
  Map<String, String> inputs;
  Map<String, CompileTypeMetadata> inputTypes;
  Map<String, String> outputs;
  Map<String, String> hostListeners;
  Map<String, String> hostProperties;
  Map<String, String> hostAttributes;
  List<LifecycleHooks> lifecycleHooks;
  List<CompileProviderMetadata> providers;
  List<CompileProviderMetadata> viewProviders;
  List<CompileIdentifierMetadata> exports;
  List<CompileQueryMetadata> queries;
  List<CompileQueryMetadata> viewQueries;
  CompileTemplateMetadata template;
  final AnalyzedClass analyzedClass;
  bool _requiresDirectiveChangeDetector;

  /// Restricts where the directive is injectable.
  final Visibility visibility;

  CompileDirectiveMetadata({
    this.type,
    this.metadataType,
    this.selector,
    this.exportAs,
    this.changeDetection,
    this.inputs,
    this.inputTypes,
    this.outputs,
    this.hostListeners,
    this.hostProperties,
    this.hostAttributes,
    this.analyzedClass,
    this.template,
    this.visibility,
    List<LifecycleHooks> lifecycleHooks,
    // CompileProviderMetadata | CompileTypeMetadata |
    // CompileIdentifierMetadata | List
    List providers,
    // CompileProviderMetadata | CompileTypeMetadata |
    // CompileIdentifierMetadata | List
    List viewProviders,
    List exports,
    List<CompileQueryMetadata> queries,
    List<CompileQueryMetadata> viewQueries,
  }) {
    this.lifecycleHooks = lifecycleHooks ?? [];
    this.providers = providers as List<CompileProviderMetadata> ?? [];
    this.viewProviders = viewProviders as List<CompileProviderMetadata> ?? [];
    this.exports = exports as List<CompileIdentifierMetadata> ?? [];
    this.queries = queries ?? [];
    this.viewQueries = viewQueries ?? [];
  }

  @override
  CompileIdentifierMetadata get identifier => type;

  bool get isComponent =>
      metadataType == CompileDirectiveMetadataType.Component;

  /// Returns true if the directive requires a ChangeDetector class to be
  /// generated.
  ///
  /// DirectiveChangeDetector classes should only be generated if they
  /// reduce the amount of duplicate code. Therefore we check for the presence
  /// of either inputs (to reduce change detection code) or outputs that
  /// are DOM events to add listeners inside a initHostEvents method.
  bool get requiresDirectiveChangeDetector {
    if (_requiresDirectiveChangeDetector == null) {
      bool hasInputsWithNgOnChanges = inputs.isNotEmpty &&
          lifecycleHooks.contains(LifecycleHooks.OnChanges);
      _requiresDirectiveChangeDetector =
          metadataType == CompileDirectiveMetadataType.Directive &&
              identifier.name != 'NgIf' &&
              (hasInputsWithNgOnChanges || hostProperties.isNotEmpty);
    }
    return _requiresDirectiveChangeDetector;
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
  return new CompileDirectiveMetadata(
    type: new CompileTypeMetadata(
        name: '${componentType.name}Host',
        moduleUrl: componentType.moduleUrl,
        isHost: true),
    template: new CompileTemplateMetadata(
        template: template,
        templateUrl: '',
        preserveWhitespace: preserveWhitespace,
        styles: const [],
        styleUrls: const [],
        ngContentSelectors: const []),
    changeDetection: ChangeDetectionStrategy.Default,
    inputs: const {},
    inputTypes: const {},
    outputs: const {},
    hostAttributes: const {},
    hostListeners: const {},
    hostProperties: const {},
    metadataType: CompileDirectiveMetadataType.Component,
    selector: '*',
  );
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
  CompileIdentifierMetadata get identifier => type;
}
