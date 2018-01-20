import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' show LibraryReader;

import '../analyzer/di/dependencies.dart';
import '../analyzer/di/tokens.dart';
import '../analyzer/link.dart';
import '../analyzer/reflector.dart';

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

  /// Origin of the analyzed library.
  ///
  /// If [deferredModules] is non-empty, this is expected to be provided.
  final String deferredModuleSource;

  /// Where the runtime `reflector.dart` is located.
  final String reflectorSource;

  final Allocator _allocator;
  final ReflectableOutput _output;

  /// The library that is being analyzed currently.
  final LibraryReader _library;

  DartEmitter _dartEmitter;
  LibraryBuilder _libraryBuilder;
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

  ReflectableEmitter(
    this._output,
    this._library, {
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

  /// Creates a manual tear-off of the provided constructor.
  Expression _tearOffConstructor(
    String constructor,
    DependencyInvocation invocation,
  ) =>
      new Method(
        (b) => b
          ..requiredParameters.addAll(
            _parameters(invocation.positional),
          )
          ..body = refer(constructor)
              .newInstance(new Iterable<Expression>.generate(
                invocation.positional.length,
                (i) => refer('p$i'),
              ))
              .code,
      ).closure;

  List<Parameter> _parameters(Iterable<DependencyElement> elements) {
    var counter = 0;
    return elements.map((element) {
      TypeLink type = element.type?.link ?? TypeLink.$dynamic;
      if (type.isDynamic) {
        final token = element.token;
        if (token is TypeTokenElement) {
          type = token.link;
        }
      }
      return new Parameter((b) => b
        ..name = 'p${counter++}'
        ..type = linkToReference(type, _library));
    }).toList();
  }

  /// Writes `import` statements needed for [emitInitReflector].
  ///
  /// They are all prefixed in a way that should not conflict with others.
  String emitImports() {
    _produceDartCode();
    return _importBuffer.toString();
  }

  /// Writes `initReflector`, including a preamble if required.
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
    _libraryBuilder = new LibraryBuilder();

    // Reference _ngRef if we do any registration.
    if (_registrationNeeded) {
      _libraryBuilder.directives.add(
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

    // For some classes and functions, link to the factory.
    //
    // This is used to allow use of ReflectiveInjector.
    _output.registerFunctions.forEach(_registerParametersForFunction);

    // Invoke 'initReflector' on other imported URLs.
    _linkToOtherInitReflectors();

    // Add initReflector() [to the end].
    _libraryBuilder.body.add(
      // var _visited = false;
      literalFalse.assignVar('_visited').statement,
    );

    initReflector.body = _initReflectorBody.build();
    _libraryBuilder.body.add(initReflector.build());

    // Write code to output.
    _libraryBuilder.build().accept(_dartEmitter, _initReflectorBuffer);
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
      _libraryBuilder.directives.add(new Directive.import(url, as: name));
      _initReflectorBody.addExpression(
        refer(name).property('initReflector').call([]),
      );
      counter++;
    }
  }

  void _registerMetadataForClass(ReflectableClass clazz) {
    // Ignore any class that isn't a component.
    if (clazz.registerComponentFactory) {
      // Legacy support for SlowComponentLoader.
      _initReflectorBody.addExpression(
        _registerComponent.call([
          refer(clazz.name),
          refer('${clazz.name}NgFactory'),
        ]),
      );

      // Legacy support for the AngularDart router [v1].
      if (clazz.registerAnnotation == null) {
        _registerEmptyMetadata(clazz.name);
      } else {
        // We arbitrarily support the `@RouteConfig` annotation for the router.
        _registerRouteConfig(clazz);
      }
    }

    // Legacy support for ReflectiveInjector.
    if (clazz.factory != null) {
      _registerConstructor(clazz.factory);
      _registerParametersForFunction(clazz.factory);
    }
  }

  void _registerParametersForFunction(
    DependencyInvocation functionOrConstructor,
  ) {
    // Optimization: Don't register dependencies for zero-arg functions.
    if (functionOrConstructor.positional.isEmpty) {
      return;
    }
    // _ngRef.registerDependencies(functionOrType, [ ... ]).
    final bound = functionOrConstructor.bound;

    // Get either the function or class name (not the constructor name).
    var name = bound.name;
    if (bound is ConstructorElement) {
      name = bound.enclosingElement.name;
    }

    _initReflectorBody.addExpression(
      _registerDependencies.call([
        refer(name),
        literalConstList(_dependencies(functionOrConstructor.positional)),
      ]),
    );
  }

  List<Expression> _dependencies(Iterable<DependencyElement> parameters) {
    final expressions = <Expression>[];
    for (final param in parameters) {
      final value = <Expression>[_token(param.token)];
      if (param.skipSelf) {
        value.add(_SkipSelf.constInstance(const []));
      }
      if (param.optional) {
        value.add(_Optional.constInstance(const []));
      }
      if (param.self) {
        value.add(_Self.constInstance(const []));
      }
      if (param.host) {
        value.add(_Host.constInstance(const []));
      }
      expressions.add(literalConstList(value));
    }
    return expressions;
  }

  Expression _token(TokenElement token) {
    if (token is LiteralTokenElement) {
      return _Inject.constInstance([refer(token.literal)]);
    }
    if (token is OpaqueTokenElement) {
      final classType = token.isMultiToken ? _MultiToken : _OpaqueToken;
      final tokenInstance = classType.constInstance(
        [literalString(token.identifier)],
        {},
        [linkToReference(token.typeUrl, _library)],
      );
      return _Inject.constInstance([tokenInstance]);
    }
    if (token is TypeTokenElement) {
      return linkToReference(token.link.withoutGenerics(), _library);
    }
    throw new UnsupportedError('Invalid token type: $token.');
  }

  void _registerConstructor(DependencyInvocation<ConstructorElement> function) {
    // _ngRef.registerFactory(Type, (p0, p1) => new Type(p0, p1));
    final bound = function.bound;
    final clazz = bound.returnType;
    var constructor = clazz.name;
    // Support named constructors.
    if (bound.name?.isNotEmpty == true) {
      constructor = '$constructor.${bound.name}';
    }
    _initReflectorBody.addExpression(
      _registerFactory.call([
        refer(clazz.name),
        _tearOffConstructor(constructor, function),
      ]),
    );
  }

  void _registerRouteConfig(ReflectableClass clazz) {
    var source = clazz.element
        .computeNode()
        .metadata
        .firstWhere((a) => a.name.name == 'RouteConfig')
        .toSource();
    source = 'const ${source.substring(1)}';
    _libraryBuilder.body.add(
      new Code('const _${clazz.name}Metadata = const [$source];'),
    );
  }

  void _registerEmptyMetadata(String className) {
    _libraryBuilder.body.add(
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
