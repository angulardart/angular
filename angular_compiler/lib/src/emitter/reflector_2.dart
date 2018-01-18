import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

import '../analyzer/reflector.dart';

import 'reflector.dart';

// TODO(matanl): Remove both of these once the class is complete.
// ignore_for_file: unused_element
// ignore_for_file: unused_field

/// Re-implements [ReflectableEmitter] using `package:code_builder`.
///
/// This allows incremental testing before removing the existing code.
///
/// **NOTE**: This class is _stateful_, unlike the original.
class CodeBuilderReflectableEmitter implements ReflectableEmitter {
  static const _package = 'package:angular';

  @override
  final Iterable<String> deferredModules;

  @override
  final String deferredModuleSource;

  @override
  final String reflectorSource;

  final Allocator _allocator;

  final ReflectableOutput _output;

  DartEmitter _dartEmitter;
  LibraryBuilder _library;
  BlockBuilder _initReflectorBody;
  StringSink _importBuffer;
  StringSink _initReflectorBuffer;

  Reference _ngRef(String symbol) => refer('_ngRef.$symbol');

  // Classes and functions we need to refer to in generated (runtime) code.
  Reference get _registerComponent => _ngRef('registerComponent');
  Reference get _registerFactory => _ngRef('registerFactory');
  Reference get _registerDependencies => _ngRef('registerDependencies');
  Reference get _SkipSelf => _ngRef('SkipSelf');
  Reference get _Optional => _ngRef('Optional');
  Reference get _Self => _ngRef('Self');
  Reference get _Host => _ngRef('Host');
  Reference get _Inject => _ngRef('Inject');
  Reference get _MultiToken => _ngRef('MultiToken');
  Reference get _OpaqueToken => _ngRef('OpaqueToken');

  CodeBuilderReflectableEmitter(
    this._output, {
    Allocator allocator,
    this.reflectorSource: '$_package/src/di/reflector.dart',
    List<String> deferredModules,
    this.deferredModuleSource,
  })
      : _allocator = allocator ?? Allocator.none,
        deferredModules = deferredModules ?? const [];

  /// Whether we have one or more URLs that need `initReflector` called on them.
  bool get _linkingNeeded => _output.urlsNeedingInitReflector.isNotEmpty;

  /// Whether one or more functions or classes to be registered for reflection.
  bool get _registrationNeeded =>
      _output.registerClasses.isNotEmpty ||
      _output.registerFunctions.isNotEmpty;

  /// Whether the result of analysis is that this file is a complete no-op.
  bool get _isNoop => !_linkingNeeded && !_registrationNeeded;

  /// Returns whether to skip linking to [url].
  ///
  /// The view compiler may instruct us to defer additional source URLs if they
  /// were only used in order to refer to a component that is later deferred
  /// using the `@deferred` template syntax.
  bool _isUsedForDeferredComponentsOnly(String url) {
    if (deferredModules.isEmpty) {
      return false;
    }
    // Transforms the current source URL to an AssetId (canonical).
    final module = new AssetId.resolve(deferredModuleSource);
    // Given the url, resolve what absolute path that is.
    // We might get a relative path, but we only deal with absolute URLs.
    final asset = new AssetId.resolve(url, from: module);
    // The template compiler and package:build use a different asset: scheme.
    final assetUrl = 'asset:${asset.toString().replaceFirst('|', '/')}';
    return deferredModules.contains(assetUrl);
  }

  @override
  String emitImports() {
    _produceDartCode();
    return _importBuffer.toString();
  }

  @override
  String emitInitReflector() {
    _produceDartCode();
    return _initReflectorBuffer.toString();
  }

