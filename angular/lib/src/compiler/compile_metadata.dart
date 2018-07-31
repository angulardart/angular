import 'package:collection/collection.dart';

import '../core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy;
import '../core/metadata/lifecycle_hooks.dart' show LifecycleHooks;
import '../core/metadata/view.dart';
import '../core/metadata/visibility.dart';
import 'analyzed_class.dart';
import 'compiler_utils.dart';
import 'expression_parser/ast.dart' as ast;
import 'output/convert.dart' show typeArgumentsFrom;
import 'output/output_ast.dart' as o;
import 'selector.dart' show CssSelector;

final _listsEqual = const ListEquality<Object>().equals;

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
  final List<o.OutputType> typeArguments;
  final String prefix;

  final String name;
  final String moduleUrl;
  final T value;

  /// If this identifier refers to a class declaration, this is non-null.
  final AnalyzedClass analyzedClass;

  CompileIdentifierMetadata(
      {this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix = false,
      this.typeArguments = const [],
      this.value,
      this.analyzedClass});

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
      {this.isAttribute = false,
      this.isSelf = false,
      this.isHost = false,
      this.isSkipSelf = false,
      this.isOptional = false,
      this.isValue = false,
      this.token,
      this.value});
}

class CompileProviderMetadata {
  final CompileTokenMetadata token;
  final CompileTypeMetadata useClass;
  dynamic useValue;
  final CompileTokenMetadata useExisting;
  final CompileFactoryMetadata useFactory;
  final List<CompileDiDependencyMetadata> deps;

  final bool multi;

  // TODO(matanl): Refactor to avoid two fields for multi-providers.
  final CompileTypeMetadata typeArgument;

  /// Restricts where the provider is injectable.
  final Visibility visibility;

  CompileProviderMetadata({
    this.token,
    this.useClass,
    this.useValue,
    this.useExisting,
    this.useFactory,
    this.deps,
    this.visibility = Visibility.all,
    this.multi = false,
    this.typeArgument,
  });

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is! CompileProviderMetadata) return false;
    CompileProviderMetadata _other = other;
    return token == _other.token &&
        useClass == _other.useClass &&
        useValue == _other.useValue &&
        useExisting == _other.useExisting &&
        useFactory == _other.useFactory &&
        _listsEqual(deps, _other.deps) &&
        multi == _other.multi;
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
  Function value;

  @override
  List<o.OutputType> get typeArguments => const [];

  List<CompileDiDependencyMetadata> diDeps;

  CompileFactoryMetadata(
      {this.name,
      this.moduleUrl,
      this.prefix,
      this.emitPrefix = false,
      this.diDeps = const [],
      this.value});

  @override
  CompileIdentifierMetadata<Function> get identifier => this;

  @override
  AnalyzedClass get analyzedClass => null;
}

class CompileTokenMetadata implements CompileMetadataWithIdentifier {
  dynamic value;
  @override
  CompileIdentifierMetadata identifier;
  bool identifierIsInstance;

  CompileTokenMetadata(
      {this.value, this.identifier, this.identifierIsInstance = false});

  // Used to determine unique-ness of CompileTokenMetadata.
  //
  // Because this code originated from the shared TypeScript source, a unique
  // String is emitted and compared, and not something more Dart-y like
  // equality. Should be refactored.
  dynamic get assetCacheKey {
    if (identifier != null) {
      return identifier.moduleUrl != null &&
              Uri.parse(identifier.moduleUrl).scheme != null
          ? ''
              '${identifier.name}|'
              '${identifier.moduleUrl}|'
              '$identifierIsInstance|'
              '$value|'
              '${identifier.typeArguments.map(_typeAssetKey).join(',')}'
          : null;
    } else {
      return value;
    }
  }

  static String _typeAssetKey(o.OutputType t) {
    if (t is o.ExternalType) {
      final generics = t.value.typeArguments != null
          ? t.value.typeArguments.map(_typeAssetKey).join(',')
          : '[]';
      return 'ExternalType {${t.value.moduleUrl}:${t.value.name}:$generics}';
    }
    return '{notExternalType}';
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
    if (other is CompileTokenMetadata) {
      return value == other.value &&
          identifier == other.identifier &&
          identifierIsInstance == other.identifierIsInstance;
    }
    return false;
  }

  @override
  String toString() => '{\n'
      'value:$value,\n'
      'identifier:$identifier,\n'
      'identifierIsInstance:$identifierIsInstance,\n'
      '}';
}

class CompileTokenMap<V> {
  final _valueMap = Map<dynamic, V>();
  final List<V> _values = [];
  final List<CompileTokenMetadata> _tokens = [];

