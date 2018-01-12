import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import '../link.dart';
import '../types.dart';
import 'dependencies.dart';
import 'modules.dart';
import 'providers.dart';
import 'tokens.dart';

/// Determines details for generating code as a result of `@Injector.generate`.
class InjectorReader {
  static const _package = 'package:angular';
  static const _runtime = '$_package/src/di/injector/injector.dart';
  static const _$Injector = const Reference('Injector', _runtime);

  static bool _shouldGenerateInjector(FunctionElement element) {
    return $_GenerateInjector.hasAnnotationOfExact(element);
  }

  /// Returns a list of all injectors needing generation in [element].
  static List<InjectorReader> findInjectors(LibraryElement element) {
    final source = element.source.uri;
    if (source == null) {
      throw new StateError('Expected a source for $element.');
    }
    return element.definingCompilationUnit.functions
        .where(_shouldGenerateInjector)
        .map((fn) => new InjectorReader(fn, doNotScope: source))
        .toList();
  }

  /// `@Injector.generate` annotation object;
  final ConstantReader annotation;

  /// A function element annotated with `@Injector.generate`.
  final FunctionElement method;

  @protected
  final ModuleReader moduleReader;

  /// Originating file URL.
  ///
  /// If non-null, references to symbols in this URL are not scoped.
  ///
  /// Workaround for https://github.com/dart-lang/code_builder/issues/148.
  @protected
  final Uri doNotScope;

  List<ProviderElement> _providers;

  InjectorReader(
    this.method, {
    this.moduleReader: const ModuleReader(),
    this.doNotScope,
  })
      : this.annotation = new ConstantReader(
          $_GenerateInjector.firstAnnotationOfExact(method),
        );

  /// Providers that are part of the provided list of the annotation.
  Iterable<ProviderElement> get providers {
    if (_providers == null) {
      final module = moduleReader.parseModule(
        annotation.read('providersOrModules').objectValue,
      );
      _providers = moduleReader.deduplicateProviders(module.flatten());
    }
    return _providers;
  }

  /// Creates a codegen reference to [symbol] in [url].
  ///
  /// Compares against [doNotScope], which is usually the current library. This
  /// is required because while some URLs can be referenced via `package:`,
  /// others cannot (i.e. those in a `test` directory), so we need to compute
  /// the relative path to them.
  Reference _referSafe(String symbol, String url) {
    final toUrl = Uri.parse(url);
    if (doNotScope != null && toUrl.scheme == 'asset') {
      return _referRelative(symbol, toUrl);
    }
    return refer(symbol, toUrl.toString());
  }

  Reference _referRelative(String symbol, Uri url) {
    // URL segments indicating the origin.
    final from = p.split(doNotScope.normalizePath().path)..removeLast();

    // URL segments indicating the target.
    final to = p.split(url.path);

    // This is pointing to a package: location. We can safely just link.
    if (to[1] == 'lib') {
      to.removeAt(1);
      return refer(symbol, 'package:${to.join('/')}');
    }

    // Verify this is the same package:.
    if (to[0] != from[0]) {
      return refer(symbol, url.toString());
    }

    // This is pointing to a true asset: location, needing a relative link.
    final path = p.relative(to.skip(2).join('/'), from: from.skip(2).join('/'));
    return refer(symbol, path);
  }

  Expression _tokenToIdentifier(TokenElement token) {
    if (token is TypeTokenElement) {
      return _referSafe(token.link.symbol, token.link.import);
    }
    final opaqueToken = token as OpaqueTokenElement;
    final tokenClass = opaqueToken.isMultiToken ? 'MultiToken' : 'OpaqueToken';
    final preciseToken = new TypeReference((b) {
      b.symbol = tokenClass;
      b.url = _runtime;
      if (opaqueToken.typeUrl != null) {
        b.types.add(linkToReference(opaqueToken.typeUrl));
      }
    });
    return preciseToken.constInstance([
      literalString(opaqueToken.identifier),
    ]);
  }