  void _produceDartCode() {
    if (_isNoop) {
      _importBuffer = new StringBuffer();
      _initReflectorBuffer = new StringBuffer(
        '// No initReflector() linking required.\nvoid initReflector(){}',
      );
      return;
    }

    // Only invoke this method once per instance of the class.
    if (_dartEmitter != null) {
      return;
    }

    // Prepare to write code.
    _importBuffer = new StringBuffer();
    _initReflectorBuffer = new StringBuffer();
    _dartEmitter = new _SplitDartEmitter(_importBuffer, _allocator);
    _library = new LibraryBuilder();

    // Reference _ngRef if we do any registration.
    if (_registrationNeeded) {
      _library.directives.add(
        new Directive.import(reflectorSource, as: '_ngRef'),
      );
    }

    // Create the initial (static) body of initReflector().
    _initReflectorBody = new BlockBuilder()
      ..statements.add(
        const Code(
          ''
              'if (_visited) {\n'
              '  return;\n'
              '}\n'
              '_visited = true;\n',
        ),
      );

    final initReflector = new MethodBuilder()
      ..name = 'initReflector'
      ..returns = refer('void');

    // For some classes, emit "const _{class}Metadata = const [ ... ]".
    //
    // This is used to:
    // 1. Allow use of ReflectiveInjector.
    // 2. Allow use of the AngularDart [v1] deprecated router.
    _output.registerClasses.forEach(_registerMetadataForClass);

    // Invoke 'initReflector' on other imported URLs.
    _linkToOtherInitReflectors();

    // Add initReflector() [to the end].
    _library.body.add(
      // var _visited = false;
      literalFalse.assignVar('_visited').statement,
    );

    initReflector.body = _initReflectorBody.build();
    _library.body.add(initReflector.build());

    // Write code to output.
    _library.build().accept(_dartEmitter, _initReflectorBuffer);
  }

  void _linkToOtherInitReflectors() {
    if (!_linkingNeeded) {
      return;
    }
    var counter = 0;
    for (final url in _output.urlsNeedingInitReflector) {
      if (_isUsedForDeferredComponentsOnly(url)) {
        continue;
      }
      // Generates:
      //
      // import "<url>" as _refN;
      //
      // void initReflector() {
      //   ...
      //   _refN.initReflector();
      // }
      final name = '_ref$counter';
      _library.directives.add(new Directive.import(url, as: name));
      _initReflectorBody.addExpression(
        refer(name).property('initReflector').call([]),
      );
      counter++;
    }
  }

  void _registerMetadataForClass(ReflectableClass clazz) {
    // Ignore any class that isn't a component.
    if (!clazz.registerComponentFactory) {
      return;
    }
    _initReflectorBody.addExpression(
      _registerComponent.call([
        refer(clazz.name),
        refer('${clazz.name}NgFactory'),
      ]),
    );
    if (clazz.registerAnnotation == null) {
      _registerEmptyMetadata(clazz.name);
    } else {
      // We arbitrarily support the `@RouteConfig` annotation for the router.
      _registerRouteConfig(clazz);
    }
  }

  void _registerRouteConfig(ReflectableClass clazz) {
    var source = clazz.element
        .computeNode()
        .metadata
        .firstWhere((a) => a.name.name == 'RouteConfig')
        .toSource();
    source = 'const ${source.substring(1)}';
    _library.body.add(
      new Code('const _${clazz.name}Metadata = const [$source];'),
    );
  }

  void _registerEmptyMetadata(String className) {
    _library.body.add(
      literalConstList([]).assignConst('_${className}Metadata').statement,
    );
  }
}

// Unlike the default [DartEmitter], this has two output buffers, which is used
// transitionally since other parts of the AngularDart compiler write code based
// on the existing "Output AST" format (string-based).
//
// Once/if all code is using code_builder, this can be safely removed.
class _SplitDartEmitter extends DartEmitter {
  final StringSink _writeImports;

  _SplitDartEmitter(
    this._writeImports, [
    Allocator allocator = Allocator.none,
  ])
      : super(allocator);

  @override
  visitDirective(Directive spec, [_]) {
    // Always write import/export directives to a separate buffer.
    return super.visitDirective(spec, _writeImports);
  }
}
