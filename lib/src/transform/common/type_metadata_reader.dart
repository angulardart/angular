import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/core/change_detection/change_detection.dart';
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart'
    show LifecycleHooks;
import 'package:angular2/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular2/src/transform/common/annotation_matcher.dart';
import 'package:angular2/src/transform/common/interface_matcher.dart';
import 'package:angular2/src/transform/common/logging.dart';
import 'package:barback/barback.dart' show AssetId;
import 'package:logging/logging.dart';

import 'naive_eval.dart';
import 'url_resolver.dart';

// Name of mixin that enables ChangeDetectionStrategy.Stateful;
const String _componentStateClassName = 'ComponentState';

class TypeMetadataReader {
  final _DirectiveMetadataVisitor _directiveVisitor;
  final _PipeMetadataVisitor _pipeVisitor;
  final _CompileTypeMetadataVisitor _typeVisitor;
  final _CompileFactoryMetadataVisitor _factoryVisitor;
  final OfflineCompiler _templateCompiler;

  TypeMetadataReader._(
    this._directiveVisitor,
    this._pipeVisitor,
    this._templateCompiler,
    this._typeVisitor,
    this._factoryVisitor,
  );

  /// Accepts an [AnnotationMatcher] which tests that an [Annotation]
  /// is a [Directive], [Component], or [View].
  factory TypeMetadataReader(AnnotationMatcher annotationMatcher,
      InterfaceMatcher interfaceMatcher, OfflineCompiler templateCompiler) {
    var lifecycleVisitor = new _LifecycleHookVisitor(interfaceMatcher);
    var typeVisitor = new _CompileTypeMetadataVisitor(annotationMatcher);
    var factoryVisitor = new _CompileFactoryMetadataVisitor(annotationMatcher);
    var directiveVisitor = new _DirectiveMetadataVisitor(
        annotationMatcher, lifecycleVisitor, typeVisitor);
    var pipeVisitor = new _PipeMetadataVisitor(
        annotationMatcher, lifecycleVisitor, typeVisitor);
    return new TypeMetadataReader._(
      directiveVisitor,
      pipeVisitor,
      templateCompiler,
      typeVisitor,
      factoryVisitor,
    );
  }

  /// Reads *un-normalized* [CompileDirectiveMetadata]/[CompilePipeMetadata] from the
  /// [ClassDeclaration] `node`.
  ///
  /// `node` is expected to be a class which may have a [Directive] or [Component]
  /// annotation. If `node` does not have one of these annotations, this function
  /// returns `null`.
  ///
  /// `assetId` is the [AssetId] from which `node` was read, unless `node` was
  /// read from a part file, in which case `assetId` should be the [AssetId] of
  /// the parent file.
  Future<dynamic> readTypeMetadata(ClassDeclaration node, AssetId assetId) {
    _directiveVisitor.reset(assetId);
    _pipeVisitor.reset(assetId);
    _typeVisitor.reset(assetId);

    node.accept(_directiveVisitor);
    node.accept(_pipeVisitor);
    node.accept(_typeVisitor);

    if (_directiveVisitor.hasMetadata) {
      final metadata = _directiveVisitor.createMetadata();
      return _templateCompiler.normalizeDirectiveMetadata(metadata);
    } else if (_pipeVisitor.hasMetadata) {
      return new Future.value(_pipeVisitor.createMetadata());
    } else if (_typeVisitor.isInjectable) {
      return new Future.value(_typeVisitor.type);
    } else {
      return new Future.value(null);
    }
  }

  Future<dynamic> readFactoryMetadata(
      FunctionDeclaration node, AssetId assetId) {
    _factoryVisitor.reset(assetId);

    node.accept(_factoryVisitor);

    if (_factoryVisitor.isInjectable) {
      return new Future.value(_factoryVisitor.factory);
    } else {
      return new Future.value(null);
    }
  }

  CompileIdentifierMetadata readIdentifierMetadata(
      VariableDeclaration decl, AssetId assetId) {
    final name = decl.name.name;
    return new CompileIdentifierMetadata(
        name: name,
        moduleUrl: toAssetUri(assetId),
        value: _readValue(decl.initializer));
  }

  dynamic _readValue(dynamic initializer) {
    if (initializer is InstanceCreationExpression) {
      String ctorName = initializer.constructorName.toString();
      if (ctorName == "Provider" || ctorName == "Binding") {
        return _readProvider(initializer);
      }
    }
    if (initializer is ListLiteral) {
      return _readProviders(initializer, throwOnErrors: false);
    } else {
      return null;
    }
  }
}

/// Evaluates the [Map] represented by `expression` and adds all `key`,
/// `value` pairs to `map`. If `expression` does not evaluate to a [Map],
/// throws a descriptive [FormatException].
void _populateMap(Expression expression, Map map, String propertyName) {
  var evaluated = naiveEval(expression);
  if (evaluated is! Map) {
    throw new FormatException(
        'Angular 2 expects a Map but could not understand the value for '
        '$propertyName.',
        '$expression' /* source */);
  }
  evaluated.forEach((key, value) {
    if (value != null) {
      map[key] = '$value';
    }
  });
}

/// Evaluates the [List] represented by `expression` and adds all values,
/// to `list`. If `expression` does not evaluate to a [List], throws a
/// descriptive [FormatException].
void _populateList(
    Expression expression, List<String> list, String propertyName) {
  var evaluated = naiveEval(expression);
  if (evaluated is List) {
    list.addAll(evaluated.map((e) => e.toString()));
    return;
  }
  throw new FormatException(
      'Angular 2 expects a List but could not understand the value for '
      '$propertyName.',
      '$expression' /* source */);
}

