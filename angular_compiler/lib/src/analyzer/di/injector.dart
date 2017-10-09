import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../types.dart';
import 'modules.dart';
import 'providers.dart';

/// Determines details for generating code as a result of `@Injector.generate`.
///
/// **NOTE**: This class is _stateful_, and should be used once per annotation.
class InjectorReader {
  static bool _shouldGenerateInjector(FunctionElement element) {
    return $_GenerateInjector.hasAnnotationOfExact(element);
  }

  /// Returns a list of all injectors needing generation in [element].
  static List<InjectorReader> findInjectors(LibraryElement element) =>
      element.definingCompilationUnit.functions
          .where(_shouldGenerateInjector)
          .map((fn) => new InjectorReader(fn))
          .toList();

  /// `@Injector.generate` annotation object;
  final ConstantReader annotation;

  /// A function element annotated with `@Injector.generate`.
  final FunctionElement method;

  @protected
  final ModuleReader moduleReader;

  Set<ProviderElement> _providers;

  InjectorReader(
    this.method, {
    this.moduleReader: const ModuleReader(),
  })
      : this.annotation = new ConstantReader(
          $_GenerateInjector.firstAnnotationOfExact(method),
        );

  /// Name of the `Injector` that should be generated.
  String get name => '${method.name}\$Injector';

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
}
