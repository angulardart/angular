import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'di/dependencies.dart';
import 'types.dart';

/// Determines how to generate and link to `initReflector` in other files.
///
/// AngularDart's `initReflector` is used to create a graph of all generated
/// code that mirrors user-authored code. Significant classes and factories are
/// recorded into a global map and can be used at runtime (via the `reflector`).
///
/// The recorder has various options on how much recording is required for a
/// given application, with the end-goal being requiring little or none for most
/// applications.
class ReflectableReader {
  /// Used to read dependencies from dart objects.
  final DependencyReader dependencyReader;

  /// Whether to treat an `@Component`-annotated `class` as an `@Component`.
  ///
  /// This means that a factory to create the component at runtime needs to be
  /// registered. This also disables tree-shaking classes annotated with
  /// `@Component`.
  final bool recordComponentsAsInjectables;

  /// Whether to treat an `@Directive`-annotated `class` as an `@Injectable`.
  ///
  /// This means that a factory to create the directive at runtime needs to be
  /// registered. This also disables tree-shaking classes annotated with
  /// `@Directive`.
  final bool recordDirectivesAsInjectables;

  /// Whether to treat a `@Pipe`-annotated `class` as an `@Injectable`.
  ///
  /// This means that a factory to create the pipe at runtime needs to be
  /// registered. This also disables tree-shaking classes annotated with
  /// `@Pipe`.
  final bool recordPipesAsInjectables;

  /// Whether to record `@RouteConfig`s for `@Component`-annotated classes.
  ///
  /// This is only required in order to support the legacy router, which looks
  /// up metadata information at runtime in order to configure itself.
  final bool recordRouterAnnotationsForComponents;

  const ReflectableReader({
    this.dependencyReader: const DependencyReader(),
    this.recordComponentsAsInjectables: true,
    this.recordDirectivesAsInjectables: true,
    this.recordPipesAsInjectables: true,
    this.recordRouterAnnotationsForComponents: true,
  });

  /// Returns information needed to write `.template.dart` files.
  Future<ReflectableOutput> resolve(LibraryElement library) async {
    final unit = library.definingCompilationUnit;
    final urlsNeedingInitReflector = <String>[]; // TODO: Implement.
    final registerClasses = <ReflectableClass>[];
    for (final type in unit.types) {
      final reflectable = _resolveClass(type);
      if (reflectable != null) {
        registerClasses.add(reflectable);
      }
    }
    final registerFunctions = unit.functions
        .where((e) => $Injectable.firstAnnotationOfExact(e) != null)
        .map(dependencyReader.parseDependencies)
        .toList();
    return new ReflectableOutput(
      urlsNeedingInitReflector: urlsNeedingInitReflector,
      registerClasses: registerClasses,
      registerFunctions: registerFunctions,
    );
  }

  ReflectableClass _resolveClass(ClassElement element) {
    DependencyInvocation<ConstructorElement> factory;
    if (_shouldRecordFactory(element)) {
      factory = dependencyReader.parseDependencies(element);
    }
    final isComponent = $Component.firstAnnotationOfExact(element) != null;
    if (factory == null && !isComponent) {
      return null;
    }
    return new ReflectableClass(
      factory: factory,
      name: element.name,
      registerAnnotation: recordRouterAnnotationsForComponents && isComponent
          ? _findRouteConfig(element)?.revive()
          : null,
      registerComponentFactory: isComponent,
    );
  }

  // We don't use a TypeChecker because this is in another library, and would
  // complicate things. Since this is only a single annotation that is rarely
  // used (and will be removed), it's not a big deal.
  ConstantReader _findRouteConfig(ClassElement element) {
    for (final annotation in element.metadata) {
      final object = annotation.computeConstantValue();
      if (object?.type?.name == 'RouteConfig') {
        return new ConstantReader(object);
      }
    }
    return null;
  }

  bool _shouldRecordFactory(ClassElement element) =>
      $Injectable.firstAnnotationOfExact(element) != null ||
      recordComponentsAsInjectables &&
          $Component.firstAnnotationOfExact(element) != null ||
      recordDirectivesAsInjectables &&
          $Directive.firstAnnotationOfExact(element) != null ||
      recordPipesAsInjectables && $Pipe.firstAnnotationOfExact(element) != null;
}

class ReflectableOutput {
  /// What `.template.dart` files need to be imported and linked to this file.
  final List<String> urlsNeedingInitReflector;

  /// What `class` elements require registration in `initReflector`.
  final List<ReflectableClass> registerClasses;

  /// What factory functions require registration in `initReflector`.
  final List<DependencyInvocation<FunctionElement>> registerFunctions;

  @visibleForTesting
  const ReflectableOutput({
    this.urlsNeedingInitReflector: const [],
    this.registerClasses: const [],
    this.registerFunctions: const [],
  });

  static const _list = const ListEquality<Object>();

  @override
  bool operator ==(Object o) =>
      o is ReflectableOutput &&
      _list.equals(urlsNeedingInitReflector, o.urlsNeedingInitReflector) &&
      _list.equals(registerClasses, o.registerClasses) &&
      _list.equals(registerFunctions, o.registerFunctions);

  @override
  int get hashCode =>
      _list.hash(urlsNeedingInitReflector) ^
      _list.hash(registerClasses) ^
      _list.hash(registerFunctions);

  @override
  String toString() =>
      'ReflectableOutput ' +
      {
        'urlsNeedingInitReflector': urlsNeedingInitReflector,
        'registerClasses': registerClasses,
        'registerFunctions': registerFunctions,
      }.toString();
}

class ReflectableClass {
  /// Factory required to invoke the constructor of the class.
  final DependencyInvocation<ConstructorElement> factory;

  /// Name of the class.
  final String name;

  /// If non-null, this object should be registered as an annotation.
  final Revivable registerAnnotation;

  /// If `true`, this class has an `NgFactory` needing registration.
  final bool registerComponentFactory;

  @visibleForTesting
  const ReflectableClass({
    this.factory,
    @required this.name,
    this.registerAnnotation,
    this.registerComponentFactory: false,
  });

  @override
  bool operator ==(Object o) =>
      o is ReflectableClass &&
      factory == o.factory &&
      name == o.name &&
      registerAnnotation?.source == o.registerAnnotation?.source &&
      registerComponentFactory == o.registerComponentFactory;

  @override
  int get hashCode =>
      factory.hashCode ^
      name.hashCode ^
      (registerAnnotation?.source?.hashCode ?? 0) ^
      registerComponentFactory.hashCode;

  @override
  String toString() =>
      'ReflectableClass' +
      {
        'factory': factory,
        'name': name,
        'registerAnnotation': '${registerAnnotation?.source}',
        'registerComponentFactory': registerComponentFactory,
      }.toString();
}
