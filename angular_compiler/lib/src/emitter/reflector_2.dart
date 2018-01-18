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

  Reference _ngRef(String symbol) => refer(reflectorSource, symbol);

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
      ..returns = refer('void')
      ..body = _initReflectorBody.build();

    // For some classes, emit "const _{class}Metadata = const [ ... ]".
    //
    // This is used to:
    // 1. Allow use of ReflectiveInjector.
    // 2. Allow use of the AngularDart [v1] deprecated router.
    _output.registerClasses.forEach(_registerMetadataFor);

    // Add initReflector() [to the end].
    _library.body.add(
      // var _visited = false;
      literalFalse.assignVar('_visited').statement,
    );
    _library.body.add(initReflector.build());

    // Write code to output.
    _library.build().accept(_dartEmitter, _initReflectorBuffer);
  }

  void _registerMetadataFor(ReflectableClass clazz) {
    if (!clazz.registerComponentFactory) {
      return;
    }
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