/// Evaluates `node` and expects that the result will be a string. If not,
/// throws a [FormatException].
String _expressionToString(Expression node, String nodeDescription) {
  var value = naiveEval(node);
  if (value is! String) {
    throw new FormatException(
        'Angular 2 could not understand the value '
        'in $nodeDescription.',
        '$node' /* source */);
  }
  return value;
}

/// Evaluates `node` and expects that the result will be a bool. If not,
/// throws a [FormatException].
bool _expressionToBool(Expression node, String nodeDescription) {
  var value = naiveEval(node);
  if (value is! bool) {
    throw new FormatException(
        'Angular 2 could not understand the value '
        'in $nodeDescription.',
        '$node' /* source */);
  }
  return value;
}

class _CompileTypeMetadataVisitor extends Object
    with RecursiveAstVisitor<CompileTypeMetadata> {
  bool _isInjectable = false;
  bool _isStatefulComponent = false;
  CompileTypeMetadata _type;
  AssetId _assetId;
  final AnnotationMatcher _annotationMatcher;
  final _ComponentMixinVisitor _mixinVisitor = new _ComponentMixinVisitor();

  _CompileTypeMetadataVisitor(this._annotationMatcher);

  bool get isInjectable => _isInjectable;
  bool get isStatefulComponent => _isStatefulComponent;

  CompileTypeMetadata get type => _type;

  void reset(AssetId assetId) {
    _mixinVisitor.reset(assetId);
    this._assetId = assetId;
    this._isInjectable = false;
    this._type = null;
  }

  @override
  CompileTypeMetadata visitAnnotation(Annotation node) {
    final isComponent = _annotationMatcher.isComponent(node, _assetId);
    final isDirective = _annotationMatcher.isDirective(node, _assetId);
    final isPipe = _annotationMatcher.isPipe(node, _assetId);
    final isInjectable = _annotationMatcher.isInjectable(node, _assetId);

    _isInjectable =
        _isInjectable || isComponent || isDirective || isPipe || isInjectable;
    return null;
  }

  @override
  CompileTypeMetadata visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    List<CompileDiDependencyMetadata> diDeps;
    if (this._isInjectable) {
      final constructor = node.getConstructor(null);
      final fieldTypes = _readFields(node);
      diDeps = constructor == null
          ? []
          : _getCompileDiDependencyMetadata(
              node, constructor.parameters, fieldTypes);
      _type = new CompileTypeMetadata(
          moduleUrl: toAssetUri(_assetId),
          name: node.name.toString(),
          diDeps: diDeps,
          runtime: null // Intentionally `null`, cannot be provided here.
          );
    }
    if (node.withClause != null) {
      List<String> mixins = node.withClause.accept(_mixinVisitor);
      if (mixins.contains(_componentStateClassName)) {
        _isStatefulComponent = true;
      }
    }
    if (node.extendsClause != null) {
      List<String> mixins = node.extendsClause.accept(_mixinVisitor);
      if (mixins.contains(_componentStateClassName)) {
        _isStatefulComponent = true;
      }
    }
    return null;
  }

  Map<String, TypeName> _readFields(ClassDeclaration clazz) {
    final res = <String, TypeName>{};
    var members = clazz.members;
    int memberCount = members.length;
    for (int i = 0; i < memberCount; i++) {
      var member = members[i];
      if (member is! FieldDeclaration) continue;
      FieldDeclaration field = member;
      var type = field.fields.type;
      if (type != null) {
        field.fields.variables.forEach((VariableDeclaration decl) {
          var key = '${decl.name}';
          res[key] = type;
        });
      }
    }
    return res;
  }
}

class _CompileFactoryMetadataVisitor extends Object
    with RecursiveAstVisitor<CompileFactoryMetadata> {
  bool _isInjectable = false;
  CompileFactoryMetadata _factory;
  AssetId _assetId;
  final AnnotationMatcher _annotationMatcher;

  _CompileFactoryMetadataVisitor(this._annotationMatcher);

  bool get isInjectable => _isInjectable;

  CompileFactoryMetadata get factory => _factory;

  void reset(AssetId assetId) {
    this._assetId = assetId;
    this._isInjectable = false;
    this._factory = null;
  }

  @override
  CompileFactoryMetadata visitAnnotation(Annotation node) {
    _isInjectable = _annotationMatcher.isInjectable(node, _assetId);
    return null;
  }

  @override
  CompileFactoryMetadata visitFunctionDeclaration(FunctionDeclaration node) {
    node.metadata.accept(this);
    if (this._isInjectable) {
      _factory = new CompileFactoryMetadata(
          moduleUrl: toAssetUri(_assetId),
          name: node.name.toString(),
          diDeps: _getCompileDiDependencyMetadata(
              null, node.functionExpression.parameters, {}),
          runtime: null // Intentionally `null`, cannot be provided here.
          );
    }
    return null;
  }
}

