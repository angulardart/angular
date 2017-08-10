import 'package:analyzer/dart/element/element.dart';

import '../analyzer/di/dependencies.dart';
import '../analyzer/di/tokens.dart';
import '../analyzer/reflector.dart';

/// Generates `.dart` source code given a [ReflectableOutput].
class ReflectableEmitter {
  static const _package = 'package:angular';

  final String reflectorSource;
  final ReflectableOutput _output;

  const ReflectableEmitter(
    this._output, {
    this.reflectorSource: '$_package/src/di/reflector.dart',
  });

  bool get _linkingNeeded => _output.urlsNeedingInitReflector.isNotEmpty;

  bool get _registrationNeeded =>
      _output.registerClasses.isNotEmpty ||
      _output.registerFunctions.isNotEmpty;

  bool get _isNoop => !_linkingNeeded && !_registrationNeeded;

  /// Writes `import` statements needed for [emitInitReflector].
  ///
  /// They are all prefixed in a way that should not conflict with others.
  String emitImports() {
    if (_isNoop) {
      return '// No initReflector() linking required.\n';
    }
    final urls = _output.urlsNeedingInitReflector;
    final output = new StringBuffer('// Required for initReflector().\n');
    if (_registrationNeeded) {
      output.writeln("import '$reflectorSource' as _ngRef;");
    }
    if (_linkingNeeded)
      for (var i = 0; i < urls.length; i++) {
        output.writeln("import '${urls[i]}' as _ref$i;");
      }
    return (output..writeln()).toString();
  }

  /// Writes `initReflector`, including a preamble if required.
  String emitInitReflector() {
    if (_isNoop) {
      return '// No initReflector() needed.\nvoid initReflector() {}\n';
    }
    // _ExampleMetadata
    final output = new StringBuffer();
    for (final element in _output.registerClasses) {
      if (!element.registerComponentFactory) {
        continue;
      }
      if (element.registerAnnotation == null) {
        output.writeln('const _${element.name}Metadata = const [];');
      } else {
        var source = (element.factory.bound.returnType.element as ClassElement)
            .computeNode()
            .metadata
            .firstWhere((a) => a.name.name == 'RouteConfig')
            .toSource();
        source = 'const ${source.substring(1)}';
        output
          ..writeln('const _${element.name}Metadata = const [')
          ..writeln('  $source,')
          ..writeln('];');
      }
    }
    output.writeln('void initReflector() {');
    if (_linkingNeeded) {
      for (var i = 0; i < _output.urlsNeedingInitReflector.length; i++) {
        output.writeln('  _ref$i.initReflector();');
      }
    }
    if (_registrationNeeded) {
      for (final element in _output.registerFunctions) {
        output.writeln(_registerFactory(element));
      }
      for (final element in _output.registerClasses) {
        if (element.registerComponentFactory) {
          output.writeln(_registerComponent(element.name));
        }
        if (element.factory != null) {
          output.writeln(_registerFactory(element.factory));
        }
        if (element.registerAnnotation != null) {
          // TODO(matanl): Complete.
        }
      }
    }
    return (output..writeln('}')).toString();
  }

  String _registerComponent(String name) =>
      '  _ngRef.registerComponent(\n    $name,\n    ${name}NgFactory,\n  );';

  String _nameOfInvocation(DependencyInvocation invocation) {
    final bound = invocation.bound;
    if (bound is ConstructorElement) {
      return bound.returnType.element.name;
    }
    if (bound is FunctionElement) {
      return bound.name;
    }
    throw new UnsupportedError('Invalid type: ${bound.runtimeType}.');
  }

  String _invocationParams(DependencyInvocation invocation) =>
      new Iterable.generate(invocation.positional.length, (i) => 'p$i')
          .join(', ');

  String _generateFactory(DependencyInvocation invocation) =>
      '(${_generateParameters(invocation.positional).join(',\n')}) => '
      '${_invocationOf(invocation)}(${_invocationParams(invocation)})';

  Iterable<String> _generateParameters(List<DependencyElement> params) sync* {
    for (var i = 0; i < params.length; i++) {
      String type = 'dynamic';
      final element = params[i];
      final token = element.token;
      if (token is TypeTokenElement) {
        type = token.url.fragment;
      }
      yield '$type p$i';
    }
  }

  String _invocationOf(DependencyInvocation invocation) {
    final bound = invocation.bound;
    if (bound is ConstructorElement) {
      return 'new ${_nameOfInvocation(invocation)}';
    }
    if (bound is FunctionElement) {
      return bound.name;
    }
    throw new UnsupportedError('Invalid type: ${bound.runtimeType}.');
  }

  String _registerFactory(DependencyInvocation invocation) =>
      (new StringBuffer()
            ..writeln('  _ngRef.registerFactory(')
            ..writeln('    ${_nameOfInvocation(invocation)},')
            ..writeln('    ${_generateFactory(invocation)},')
            ..writeln('  );')
            ..writeln('  _ngRef.registerDependencies(')
            ..writeln('    ${_nameOfInvocation(invocation)},')
            ..writeln('    ${_generateDependencies(invocation)},')
            ..writeln('  );'))
          .toString();

  String _generateDependencies(DependencyInvocation invocation) {
    final output = new StringBuffer('const [');
    for (final param in invocation.positional) {
      output
        ..write('const [')
        ..write(_generateToken(param.token))
        ..write(',')
        ..write('],');
    }
    return (output..write(']')).toString();
  }

  String _generateToken(TokenElement token) => token is TypeTokenElement
      ? token.url.fragment
      : 'const OpaqueToken(${(token as OpaqueTokenElement).identifier})';
}
