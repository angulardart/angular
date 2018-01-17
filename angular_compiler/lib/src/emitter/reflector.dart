import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';

import '../analyzer/di/dependencies.dart';
import '../analyzer/di/tokens.dart';
import '../analyzer/link.dart';
import '../analyzer/reflector.dart';

import 'reflector_2.dart';

/// Generates `.dart` source code given a [ReflectableOutput].
class ReflectableEmitter {
  static const _package = 'package:angular';

  /// Optional, may be specified in order to avoid linking to specified URLs.
  ///
  /// These are expected in the fully-qualified `asset:...` notation, including
  /// both relative files and `package: ...` imports.
  ///
  /// For example in the case of using the `@deferred` feature, we don't want
  /// to call "initReflector(...)" on the components' modules.
  final Iterable<String> deferredModules;

  /// If [deferredModules] is non-empty, this is expected to be provided.
  final String deferredModuleSource;

  final String reflectorSource;
  final ReflectableOutput _output;

  const ReflectableEmitter(
    this._output, {
    this.reflectorSource: '$_package/src/di/reflector.dart',
    List<String> deferredModules,
    this.deferredModuleSource,
  })
      : this.deferredModules = deferredModules ?? const [];

  /// Alternative constructor that uses a different output strategy.
  factory ReflectableEmitter.useCodeBuilder(
    ReflectableOutput output, {
    Allocator allocator,
    String reflectorSource,
    List<String> deferredModules,
    String deferredModuleSource,
  }) = CodeBuilderReflectableEmitter;

  bool get _linkingNeeded => _output.urlsNeedingInitReflector.isNotEmpty;

  bool get _registrationNeeded =>
      _output.registerClasses.isNotEmpty ||
      _output.registerFunctions.isNotEmpty;

  bool get _isNoop => !_linkingNeeded && !_registrationNeeded;

  /// Returns true if [url] should not be omitted for linking `initReflector()`.
  ///
  /// If the Angular compiler is going to manually load another component (for
  /// example for `@deferred` loading), then we want to delegate to the template
  /// compiler and not invoke `initReflector()` ourselves.
  bool _isDeferred(String url) {
    if (deferredModules.isEmpty) {
      return false;
    }
    // Create an asset URL for the current module URL (asset:../../*.dart).
    final module = new AssetId.resolve(deferredModuleSource);
    // Give the prospective [url] parameter, resolve what absolute path that is.
    final asset = new AssetId.resolve(url, from: module);
    // The template compiler and package:build use a different asset: scheme.
    final assetUrl = 'asset:${asset.toString().replaceFirst('|', '/')}';
    return deferredModules.contains(assetUrl);
  }

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
        if (_isDeferred(urls[i])) {
          continue;
        }
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
        var source = element.element
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
        if (_isDeferred(_output.urlsNeedingInitReflector[i])) {
          continue;
        }
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
    throw new UnsupportedError('Unexpected element: $bound.');
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
            ? '${token.prefix}${token.link.symbol}'
            : token.link.symbol;
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
    throw new UnsupportedError('Unexpected element: $bound.');
  }

  String _registerFactory(DependencyInvocation invocation) {
    final buffer = new StringBuffer();
    if (invocation.bound is ConstructorElement) {
      // Only store the factory function for constructors (useClass: ...).
      buffer
        ..writeln('  _ngRef.registerFactory(')
        ..writeln('    ${_nameOfInvocation(invocation)},')
        ..writeln('    ${_generateFactory(invocation)},')
        ..writeln('  );');
    }
    if (invocation.positional.isNotEmpty) {
      buffer
        ..writeln('  _ngRef.registerDependencies(')
        ..writeln('    ${_nameOfInvocation(invocation)},')
        ..writeln('    ${_generateDependencies(invocation)},')
        ..writeln('  );');
    }
    return buffer.toString();
  }

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
      // TODO(matanl): Make this more solid.
      //
      // Ideally we should be using code_builder for this entire class, as it
      // would handle import resolution, etc, and make the code more future
      // proof.
      //
      // As-is, this will breakdown if the generic type of an OpaqueToken is
      // imported with a prefix, for example:
      //
      //   const fooToken = const OpaqueToken<foo.Foo>('fooToken');
      //
      // Since this feature is still WIP, this is acceptable, but it should be
      // fixed 5.0-beta: https://github.com/dart-lang/angular/issues/782.
      final classType = token.isMultiToken ? 'MultiToken' : 'OpaqueToken';
      final genericTypeIfAny = _typesAsString([token.typeUrl]);
      final expression =
          'const _ngRef.$classType$genericTypeIfAny(r\'${token.identifier}\')';
      return 'const _ngRef.Inject($expression)';
    }
    if (token is TypeTokenElement) {
      return token.prefix != null
          ? '${token.prefix}${token.link.symbol}'
          : token.link.symbol;
    }
    throw new UnsupportedError('Invalid token type: $token.');
  }

  static String _typesAsString(List<TypeLink> types) {
    if (types.isEmpty) {
      return '';
    }
    return '<${types.map((l) => l.symbol + _typesAsString(l.generics)).join(', ')}>';
  }
}