/// Visitor responsible for processing a [Directive] annotated
/// [ClassDeclaration] and creating a [CompileDirectiveMetadata] object.
class _DirectiveMetadataVisitor extends Object
    with RecursiveAstVisitor<Object> {
  /// Tests [Annotation]s to determine if they deifne a [Directive],
  /// [Component], [View], or none of these.
  final AnnotationMatcher _annotationMatcher;

  final _LifecycleHookVisitor _lifecycleVisitor;
  final _ComponentMixinVisitor _componentMixinVisitor =
      new _ComponentMixinVisitor();

  final _CompileTypeMetadataVisitor _typeVisitor;

  /// The [AssetId] we are currently processing.
  AssetId _assetId;

  _DirectiveMetadataVisitor(
      this._annotationMatcher, this._lifecycleVisitor, this._typeVisitor) {
    reset(null);
  }

  /// Whether the visitor has found a [Component] or [Directive] annotation
  /// since the last call to `reset`.
  bool _hasMetadata = false;

  // Annotation fields
  CompileTypeMetadata _type;
  bool _isComponent;
  String _selector;
  String _exportAs;
  ChangeDetectionStrategy _changeDetection;
  List<String> _inputs;
  List<String> _outputs;
  Map<String, String> _host;
  List _providers;
  List _viewProviders;
  List _queries;
  List _viewQueries;
  List<LifecycleHooks> _lifecycleHooks;
  CompileTemplateMetadata _cmpTemplate;
  CompileTemplateMetadata _viewTemplate;
  bool _isStatefulComponent;

  void reset(AssetId assetId) {
    _lifecycleVisitor.reset(assetId);
    _typeVisitor.reset(assetId);
    _componentMixinVisitor.reset(assetId);
    _assetId = assetId;

    _type = null;
    _isComponent = false;
    _isStatefulComponent = false;
    _hasMetadata = false;
    _selector = '';
    _exportAs = null;
    _changeDetection = ChangeDetectionStrategy.Default;
    _inputs = <String>[];
    _outputs = <String>[];
    _host = <String, String>{};
    _providers = [];
    _viewProviders = [];
    _queries = [];
    _viewQueries = [];
    _lifecycleHooks = null;
    _cmpTemplate = null;
    _viewTemplate = null;
  }

  bool get hasMetadata => _hasMetadata;

  CompileTemplateMetadata get _template =>
      _viewTemplate != null ? _viewTemplate : _cmpTemplate;

  CompileDirectiveMetadata createMetadata() {
    return CompileDirectiveMetadata.create(
        type: _type,
        isComponent: _isComponent,
        selector: _selector,
        exportAs: _exportAs,
        changeDetection: _isStatefulComponent
            ? ChangeDetectionStrategy.Stateful
            : _changeDetection,
        inputs: _inputs,
        outputs: _outputs,
        host: _host,
        providers: _providers,
        viewProviders: _viewProviders,
        queries: _queries as List<CompileQueryMetadata>,
        viewQueries: _viewQueries as List<CompileQueryMetadata>,
        lifecycleHooks: _lifecycleHooks,
        template: _template);
  }

  /// Ensures that we do not specify View values on an `@Component` annotation
  /// when there is a @View annotation present.
  void _validateTemplates() {
    if (_cmpTemplate != null && _viewTemplate != null) {
      var name = '(Unknown)';
      if (_type != null && _type.name != null && _type.name.isNotEmpty) {
        name = _type.name;
      }
      log.warning(
          'Cannot specify view parameters on @Component when a @View '
          'is present. Component name: ${name}',
          asset: _assetId);
    }
  }

  @override
  Object visitAnnotation(Annotation node) {
    var isComponent = _annotationMatcher.isComponent(node, _assetId);
    var isDirective = _annotationMatcher.isDirective(node, _assetId);
    if (isDirective) {
      if (_hasMetadata) {
        throw new FormatException(
            'Only one Directive is allowed per class. '
            'Found unexpected "$node".',
            '$node' /* source */);
      }
      _isComponent = isComponent;
      _hasMetadata = true;
      if (isComponent) {
        _cmpTemplate =
            new _CompileTemplateMetadataVisitor().visitAnnotation(node);
        _validateTemplates();
      }
      super.visitAnnotation(node);
    } else if (_annotationMatcher.isView(node, _assetId)) {
      if (_viewTemplate != null) {
        throw new FormatException(
            'Only one View is allowed per class. '
            'Found unexpected "$node".',
            '$node' /* source */);
      }
      _viewTemplate =
          new _CompileTemplateMetadataVisitor().visitAnnotation(node);
      _validateTemplates();
    }

    // Annotation we do not recognize - no need to visit.
    return null;
  }

  /// Verifies that annotation has parentheses.
  ///
  /// Throws error for input such as `@Input String value`.
  void _verifyHasZeroOrMoreArgs(
      String name, FieldDeclaration node, Annotation meta) {
    if (meta.arguments == null || meta.arguments.arguments == null) {
      throw new FormatException(
          'Expecting parentheses after @${name}() annotation.',
          '$node' /* source */);
    }
  }

  void _verifyMethodHasZeroOrMoreArgs(
      String name, MethodDeclaration node, Annotation meta) {
    if (meta.arguments == null || meta.arguments.arguments == null) {
      throw new FormatException(
          'Expecting parentheses after @${name}() annotation.',
          '$node' /* source */);
    }
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      for (var meta in node.metadata) {
        if (_isAnnotation(meta, 'Output')) {
          _verifyHasZeroOrMoreArgs('Output', node, meta);
          _addOutputPropertyToType(variable.name.toString(), meta, _outputs);
        }

        if (_isAnnotation(meta, 'Input')) {
          _verifyHasZeroOrMoreArgs('Input', node, meta);
          _addInputPropertyToType(
              node.fields.type, variable.name.toString(), meta, _inputs);
        }

        if (_isAnnotation(meta, 'HostBinding')) {
          _verifyHasZeroOrMoreArgs('HostBinding', node, meta);
          final renamed = _getRenamedValue(meta);
          if (renamed != null) {
            _host['[${renamed}]'] = '${variable.name}';
          } else {
            _host['[${variable.name}]'] = '${variable.name}';
          }
        }

        if (_isAnnotation(meta, 'ContentChild')) {
          _verifyHasZeroOrMoreArgs('ContentChild', node, meta);
          _queries.add(_createQueryMetadata(meta, variable.name.toString(),
              first: true));
        }
        if (_isAnnotation(meta, 'ContentChildren')) {
          _verifyHasZeroOrMoreArgs('ContentChildren', node, meta);
          _queries.add(_createQueryMetadata(meta, variable.name.toString(),
              first: false));
        }
        if (_isAnnotation(meta, 'ViewChild')) {
          _verifyHasZeroOrMoreArgs('ViewChild', node, meta);
          _viewQueries.add(_createQueryMetadata(meta, variable.name.toString(),
              defaultDescendantsValue: true, first: true));
        }
        if (_isAnnotation(meta, 'ViewChildren')) {
          _verifyHasZeroOrMoreArgs('ViewChildren', node, meta);
          _viewQueries.add(_createQueryMetadata(meta, variable.name.toString(),
              first: false));
        }
      }
    }
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    for (var meta in node.metadata) {
      if (_isAnnotation(meta, 'Output') && node.isGetter) {
        _verifyMethodHasZeroOrMoreArgs('Output', node, meta);
        _addOutputPropertyToType(node.name.toString(), meta, _outputs);
      }

      if (_isAnnotation(meta, 'Input') && node.isSetter) {
        _verifyMethodHasZeroOrMoreArgs('Input', node, meta);
        TypeName setterParamType = (node.parameters.parameters != null &&
                node.parameters.parameters[0] is SimpleFormalParameter)
            ? (node.parameters.parameters[0] as SimpleFormalParameter).type
            : null;
        _addInputPropertyToType(
            setterParamType, node.name.toString(), meta, _inputs);
      }

      if (_isAnnotation(meta, 'ContentChild') && node.isSetter) {
        _verifyMethodHasZeroOrMoreArgs('ContentChild', node, meta);
        _queries
            .add(_createQueryMetadata(meta, node.name.toString(), first: true));
      }
      if (_isAnnotation(meta, 'ContentChildren') && node.isSetter) {
        _verifyMethodHasZeroOrMoreArgs('ContentChildren', node, meta);
        _queries.add(
            _createQueryMetadata(meta, node.name.toString(), first: false));
      }
      if (_isAnnotation(meta, 'ViewChild') && node.isSetter) {
        _verifyMethodHasZeroOrMoreArgs('ViewChild', node, meta);
        _viewQueries.add(_createQueryMetadata(meta, node.name.toString(),
            defaultDescendantsValue: true, first: true));
      }
      if (_isAnnotation(meta, 'ViewChildren') && node.isSetter) {
        _verifyMethodHasZeroOrMoreArgs('ViewChildren', node, meta);
        _viewQueries.add(
            _createQueryMetadata(meta, node.name.toString(), first: false));
      }

      if (_isAnnotation(meta, 'HostListener')) {
        if (meta.arguments?.arguments == null ||
            meta.arguments.arguments.length == 0 ||
            meta.arguments.arguments.length > 2) {
          throw new ArgumentError(
              'Incorrect value passed to HostListener. Expected 1 or 2.');
        }

        final eventName = _getHostListenerEventName(meta);
        final params = _getHostListenerParams(meta);
        _host['(${eventName})'] = '${node.name}($params)';
      }

      if (_isAnnotation(meta, 'HostBinding') && node.isGetter) {
        _verifyMethodHasZeroOrMoreArgs('HostBinding', node, meta);
        final renamed = _getRenamedValue(meta);
        if (renamed != null) {
          _host['[${renamed}]'] = '${node.name}';
        } else {
          _host['[${node.name}]'] = '${node.name}';
        }
      }
    }
    return null;
  }

  void _addOutputPropertyToType(String name, Annotation meta, List outputList) {
    final renamed = _getRenamedValue(meta);
    if (renamed != null) {
      outputList.add('${name}: ${renamed}');
    } else {
      outputList.add('${name}');
    }
  }

  void _addInputPropertyToType(
      TypeName inputType, String name, Annotation meta, List inputList) {
    final renamed = _getRenamedValue(meta);
    String inputTypeName = inputType?.name?.name;
    if (renamed != null) {
      if (inputType != null) {
        inputList.add('$name: $renamed; $inputTypeName');
      } else {
        inputList.add('$name: $renamed');
      }
    } else {
      if (inputType != null) {
        inputList.add('${name}; ${inputType.name.name}');
      } else {
        inputList.add('${name}');
      }
    }
  }

  void _populateProviders(Expression providerValues, List providers) {
    _checkMeta();

    if (providerValues is ListLiteral) {
      providers.addAll(_readProviders(providerValues, throwOnErrors: true));
    } else {
      // Support private nested provider lists...
      providers.add(_readIdentifier(providerValues, allowPrivate: true));
    }
  }

  //TODO Use AnnotationMatcher instead of string matching
  bool _isAnnotation(Annotation node, String annotationName) {
    var id = node.name;
    final name = id is PrefixedIdentifier ? '${id.identifier}' : '$id';
    return name == annotationName;
  }

  String _getRenamedValue(Annotation node) {
    if (node.arguments.arguments.length == 1) {
      final renamed = naiveEval(node.arguments.arguments.single);
      if (renamed is! String) {
        throw new ArgumentError(
            'Incorrect value. Expected a String, but got "${renamed}".');
      }
      return renamed;
    } else {
      return null;
    }
  }

  String _getHostListenerEventName(Annotation node) {
    final name = naiveEval(node.arguments.arguments.first);
    if (name is! String) {
      throw new ArgumentError(
          'Incorrect event name. Expected a String, but got "${name}".');
    }
    return name;
  }

  String _getHostListenerParams(Annotation node) {
    if (node.arguments.arguments.length == 2) {
      return naiveEval(node.arguments.arguments[1]).join(',');
    } else {
      return "";
    }
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.accept(_typeVisitor);
    _type = _typeVisitor.type;

    if (this._hasMetadata) {
      _lifecycleHooks = node.implementsClause != null
          ? node.implementsClause.accept(_lifecycleVisitor)
          : const <LifecycleHooks>[];

      if (node.withClause != null) {
        List<String> mixins = node.withClause.accept(_componentMixinVisitor);
        if (mixins.contains(_componentStateClassName)) {
          _isStatefulComponent = true;
        }
      }
      if (node.extendsClause != null) {
        List<String> mixins = node.extendsClause.accept(_componentMixinVisitor);
        if (mixins.contains(_componentStateClassName)) {
          _isStatefulComponent = true;
        }
      }

      node.members.accept(this);
    }

    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    // TODO(kegluneq): Remove this limitation.
    if (node.name is! Label || node.name.label is! SimpleIdentifier) {
      throw new FormatException(
          'Angular 2 currently only supports simple identifiers in directives.',
          '$node' /* source */);
    }
    var keyString = '${node.name.label}';
    switch (keyString) {
      case 'selector':
        _populateSelector(node.expression);
        break;
      case 'inputs':
        _populateProperties(node.expression);
        break;
      case 'host':
        _populateHost(node.expression);
        break;
      case 'exportAs':
        _populateExportAs(node.expression);
        break;
      case 'changeDetection':
        _populateChangeDetection(node.expression);
        break;
      case 'outputs':
        _populateEvents(node.expression);
        break;
      case 'providers':
        _populateProviders(node.expression, _providers);
        break;
      case 'viewProviders':
        _populateProviders(node.expression, _viewProviders);
        break;
    }
    return null;
  }

  void _populateSelector(Expression selectorValue) {
    _checkMeta();
    _selector = _expressionToString(selectorValue, 'Directive#selector');
  }

  void _checkMeta() {
    if (!_hasMetadata) {
      throw new ArgumentError('Incorrect value passed to readTypeMetadata. '
          'Expected type is ClassDeclaration');
    }
  }

  void _populateProperties(Expression inputsValue) {
    _checkMeta();
    _populateList(inputsValue, _inputs, 'Directive#inputs');
  }

  void _populateHost(Expression hostValue) {
    _checkMeta();
    _populateMap(hostValue, _host, 'Directive#host');
  }

  void _populateExportAs(Expression exportAsValue) {
    _checkMeta();
    _exportAs = _expressionToString(exportAsValue, 'Directive#exportAs');
  }

  void _populateEvents(Expression outputsValue) {
    _checkMeta();
    _populateList(outputsValue, _outputs, 'Directive#outputs');
  }

  void _populateChangeDetection(Expression value) {
    _checkMeta();
    _changeDetection = _changeDetectionStrategies[value.toSource()];
  }

  static final Map<String, ChangeDetectionStrategy> _changeDetectionStrategies =
      new Map.fromIterable(ChangeDetectionStrategy.values,
          key: (v) => v.toString());
}

