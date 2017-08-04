import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../types.dart';
import 'dependencies.dart';
import 'providers.dart';
import 'tokens.dart';

/// Determines details for providing dependency injection for a `@Component`.
///
/// **NOTE**: This class is _stateful_, and should be used once per component.
class ComponentReader {
  /// A `class` element annotated with `@Component`.
  final ClassElement component;

  /// `@Component` annotation object.
  @protected
  final ConstantReader annotation;

  /// Directives that were part of the template creating this component.
  ///
  /// i.e. `<comp dir1 dir2></comp>`, should have `[Dir1, Dir2]`.
  @protected
  final List<ClassElement> directives;

  @protected
  final DependencyReader dependencyReader;

  @protected
  final ProviderReader providerReader;

  DependencyInvocation<ConstructorElement> _dependencies;
  List<ProviderElement> _providers;
  List<ProviderElement> _viewProviders;

  ComponentReader(
    this.component, {
    this.dependencyReader: const DependencyReader(),
    this.directives: const [],
    this.providerReader: const ProviderReader(),
  })
      : this.annotation = new ConstantReader(
          $Component.firstAnnotationOfExact(component),
        );

  /// Details of the invocation required to create the component.
  DependencyInvocation<ConstructorElement> get dependencies {
    return _dependencies ??= dependencyReader.parseDependencies(component);
  }

  /// Returns whether [token] is visible to transcluded or view children.
  ///
  /// For example:
  /// ```dart
  /// @Component(
  ///   providers: const [
  ///     const Provider(ExampleService),
  ///   ],
  /// )
  /// class Comp {}
  /// ```
  ///
  /// ... would return `true` for a token representing `ExampleService`.
  bool provides(TokenElement token) =>
      providesForContent(token) || viewProviders.any((e) => e.token == token);

  /// Returns whether [token] is visible to transcluded children.
  ///
  /// For example:
  /// ```dart
  /// @Component(
  ///   providers: const [
  ///     const Provider(ExampleService),
  ///   ],
  ///   viewProviders: const [
  ///     const Provider(OtherService),
  ///   ],
  /// )
  /// class Comp {}
  /// ```
  ///
  /// ... would return `true` for a token representing `ExampleService` but
  /// would return `false` for a token representing `OtherService`.
  bool providesForContent(TokenElement token) =>
      providers.any((e) => e.token == token);

  /// Providers that are provided as part of `providers: [ ... ]` or directives.
  Iterable<ProviderElement> get providers {
    if (_providers == null) {
      final providers = annotation.read('providers');
      if (providers.isNull) {
        _providers = <ProviderElement>[];
      } else {
        _providers = providerReader.parseModule(providers.objectValue);
      }
      for (final directive in directives) {
        final annotation = $Directive.firstAnnotationOfExact(directive);
        final providers = new ConstantReader(annotation).read('providers');
        if (!providers.isNull) {
          _providers.addAll(providerReader.parseModule(providers.objectValue));
        }
      }
    }
    return _providers;
  }

  /// Providers that are provided as part of `viewProviders: [ ... ]`.
  Iterable<ProviderElement> get viewProviders {
    if (_viewProviders == null) {
      final providers = annotation.read('viewProviders');
      if (providers.isNull) {
        _viewProviders = <ProviderElement>[];
      } else {
        _viewProviders = providerReader.parseModule(providers.objectValue);
      }
    }
    return _viewProviders;
  }
}
