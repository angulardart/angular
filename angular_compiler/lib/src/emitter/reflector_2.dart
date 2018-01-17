import 'package:code_builder/code_builder.dart';

import '../analyzer/reflector.dart';

import 'reflector.dart';

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

  // ignore: unused_field
  final ReflectableOutput _output;

  DartEmitter _dartEmitter;
  StringSink _importBuffer;
  StringSink _initReflectorBuffer;

  CodeBuilderReflectableEmitter(
    this._output, {
    Allocator allocator,
    this.reflectorSource: '$_package/src/di/reflector.dart',
    List<String> deferredModules,
    this.deferredModuleSource,
  })
      : _allocator = allocator ?? Allocator.none,
        deferredModules = deferredModules ?? const [];

  @override
  String emitImports() {
    _produceDartCode();
    return _initReflectorBuffer.toString();
  }

  @override
  String emitInitReflector() {
    _produceDartCode();
    return _importBuffer.toString();
  }

  void _produceDartCode() {
    // Only invoke this method once per instance of the class.
    if (_dartEmitter != null) {
      return;
    }
    _importBuffer = new StringBuffer();
    _initReflectorBuffer = new StringBuffer();
    _dartEmitter = new _SplitDartEmitter(_importBuffer, _allocator);
    // TODO(matanl): Actually implement. This is an empty no-op.
    final library = new LibraryBuilder();
    library.build().accept(_dartEmitter, _initReflectorBuffer);
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
