import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' show LibraryReader;
import 'package:angular_compiler/v2/context.dart';

import '../analyzer/di/dependencies.dart';
import '../analyzer/di/tokens.dart';
import '../analyzer/link.dart';
import '../analyzer/reflector.dart';

/// Generates `.dart` source code given a [ReflectableOutput].
class ReflectableEmitter {
  static const _package = 'package:angular';

  /// Where the runtime `reflector.dart` is located.
  final String reflectorSource;

  final Allocator _allocator;
  final ReflectableOutput _output;

  /// The library that is being analyzed currently.
  final LibraryReader _library;

  DartEmitter? _dartEmitter;
  late LibraryBuilder _libraryBuilder;
  late BlockBuilder _initReflectorBody;
  late StringSink _importBuffer;
  late StringSink _initReflectorBuffer;

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

  ReflectableEmitter(
    this._output,
    this._library, {
    Allocator? allocator,
    this.reflectorSource = '$_package/src/reflector.dart',
  }) : _allocator = allocator ?? Allocator.none;

  /// Whether we have one or more URLs that need `initReflector` called on them.
  bool get _linkingNeeded => _output.urlsNeedingInitReflector.isNotEmpty;

  /// Whether one or more functions or classes to be registered for reflection.
  bool get _registrationNeeded =>
      _output.registerClasses.isNotEmpty ||
      _output.registerFunctions.isNotEmpty;

  /// Whether the result of analysis is that this file is a complete no-op.
  bool get _isNoop => !_linkingNeeded && !_registrationNeeded;

  /// Creates a manual tear-off of the provided constructor.
  Expression _tearOffConstructor(
    String? constructor,
    DependencyInvocation invocation,
  ) =>
      Method(
        (b) => b
          ..requiredParameters.addAll(
            _parameters(invocation.positional),
          )
          ..body = refer(constructor!)
              .newInstance(Iterable<Expression>.generate(
                invocation.positional.length,
                (i) => refer('p$i'),
              ))
              .code,
      ).closure;

  List<Parameter> _parameters(Iterable<DependencyElement> elements) {
    var counter = 0;
    return elements.map((element) {
      var type = element.type?.link ?? TypeLink.$dynamic;
      if (type.isDynamic) {
        final token = element.token;
        if (token is TypeTokenElement) {
          type = token.link;
        }
      }
      return Parameter((b) => b
        ..name = 'p${counter++}'
        ..type = linkToReference(type, _library)
            // TODO(b/185491084): move this inside linkToReference.
            .rebuild((b) => b..isNullable = type.isNullable));
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
      _importBuffer = StringBuffer();
      _initReflectorBuffer = StringBuffer(
        '// No initReflector() linking required.\nvoid initReflector(){}',
      );
      return;
    }

    // Only invoke this method once per instance of the class.
    if (_dartEmitter != null) {
      return;
    }

    // Prepare to write code.
    _importBuffer = StringBuffer();
    _initReflectorBuffer = StringBuffer();
    _dartEmitter = SplitDartEmitter(
      _importBuffer,
      allocator: _allocator,
      emitNullSafeSyntax: CompileContext.current.emitNullSafeCode,
    );
    _libraryBuilder = LibraryBuilder();

    // Reference _ngRef if we do any registration.
    if (_registrationNeeded) {
      _libraryBuilder.directives.add(
        Directive.import(reflectorSource, as: '_ngRef'),
      );
    }

    // Create the initial (static) body of initReflector().
    _initReflectorBody = BlockBuilder()
      ..statements.add(
        const Code(
          ''
          'if (_visited) {\n'
          '  return;\n'
          '}\n'
          '_visited = true;\n',
        ),
      );

    final initReflector = MethodBuilder()
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
    _libraryBuilder.build().accept(_dartEmitter!, _initReflectorBuffer);
  }

  void _linkToOtherInitReflectors() {
    if (!_linkingNeeded) {
      return;
    }
    var counter = 0;
    for (final url in _output.urlsNeedingInitReflector) {
      // Generates:
      //
      // import "<url>" as _refN;
      //
      // void initReflector() {
      //   ...
      //   _refN.initReflector();
      // }
      final name = '_ref$counter';
      _libraryBuilder.directives.add(Directive.import(url, as: name));
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
          refer('create${clazz.name}Factory').call([]),
        ]),
      );
    }

    // Legacy support for ReflectiveInjector.
    var clazzFactory = clazz.factory;
    if (clazzFactory != null) {
      _registerConstructor(clazzFactory);
      _registerParametersForFunction(clazzFactory);
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

    String name;
    if (bound is ConstructorElement) {
      name = bound.enclosingElement.name;
    } else if (bound is MethodElement) {
      name = '${bound.enclosingElement.name}.${bound.name}';
    } else {
      name = bound!.name!;
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
    if (token is OpaqueTokenElement) {
      final classType = linkToReference(token.classUrl, _library);
      final tokenInstance = classType.constInstance(
        token.identifier.isNotEmpty ? [literalString(token.identifier)] : [],
        {},
      );
      return _Inject.constInstance([tokenInstance]);
    }
    if (token is TypeTokenElement) {
      return linkToReference(token.link.withoutGenerics(), _library);
    }
    throw UnsupportedError('Invalid token type: $token.');
  }

  void _registerConstructor(
      DependencyInvocation<ConstructorElement?> function) {
    // _ngRef.registerFactory(Type, (p0, p1) => new Type(p0, p1));
    final bound = function.bound!;
    final clazz = bound.returnType;
    var constructor = clazz.name;
    // Support named constructors.
    if (bound.name.isNotEmpty == true) {
      constructor = '$constructor.${bound.name}';
    }
    _initReflectorBody.addExpression(
      _registerFactory.call([
        refer(clazz.name!),
        _tearOffConstructor(constructor, function),
      ]),
    );
  }
}

// Unlike the default [DartEmitter], this has two output buffers, which is used
// transitionally since other parts of the AngularDart compiler write code based
// on the existing "Output AST" format (string-based).
//
// Once/if all code is using code_builder, this can be safely removed.
class SplitDartEmitter extends DartEmitter {
  final StringSink? _writeImports;

  SplitDartEmitter(
    this._writeImports, {
    Allocator allocator = Allocator.none,
    bool emitNullSafeSyntax = false,
  }) : super(
          allocator: allocator,
          orderDirectives: false,
          useNullSafetySyntax: emitNullSafeSyntax,
        );

  @override
  StringSink visitDirective(Directive spec, [_]) {
    // Always write import/export directives to a separate buffer.
    return super.visitDirective(spec, _writeImports);
  }
}