/// Visitor responsible for parsing an [ImplementsClause] and returning a
/// [List<LifecycleHooks>] that the [Directive] subscribes to.
class _LifecycleHookVisitor extends SimpleAstVisitor<List<LifecycleHooks>> {
  /// Tests [Identifier]s of implemented interfaces to determine if they
  /// correspond to [LifecycleHooks] values.
  final InterfaceMatcher _ifaceMatcher;

  /// The [AssetId] we are currently processing.
  AssetId _assetId;

  _LifecycleHookVisitor(this._ifaceMatcher);

  void reset(AssetId assetId) {
    _assetId = assetId;
  }

  @override
  List<LifecycleHooks> visitImplementsClause(ImplementsClause node) {
    if (node == null || node.interfaces == null) return const [];

    return node.interfaces
        .map((TypeName ifaceTypeName) {
          var id = ifaceTypeName.name;
          if (_ifaceMatcher.isAfterContentChecked(id, _assetId)) {
            return LifecycleHooks.AfterContentChecked;
          } else if (_ifaceMatcher.isAfterContentInit(id, _assetId)) {
            return LifecycleHooks.AfterContentInit;
          } else if (_ifaceMatcher.isAfterViewChecked(id, _assetId)) {
            return LifecycleHooks.AfterViewChecked;
          } else if (_ifaceMatcher.isAfterViewInit(id, _assetId)) {
            return LifecycleHooks.AfterViewInit;
          } else if (_ifaceMatcher.isDoCheck(id, _assetId)) {
            return LifecycleHooks.DoCheck;
          } else if (_ifaceMatcher.isOnChange(id, _assetId)) {
            return LifecycleHooks.OnChanges;
          } else if (_ifaceMatcher.isOnDestroy(id, _assetId)) {
            return LifecycleHooks.OnDestroy;
          } else if (_ifaceMatcher.isOnInit(id, _assetId)) {
            return LifecycleHooks.OnInit;
          }
          return null;
        })
        .where((e) => e != null)
        .toList(growable: false);
  }
}