  List<Expression> _computeDependencies(Iterable<DependencyElement> deps) {
    // TODO(matanl): Optimize.
    return deps.map((dep) {
      if (dep.self) {
        if (dep.optional) {
          return refer('injectFromSelfOptional').call([
            _tokenToIdentifier(dep.token),
            literalNull,
          ]);
        } else {
          return refer('injectFromSelf').call([
            _tokenToIdentifier(dep.token),
          ]);
        }
      }
      if (dep.skipSelf) {
        if (dep.optional) {
          return refer('injectFromAncestryOptional').call([
            _tokenToIdentifier(dep.token),
            literalNull,
          ]);
        } else {
          return refer('injectFromAncestry').call([
            _tokenToIdentifier(dep.token),
          ]);
        }
      }
      if (dep.host) {
        if (dep.optional) {
          return refer('injectFromParentOptional').call([
            _tokenToIdentifier(dep.token),
            literalNull,
          ]);
        } else {
          return refer('injectFromParent').call([
            _tokenToIdentifier(dep.token),
          ]);
        }
      }
      if (dep.optional) {
        return refer('injectOptional').call([
          _tokenToIdentifier(dep.token),
          literalNull,
        ]);
      } else {
        return refer('inject').call([
          _tokenToIdentifier(dep.token),
        ]);
      }
    }).toList();
  }

  /// Uses [visitor] to emit the results of this reader.
  void accept(InjectorVisitor visitor) {
    visitor.visitMeta('_Injector\$${method.name}', '${method.name}\$Injector');
    var index = 0;
    for (final provider in providers) {
      if (provider is UseValueProviderElement) {
        var useValue = provider.useValue;
        if (useValue is Revivable) {
          // TODO(matanl): Make this an error once cases we support are ready.
          log.warning(''
              'Cannot resolve useValue: for ${provider.token}.\n'
              'Most constant expressions are not yet supported.');
          useValue = ''
              '(() => throw new UnimplementedError(r"""Does not yet useValue: '
              '<const expression> for ${provider.token}"""))()';
        } else if (useValue is String) {
          useValue = 'r"""$useValue"""';
        }
        visitor.visitProvideValue(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          linkToReference(provider.providerType),
          refer(useValue),
          provider.isMulti,
        );
      } else if (provider is UseClassProviderElement) {
        final name = provider.dependencies.bound.name;
        visitor.visitProvideClass(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          _referSafe(provider.useClass.symbol, provider.useClass.import),
          name.isNotEmpty ? name : null,
          _computeDependencies(provider.dependencies.positional),
          provider.isMulti,
        );
      } else if (provider is UseFactoryProviderElement) {
        visitor.visitProvideFactory(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          linkToReference(provider.providerType),
          _referSafe(
            provider.useFactory.fragment,
            provider.useFactory.removeFragment().toString(),
          ),
          _computeDependencies(provider.dependencies.positional),
          provider.isMulti,
        );
      } else if (provider is UseExistingProviderElement) {
        visitor.visitProvideExisting(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          linkToReference(provider.providerType),
          _tokenToIdentifier(provider.redirect),
          provider.isMulti,
        );
      }
      index++;
    }
    // Implicit provider: provide(Injector).
    visitor.visitProvideValue(
      index,
      null,
      _$Injector,
      _$Injector,
      refer('this'),
      false,
    );
  }
}

/// To be implemented by an emitter class to create a `GeneratedInjector`.
abstract class InjectorVisitor {
  /// Implement storing meta elements of this injector, such as its [name].
  void visitMeta(String className, String factoryName);

  /// Implement providing a new instance of [type], calling [constructor].
  ///
  /// Any [dependencies] are expected to invoke local methods as appropriate:
  /// ```dart
  /// refer('inject').call([refer('Dep1')])
  /// ```
  void visitProvideClass(
    int index,
    TokenElement token,
    Expression tokenExpression,
    Reference type,
    String constructor,
    List<Expression> dependencies,
    bool isMulti,
  );

  /// Implement redirecting to [redirect] when [token] is requested.
  void visitProvideExisting(
    int index,
    TokenElement token,
    Expression tokenExpression,
    Reference type,
    Expression redirect,
    bool isMulti,
  );

  /// Implement providing [token] by calling [function].
  ///
  /// Any [dependencies] are expected to invoke local methods as appropriate:
  /// ```dart
  /// refer('inject').call([refer('Dep1')])
  /// ```
  void visitProvideFactory(
    int index,
    TokenElement token,
    Expression tokenExpression,
    Reference returnType,
    Reference function,
    List<Expression> dependencies,
    bool isMulti,
  );

  /// Implement providing [value] when [token] is requested.
  void visitProvideValue(
    int index,
    TokenElement token,
    Expression tokenExpression,
    Reference returnType,
    Expression value,
    bool isMulti,
  );
}
