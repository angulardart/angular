import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import '../common.dart';
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
  static List<InjectorReader> findInjectors(LibraryElement element) =>
      element.definingCompilationUnit.functions
          .where(_shouldGenerateInjector)
          .map((fn) => new InjectorReader(fn, doNotScope: element.source.uri))
          .toList();

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

  Reference _referToProxy(Uri to) {
    if (doNotScope != null && to.scheme == 'asset') {
      final normalizedBased = doNotScope.normalizePath();
      final baseSegments = p.split(normalizedBased.path)..removeLast();
      final targetSegments = p.split(to.path);
      if (baseSegments.first == targetSegments.first &&
          baseSegments[1] == targetSegments[1]) {
        final relativePath = p.relative(
          targetSegments.skip(2).join('/'),
          from: baseSegments.skip(2).join('/'),
        );
        return referTo(new Uri(path: relativePath, fragment: to.fragment));
      }
    }
    return referTo(to);
  }

  Expression _tokenToIdentifier(TokenElement token) {
    if (token is TypeTokenElement) {
      return _referToProxy(token.url);
    }
    final opaqueToken = token as OpaqueTokenElement;
    final tokenClass = opaqueToken.isMultiToken ? 'MultiToken' : 'OpaqueToken';
    return new Reference(tokenClass, _runtime).constInstance([
      literalString(opaqueToken.identifier),
    ]);
  }

  // TODO(matanl): Support nested generics, i.e. List<T>, Map<K, V>.
  static Reference _urlToReference(Uri typeUrl) {
    return refer(typeUrl.fragment, typeUrl.removeFragment().toString());
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
          _urlToReference(provider.providerType),
          refer(useValue),
          provider.isMulti,
        );
      } else if (provider is UseClassProviderElement) {
        final name = provider.dependencies.bound.name;
        visitor.visitProvideClass(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          _referToProxy(provider.useClass),
          name.isNotEmpty ? name : null,
          _computeDependencies(provider.dependencies.positional),
          provider.isMulti,
        );
      } else if (provider is UseFactoryProviderElement) {
        visitor.visitProvideFactory(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          _urlToReference(provider.providerType),
          _referToProxy(provider.useFactory),
          _computeDependencies(provider.dependencies.positional),
          provider.isMulti,
        );
      } else if (provider is UseExistingProviderElement) {
        visitor.visitProvideExisting(
          index,
          provider.token,
          _tokenToIdentifier(provider.token),
          _urlToReference(provider.providerType),
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