/// Visitor responsible for returning list of angular mixins.
class _ComponentMixinVisitor extends SimpleAstVisitor<List<String>> {
  /// The [AssetId] we are currently processing.
  AssetId _assetId;

  _ComponentMixinVisitor();

  void reset(AssetId assetId) {
    _assetId = assetId;
  }

  List<String> visitWithClause(WithClause node) {
    if (node == null) return const <String>[];
    var mixinTypes = <String>[];
    node.mixinTypes.forEach((TypeName t) {
      mixinTypes.add(t.name.name);
    });
    return mixinTypes;
  }

  @override
  List<String> visitExtendsClause(ExtendsClause node) {
    if (node == null) return const <String>[];
    return [node.superclass.name.name];
  }
}

/// Visitor responsible for parsing a @View [Annotation] and producing a
/// [CompileTemplateMetadata].
class _CompileTemplateMetadataVisitor
    extends RecursiveAstVisitor<CompileTemplateMetadata> {
  ViewEncapsulation _encapsulation;
  String _template;
  String _templateUrl;
  bool _preserveWhitespace;
  List<String> _styles;
  List<String> _styleUrls;

  @override
  CompileTemplateMetadata visitAnnotation(Annotation node) {
    super.visitAnnotation(node);

    if (_encapsulation == null &&
        _template == null &&
        _templateUrl == null &&
        _preserveWhitespace == null &&
        _styles == null &&
        _styleUrls == null) {
      return null;
    }

    return new CompileTemplateMetadata(
        encapsulation: _encapsulation,
        template: _template,
        templateUrl: _templateUrl,
        preserveWhitespace: _preserveWhitespace,
        styles: _styles,
        styleUrls: _styleUrls);
  }

  @override
  CompileTemplateMetadata visitNamedExpression(NamedExpression node) {
    // TODO(kegluneq): Remove this limitation.
    if (node.name is! Label || node.name.label is! SimpleIdentifier) {
      throw new FormatException(
          'Angular 2 currently only supports simple identifiers in directives.',
          '$node' /* source */);
    }
    var keyString = '${node.name.label}';
    switch (keyString) {
      case 'encapsulation':
        _populateEncapsulation(node.expression);
        break;
      case 'template':
        _populateTemplate(node.expression);
        break;
      case 'templateUrl':
        _populateTemplateUrl(node.expression);
        break;
      case 'styles':
        _populateStyles(node.expression);
        break;
      case 'styleUrls':
        _populateStyleUrls(node.expression);
        break;
      case 'preserveWhitespace':
        _populatePreserveWhitespace(node.expression);
        break;
    }
    return null;
  }

  void _populateTemplate(Expression value) {
    _template = _expressionToString(value, 'View#template');
  }

  void _populatePreserveWhitespace(Expression value) {
    _preserveWhitespace = _expressionToBool(value, 'View#preserveWhitespace');
  }

  void _populateTemplateUrl(Expression value) {
    _templateUrl = _expressionToString(value, 'View#templateUrl');
  }

  void _populateStyles(Expression value) {
    _styles = <String>[];
    _populateList(value, _styles, 'View#styles');
  }

  void _populateStyleUrls(Expression value) {
    _styleUrls = <String>[];
    _populateList(value, _styleUrls, 'View#styleUrls');
  }

  void _populateEncapsulation(Expression value) {
    _encapsulation = _viewEncapsulationMap[value.toSource()];
  }

  static final _viewEncapsulationMap =
      new Map.fromIterable(ViewEncapsulation.values, key: (v) => v.toString());
}

