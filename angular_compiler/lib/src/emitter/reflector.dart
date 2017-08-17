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
    output
      // Can't write "bool", in case `import 'dart:core' as core` is used.
      ..writeln('var _visited = false;')
      ..writeln('void initReflector() {')
      ..writeln('  if (_visited) {')
      ..writeln('    return;')
      ..writeln('  }')
      ..writeln('  _visited = true;');
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
      }
    }
    return (output..writeln('}')).toString();
  }

  String _registerComponent(String name) =>
      '  _ngRef.registerComponent(\n    $name,\n    ${name}NgFactory,\n  );';

  String _nameOfInvocation(
    DependencyInvocation invocation, {
    bool checkNamedConstructor: false,
  }) {
    final bound = invocation.bound;
    if (bound is ConstructorElement) {
      final clazz = bound.returnType.element.name;
      if (checkNamedConstructor && bound?.name?.isNotEmpty == true) {
        return '$clazz.${bound.name}';
      }
      return clazz;
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
      invocation.bound is FunctionElement
          ? invocation.bound.name
          : '(${_generateParameters(invocation.positional).join(', ')}) => '
          '${_invocationOf(invocation)}(${_invocationParams(invocation)})';

  Iterable<String> _generateParameters(List<DependencyElement> params) sync* {
    for (var i = 0; i < params.length; i++) {
      String type = '';
      final element = params[i];
      final token = element.type ?? element.token;
      if (token is TypeTokenElement && !token.isDynamic) {
        type = token.prefix != null
            ? '${token.prefix}${token.url.fragment}'
            : token.url.fragment;
      }
      yield '$type p$i';
    }
  }

  String _invocationOf(DependencyInvocation invocation) {
    final bound = invocation.bound;
    if (bound is ConstructorElement) {
      final expression = _nameOfInvocation(
        invocation,
        checkNamedConstructor: true,
      );
      return 'new $expression';
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
      output..write('const [')..write(_generateToken(param.token))..write(',');
      if (param.skipSelf) {
        output.write('const _ngRef.SkipSelf(),');
      }
      if (param.optional) {
        output.write('const _ngRef.Optional(),');
      }
      if (param.self) {
        output.write('const _ngRef.Self(),');
      }
      if (param.host) {
        output.write('const _ngRef.Host(),');
      }
      output..write('],');
    }
    return (output..write(']')).toString();
  }

  String _generateToken(TokenElement token) {
    if (token is LiteralTokenElement) {
      return 'const _ngRef.Inject(${token.literal})';
    }
    if (token is OpaqueTokenElement) {
      final expression = 'const _ngRef.OpaqueToken(r\'${token.identifier}\')';
      return 'const _ngRef.Inject($expression)';
    }
    if (token is TypeTokenElement) {
      return token.prefix != null
          ? '${token.prefix}${token.url.fragment}'
          : token.url.fragment;
    }
    throw new UnsupportedError('Invalid token type: $token.');
  }
}