  void add(CompileTokenMetadata token, V value) {
    var existing = get(token);
    if (existing != null) {
      throw StateError(
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
    implements CompileIdentifierMetadata<Type>, CompileMetadataWithType<Type> {
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
  Type value;

  List<CompileDiDependencyMetadata> diDeps;

  @override
  final List<o.OutputType> typeArguments;

  /// The type parameters on this type's definition.
  ///
  /// Note the distinction from [typeArguments], which represent the *type
  /// arguments* of an instantiated type.
  final List<o.TypeParameter> typeParameters;

  CompileTypeMetadata({
    this.name,
    this.moduleUrl,
    this.prefix,
    this.isHost = false,
    this.value,
    this.typeArguments = const [],
    this.typeParameters = const [],
    this.diDeps = const [],
  });

  @override
  CompileIdentifierMetadata<Type> get identifier => this;

  @override
  CompileTypeMetadata get type => this;

  @override
  AnalyzedClass get analyzedClass => null;

  @override
  // ignore: hash_and_equals
  bool operator ==(other) {
    if (other is! CompileTypeMetadata) return false;
    CompileTypeMetadata _other = other;
    return name == _other.name &&
        prefix == _other.prefix &&
        emitPrefix == _other.emitPrefix &&
        moduleUrl == _other.moduleUrl &&
        isHost == _other.isHost &&
        value == _other.value &&
        _listsEqual(diDeps, _other.diDeps);
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
      'typeArguments:$typeArguments\n'
      '}';
}

/// Metadata used to type a generic directive.
class CompileTypedMetadata {
  /// The module URL of the directive this types.
  final String moduleUrl;

  /// The name of the directive this types.
  final String name;

  /// An optional identifier for matching specific instances of the directive.
  final String on;

  /// The generic type arguments to be used to instantiate the directive.
  final List<o.OutputType> typeArguments;

  CompileTypedMetadata(
    this.name,
    this.moduleUrl,
    this.typeArguments, {
    this.on,
  });
}

/// Provides metadata for Query, ViewQuery, ViewChildren,
/// ContentChild and ContentChildren decorators.
class CompileQueryMetadata {
  /// List of types or tokens to match.
  final List<CompileTokenMetadata> selectors;

  /// Whether nested elements should be queried.
  final bool descendants;

  /// Set when querying for first instance that matches selectors.
  final bool first;

  /// Name of class member on the component to update with query result.
  final String propertyName;

  /// Whether this is typed `dart:html`'s `Element` (or a sub-type).
  final bool isElementType;

  /// Optional type to read for given match.
  ///
  /// When we match an element in the template, it typically returns the
  /// component. Using read: parameter we can specifically query for
  /// ViewContainer or TemplateRef for the node.
  final CompileTokenMetadata read;

  const CompileQueryMetadata({
    this.selectors,
    this.descendants = false,
    this.first = false,
    this.propertyName,
    this.isElementType = false,
    this.read,
  });
}

/// Metadata regarding compilation of a template.
class CompileTemplateMetadata {
  final ViewEncapsulation encapsulation;
  final String template;
  final String templateUrl;
  final bool preserveWhitespace;
  final List<String> styles;
  final List<String> styleUrls;
  final List<String> ngContentSelectors;
  CompileTemplateMetadata(
      {this.encapsulation = ViewEncapsulation.Emulated,
      this.template,
      this.templateUrl,
      this.preserveWhitespace = false,
      this.styles = const [],
      this.styleUrls = const [],
      this.ngContentSelectors = const []});
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
  @override
  final CompileTypeMetadata type;

  /// User-land class where the component annotation originated.
  final CompileTypeMetadata originType;

  final CompileDirectiveMetadataType metadataType;
  final String selector;
  final String exportAs;
  final int changeDetection;
  final Map<String, String> inputs;
  final Map<String, CompileTypeMetadata> inputTypes;
  final Map<String, String> outputs;
  final Map<String, ast.AST> hostBindings;
  final Map<String, String> hostListeners;
  final List<LifecycleHooks> lifecycleHooks;
  final List<CompileProviderMetadata> providers;
  final List<CompileProviderMetadata> viewProviders;
  final List<CompileIdentifierMetadata> exports;
  final List<CompileQueryMetadata> queries;
  final List<CompileQueryMetadata> viewQueries;
  final CompileTemplateMetadata template;
  final AnalyzedClass analyzedClass;
  bool _requiresDirectiveChangeDetector;

  /// Restricts where the directive is injectable.
  final Visibility visibility;

  CompileDirectiveMetadata({
    this.type,
    this.originType,
    this.metadataType,
    this.selector,
    this.exportAs,
    this.changeDetection,
    this.inputs,
    this.inputTypes,
    this.outputs,
    this.hostBindings,
    this.hostListeners,
    this.analyzedClass,
    this.template,
    this.visibility = Visibility.all,
    this.lifecycleHooks = const [],
    this.providers = const [],
    this.viewProviders = const [],
    this.exports = const [],
    this.queries = const [],
    this.viewQueries = const [],
  });

  @override
  CompileIdentifierMetadata get identifier => type;

  bool get isComponent =>
      metadataType == CompileDirectiveMetadataType.Component;

  /// Whether the directive requires a change detector class to be generated.
  ///
  /// [DirectiveChangeDetector] classes should only be generated if they
  /// reduce the amount of duplicate code. Therefore we check for the presence
  /// of host bindings to move from each call site to a single method.
  bool get requiresDirectiveChangeDetector {
    if (_requiresDirectiveChangeDetector == null) {
      _requiresDirectiveChangeDetector =
          metadataType == CompileDirectiveMetadataType.Directive &&
              identifier.name != 'NgIf' &&
              hostProperties.isNotEmpty;
    }
    return _requiresDirectiveChangeDetector;
  }

  Map<String, ast.AST> _cachedHostAttributes;
  Map<String, ast.AST> _cachedHostProperties;

  /// The subset of `hostBindings` that are immutable bindings.
  ///
  /// It's useful to separate these out because we can set them at
  /// build time and avoid change detecting them.
  Map<String, ast.AST> get hostAttributes {
    if (_cachedHostAttributes == null) {
      _computeHostBindingImmutability();
    }
    assert(_cachedHostAttributes != null);
    return _cachedHostAttributes;
  }

  Map<String, ast.AST> get hostProperties {
    if (_cachedHostProperties == null) {
      _computeHostBindingImmutability();
    }
    assert(_cachedHostProperties != null);
    return _cachedHostProperties;
  }

  void _computeHostBindingImmutability() {
    assert(_cachedHostAttributes == null);
    assert(_cachedHostProperties == null);
    _cachedHostAttributes = <String, ast.AST>{};
    _cachedHostProperties = <String, ast.AST>{};

    // Host bindings are either literal strings or a property access. We have
    // to filter out non-static property accesses because the directive instance
    // is not available at build time.
    bool _isStatic(ast.AST value) {
      if (value is ast.LiteralPrimitive) return true;
      if (value is ast.PropertyRead) {
        return value.receiver is ast.StaticRead;
      }
      // Unrecognized binding type, just assume it's not static.
      return false;
    }

    hostBindings.forEach((name, value) {
      // TODO(het): We should also inline style and class bindings
      var isStyleOrClassBinding =
          name.startsWith('style.') || name.startsWith('class.');
      if (isImmutable(value, analyzedClass) &&
          _isStatic(value) &&
          !isStyleOrClassBinding) {
        if (name.startsWith('attr.')) {
          name = name.substring('attr.'.length);
        }
        _cachedHostAttributes[name] = value;
      } else {
        _cachedHostProperties[name] = value;
      }
    });
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
  return CompileDirectiveMetadata(
    originType: componentType,
    type: CompileTypeMetadata(
        name: '${componentType.name}Host',
        moduleUrl: componentType.moduleUrl,
        isHost: true),
    template: CompileTemplateMetadata(
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
    hostBindings: const {},
    hostListeners: const {},
    metadataType: CompileDirectiveMetadataType.Component,
    selector: '*',
  );
}

/// Creates metadata necessary to flow types from a host view to its component.
List<CompileTypedMetadata> createHostDirectiveTypes(
    CompileTypeMetadata componentType) {
  // If the component doesn't have any generic type parameters, there's no need
  // to specify generic type arguments.
  if (componentType.typeParameters.isEmpty) {
    return [];
  }
  // Otherwise, the returned metadata flows each type parameter of the host view
  // as a type argument to the component (and its associated views).
  return [
    CompileTypedMetadata(
      componentType.name,
      componentType.moduleUrl,
      typeArgumentsFrom(componentType.typeParameters),
    )
  ];
}

class CompilePipeMetadata implements CompileMetadataWithType {
  @override
  final CompileTypeMetadata type;
  final o.FunctionType transformType;
  final String name;
  final bool pure;
  final List<LifecycleHooks> lifecycleHooks;

  CompilePipeMetadata({
    this.type,
    this.transformType,
    this.name,
    this.pure = true,
    this.lifecycleHooks = const [],
  });

  @override
  CompileIdentifierMetadata get identifier => type;
}