/// Visitor responsible for processing a [Pipe] annotated
/// [ClassDeclaration] and creating a [CompilePipeMetadata] object.
class _PipeMetadataVisitor extends Object with RecursiveAstVisitor<Object> {
  /// Tests [Annotation]s to determine if they deifne a [Directive],
  /// [Component], [View], or none of these.
  final AnnotationMatcher _annotationMatcher;

  final _LifecycleHookVisitor _lifecycleVisitor;

  final _CompileTypeMetadataVisitor _typeVisitor;

  /// The [AssetId] we are currently processing.
  AssetId _assetId;

  _PipeMetadataVisitor(
      this._annotationMatcher, this._lifecycleVisitor, this._typeVisitor) {
    reset(null);
  }

  /// Whether the visitor has found a [Pipe] annotation
  /// since the last call to `reset`.
  bool _hasMetadata = false;

  // Annotation fields
  CompileTypeMetadata _type;
  String _name;
  bool _pure;
  List<LifecycleHooks> _lifecycleHooks;

  void reset(AssetId assetId) {
    _lifecycleVisitor.reset(assetId);
    _typeVisitor.reset(assetId);
    _assetId = assetId;

    _hasMetadata = false;
    _type = null;
    _name = null;
    _pure = null;

    _lifecycleHooks = null;
  }

  bool get hasMetadata => _hasMetadata;

  CompilePipeMetadata createMetadata() {
    return new CompilePipeMetadata(
        type: _type, name: _name, pure: _pure, lifecycleHooks: _lifecycleHooks);
  }

  @override
  Object visitAnnotation(Annotation node) {
    var isPipe = _annotationMatcher.isPipe(node, _assetId);
    if (isPipe) {
      if (_hasMetadata) {
        throw new FormatException(
            'Only one Pipe is allowed per class. '
            'Found unexpected "$node".',
            '$node' /* source */);
      }
      _hasMetadata = true;
      super.visitAnnotation(node);
    }

    // Annotation we do not recognize - no need to visit.
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.accept(_typeVisitor);
    _type = _typeVisitor.type;
    if (this._hasMetadata) {
      _lifecycleHooks = node.implementsClause != null
          ? node.implementsClause.accept(_lifecycleVisitor)
          : const <LifecycleHooks>[];

      node.members.accept(this);
    }
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    // TODO(kegluneq): Remove this limitation.
    if (node.name is! Label || node.name.label is! SimpleIdentifier) {
      throw new FormatException(
          'Angular 2 currently only supports simple identifiers in pipes.',
          '$node' /* source */);
    }
    var keyString = '${node.name.label}';
    switch (keyString) {
      case 'name':
        _popuplateName(node.expression);
        break;
      case 'pure':
        _populatePure(node.expression);
        break;
    }
    return null;
  }

  void _checkMeta() {
    if (!_hasMetadata) {
      throw new ArgumentError('Incorrect value passed to readTypeMetadata. '
          'Expected type is ClassDeclaration');
    }
  }

  void _popuplateName(Expression nameValue) {
    _checkMeta();
    _name = _expressionToString(nameValue, 'Pipe#name');
  }

  void _populatePure(Expression pureValue) {
    _checkMeta();
    _pure = _expressionToBool(pureValue, 'Pipe#pure');
  }
}

List _readProviders(ListLiteral providerValues, {bool throwOnErrors}) {
  bool hasError = false;
  var providers = providerValues.elements.map((el) {
    if (el is PrefixedIdentifier || el is SimpleIdentifier) {
      // Support private nested provider lists...
      return _readIdentifier(el,
          allowPrivate: true, throwOnErrors: throwOnErrors);
    } else if (el is InstanceCreationExpression &&
        (el.constructorName.toString() == "Provider" ||
            el.constructorName.toString() == "Binding")) {
      return _readProvider(el);
    } else {
      hasError = true;
      if (throwOnErrors) {
        throw new ArgumentError(
            'Incorrect value. Expected a Provider or a String, but got "${el}".');
      }
    }
  }).toList();
  return hasError ? null : providers;
}

CompileProviderMetadata _readProvider(InstanceCreationExpression el) {
  final token = el.argumentList.arguments.first;

  var useClass, useExisting, useValue, useFactory, multi;
  List<CompileDiDependencyMetadata> deps;
  bool hasAnyValue = false;
  el.argumentList.arguments.skip(1).forEach((expr) {
    assert(expr is NamedExpression);
    String name = (expr is NamedExpression) ? expr.name.toString() : '';
    NamedExpression arg = expr;
    switch (name) {
      case "useClass:":
        final id = _readIdentifier(arg.expression);
        useClass = new CompileTypeMetadata(prefix: id.prefix, name: id.name);
        hasAnyValue = true;
        break;
      case "toClass:":
        final id = _readIdentifier(arg.expression);
        useClass = new CompileTypeMetadata(prefix: id.prefix, name: id.name);
        hasAnyValue = true;
        break;
      case "useExisting:":
        useExisting = _readToken(arg.expression);
        hasAnyValue = true;
        break;
      case "toAlias:":
        useExisting = _readToken(arg.expression);
        hasAnyValue = true;
        break;
      case "useValue:":
        useValue = _readValue(arg.expression);
        hasAnyValue = true;
        break;
      case "toValue:":
        useValue = _readValue(arg.expression);
        hasAnyValue = true;
        break;
      case "useFactory:":
        final id = _readIdentifier(arg.expression);
        useFactory =
            new CompileFactoryMetadata(name: id.name, prefix: id.prefix);
        hasAnyValue = true;
        break;
      case "toFactory:":
        final id = _readIdentifier(arg.expression);
        useFactory =
            new CompileFactoryMetadata(name: id.name, prefix: id.prefix);
        hasAnyValue = true;
        break;
      case "deps:":
        deps = _readDeps(arg.expression);
        break;
      case "multi:":
        multi = _readValue(arg.expression);
        break;
    }
  });
  if (!hasAnyValue) {
    throw new ArgumentError(
        'No "useClass", "useExisting", "useValue" or "useFactory" found in "${el}".');
  }
  return new CompileProviderMetadata(
      token: _readToken(token),
      useClass: useClass,
      useExisting: useExisting,
      useValue: useValue,
      useFactory: useFactory,
      multi: multi,
      deps: deps);
}

List<CompileDiDependencyMetadata> _readDeps(ListLiteral deps) {
  if (deps is! ListLiteral) {
    throw new ArgumentError('Incorrect value is set as deps. '
        'Expected type is ListLiteral');
  }

  return deps.elements.map((p) {
    final list = p is ListLiteral ? p.elements : [p];
    final first = list.first;

    var token;
    if (first is InstanceCreationExpression &&
        first.constructorName.toString() == "Inject") {
      token = _readToken(first.argumentList.arguments[0]);
    } else {
      token = _readToken(first);
    }

    return new CompileDiDependencyMetadata(
        token: token,
        isSelf: _hasConst(list, "Self"),
        isHost: _hasConst(list, "Host"),
        isSkipSelf: _hasConst(list, "SkipSelf"),
        isOptional: _hasConst(list, "Optional"));
  }).toList();
}

CompileQueryMetadata _createQueryMetadata(Annotation a, String propertyName,
    {bool defaultDescendantsValue: false, bool first: false}) {
  final selector = _readToken(a.arguments.arguments.first);
  var descendants = defaultDescendantsValue;
  var read;
  a.arguments.arguments.skip(0).forEach((arg) {
    if (arg is NamedExpression) {
      var name = arg.name.toString();
      if (name == "descendants:") {
        descendants = naiveEval(arg.expression);
      } else if (name == "read:") {
        read = _readToken(arg.expression);
      }
    }
  });

  final selectors = <CompileTokenMetadata>[];
  if (selector.value is String) {
    List<String> values = (selector.value as String).split(',');
    for (String v in values) {
      selectors.add(new CompileTokenMetadata(value: v));
    }
  } else {
    selectors.add(selector);
  }
  return new CompileQueryMetadata(
      selectors: selectors,
      descendants: descendants,
      first: first,
      read: read,
      propertyName: propertyName);
}

List<CompileDiDependencyMetadata> _getCompileDiDependencyMetadata(
    ClassDeclaration classDecl,
    FormalParameterList params,
    Map<String, TypeName> fieldTypes) {
  return params.parameters.map((dynamic p) {
    if (p is DefaultFormalParameter) {
      p = p.parameter;
    }

    var token;
    final isAttribute = _hasAnnotation(p, "Attribute");
    if (isAttribute) {
      token =
          _readToken(_getAnnotation(p, "Attribute").arguments.arguments.first);
    } else {
      var type;
      if (p is SimpleFormalParameter) {
        type = p.type;
      } else if (p is FieldFormalParameter) {
        type = fieldTypes[p.identifier.toString()];
      }
      final typeToken = type != null ? _readToken(type.name) : null;
      final injectTokens = p.metadata
          .where((m) => m.name.toString() == "Inject")
          .map((m) => _readToken(m.arguments.arguments[0]));
      token = injectTokens.isNotEmpty ? injectTokens.first : typeToken;
    }

    // View queries in constructors were deprecated Nov 2016. Remove this
    // code and deprecation warning EOQ1 2017.
    if (_hasAnnotation(p, "Query") ||
        _hasAnnotation(p, "ContentChildren") ||
        _hasAnnotation(p, "ViewQuery") ||
        _hasAnnotation(p, "ViewChildren")) {
      _reportDeprecation(classDecl);
    }

    if (token == null) {
      throw new ArgumentError(
          'Missing class member or type for constructor parameter $p');
    }
    return new CompileDiDependencyMetadata(
        token: token,
        isAttribute: _hasAnnotation(p, "Attribute"),
        isSelf: _hasAnnotation(p, "Self"),
        isHost: _hasAnnotation(p, "Host"),
        isSkipSelf: _hasAnnotation(p, "SkipSelf"),
        isOptional: _hasAnnotation(p, "Optional"));
  }).toList();
}

final Logger _deprecationLogger = new Logger('angular2.transformer');
void _reportDeprecation(ClassDeclaration classDecl) {
  if (classDecl == null) {
    throw new Exception('View queries inside global functions '
        'are not supported');
  }
  String source = 'in class ${classDecl.name.name}';
  throw new Exception('Queries inside constructors are deprecated, '
      'please replace with query annotations on fields $source');
}

Annotation _getAnnotation(p, String attrName) =>
    p.metadata.where((m) => m.name.toString() == attrName).first;

bool _hasAnnotation(p, String attrName) =>
    p.metadata.where((m) => m.name.toString() == attrName).isNotEmpty;

bool _hasConst(List list, String name) => list
    .where((m) =>
        m is InstanceCreationExpression && m.constructorName.toString() == name)
    .isNotEmpty;

dynamic _readIdentifier(dynamic el,
    {bool allowPrivate: false, bool throwOnErrors: true}) {
  var name;
  var prefix;
  var error;
  if (el is PrefixedIdentifier) {
    prefix = '${el.prefix}';
    if (prefix.length > 0 && prefix.toUpperCase()[0] == prefix[0]) {
      error = 'Incorrect identifier "${el}".';
    }
    name = '${el.identifier}';
  } else if (el is SimpleIdentifier) {
    name = '$el';
  } else {
    error = 'Incorrect identifier "${el}".';
  }
  if (name != null && !allowPrivate && name.startsWith('_')) {
    error = 'Private identifier "${el}" not supported.';
  }
  if (error != null) {
    if (throwOnErrors) {
      throw new ArgumentError(error);
    } else {
      return null;
    }
  } else {
    return new CompileIdentifierMetadata(name: name, prefix: prefix);
  }
}

dynamic _readValue(dynamic el) {
  if (el is DoubleLiteral ||
      el is IntegerLiteral ||
      el is SimpleStringLiteral ||
      el is BooleanLiteral) {
    return el.value;
  } else if (el is NullLiteral) {
    return null;
  } else {
    return _readIdentifier(el);
  }
}

CompileTokenMetadata _readToken(dynamic el) {
  if (el is DoubleLiteral ||
      el is IntegerLiteral ||
      el is SimpleStringLiteral ||
      el is BooleanLiteral) {
    return new CompileTokenMetadata(value: el.value);
  } else if (el is InstanceCreationExpression) {
    return new CompileTokenMetadata(
        identifier:
            new CompileIdentifierMetadata(name: '${el.constructorName}'),
        identifierIsInstance: true);
  } else {
    return new CompileTokenMetadata(identifier: _readIdentifier(el));
  }
}
