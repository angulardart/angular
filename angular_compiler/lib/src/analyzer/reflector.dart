import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/cli.dart';
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
  static const _defaultOutputExtension = '.template.dart';

  /// Used to read dependencies from dart objects.
  final DependencyReader dependencyReader;

  /// Returns whether [uri] is a file part of the same build process.
  ///
  /// Used to determine whether [uri] (i.e. `foo.dart`) _will_ generate a future
  /// output (i.e. `foo.template.dart`). It should be assumed the [uri]
  /// parameter, if a relative URI, is relative to the library being analyzed.
  final FutureOr<bool> Function(String) hasInput;

  /// Returns whether [uri] represents a summarized/analyzed dart library.
  ///
  /// It should be assumed the [uri] parameter, if a relative URI, is relative
  /// to the library being analyzed.
  final Future<bool> Function(String) isLibrary;

  /// File extension used when compiling AngularDart files.
  ///
  /// By default this is `.template.dart`.
  final String outputExtension;

  /// Whether to record `@RouteConfig`s for `@Component`-annotated classes.
  ///
  /// This is only required in order to support the legacy router, which looks
  /// up metadata information at runtime in order to configure itself.
  final bool recordRouterAnnotationsForComponents;

  /// Whether to record `ComponentFactory` for `@Component`-annotated classes.
  ///
  /// This is used to support `SlowComponentLoader`.
  final bool recordComponentFactories;

  /// Whether to record factory functions for `@Injectable`-annotated elements.
  ///
  /// This is used to support `ReflectiveInjector`.
  final bool recordInjectableFactories;

  const ReflectableReader({
    this.dependencyReader = const DependencyReader(),
    @required this.hasInput,
    @required this.isLibrary,
    this.outputExtension = _defaultOutputExtension,
    this.recordRouterAnnotationsForComponents = false,
    this.recordComponentFactories = true,
    this.recordInjectableFactories = true,
  });

  /// Always emits an empty [ReflectableOutput.urlsNeedingInitReflector].
  ///
  /// Useful for tests that do not want to try emulating a complete build.
  @visibleForTesting
  const ReflectableReader.noLinking({
    this.dependencyReader = const DependencyReader(),
    this.outputExtension = _defaultOutputExtension,
    this.recordRouterAnnotationsForComponents = true,
    this.recordComponentFactories = true,
    this.recordInjectableFactories = true,
  })  : hasInput = _nullHasInput,
        isLibrary = _nullIsLibrary;

  static FutureOr<bool> _nullHasInput(_) => false;
  static Future<bool> _nullIsLibrary(_) async => false;

  static Iterable<CompilationUnitElement> _allUnits(LibraryElement lib) sync* {
    yield lib.definingCompilationUnit;
    yield* lib.parts;
  }

  /// Returns information needed to write `.template.dart` files.
  Future<ReflectableOutput> resolve(LibraryElement library) async {
    final registerClasses = <ReflectableClass>[];
    final registerFunctions = <DependencyInvocation<FunctionElement>>[];
    for (final unit in _allUnits(library)) {
      for (final type in unit.types) {
        final reflectable = _resolveClass(type);
        if (reflectable != null) {
          registerClasses.add(reflectable);
        }
      }
      if (recordInjectableFactories) {
        registerFunctions.addAll(unit.functions
            .where((e) => $Injectable.firstAnnotationOfExact(e) != null)
            .map(dependencyReader.parseDependencies));
      }
    }
    List<String> urlsNeedingInitReflector = const [];

    // Only link to other ".initReflector" calls if either flag is enabled.
    if (recordInjectableFactories || recordComponentFactories) {
      urlsNeedingInitReflector = await _resolveNeedsReflector(library);
    }

    return ReflectableOutput(
      urlsNeedingInitReflector: urlsNeedingInitReflector,
      registerClasses: registerClasses,
      registerFunctions: registerFunctions,
    );
  }

  ReflectableClass _resolveClass(ClassElement element) {
    DependencyInvocation<ConstructorElement> factory;
    if (_shouldRecordFactory(element) && recordInjectableFactories) {
      if (element.isPrivate) {
        throw BuildError.throwForElement(
            element, 'Private classes can not be @Injectable');
      }
      factory = dependencyReader.parseDependencies(element);
    }
    final isComponent = $Component.firstAnnotationOfExact(element) != null;
    if (factory == null && !isComponent) {
      return null;
    }
    return ReflectableClass(
      element: element,
      factory: factory,
      name: element.name,
      registerAnnotation: recordRouterAnnotationsForComponents && isComponent
          ? _findRouteConfig(element)?.revive()
          : null,
      registerComponentFactory: isComponent && recordComponentFactories,
    );
  }

  // We don't use a TypeChecker because this is in another library, and would
  // complicate things. Since this is only a single annotation that is rarely
  // used (and will be removed), it's not a big deal.
  ConstantReader _findRouteConfig(ClassElement element) {
    for (final annotation in element.metadata) {
      final object = annotation.computeConstantValue();
      if (object?.type?.name == 'RouteConfig') {
        return ConstantReader(object);
      }
    }
    return null;
  }

  String _withOutputExtension(String uri) {
    final extensionAt = uri.lastIndexOf('.');
    return uri.substring(0, extensionAt) + outputExtension;
  }

  Future<List<String>> _resolveNeedsReflector(LibraryElement library) async {
    final directives = <UriReferencedElement>[]
      ..addAll(library.imports)
      ..addAll(library.exports);
    final results = <String>[];
    await Future.wait(directives.map((d) async {
      if (await _needsInitReflector(d, library.source.uri.toString())) {
        var uri = d.uri ?? '';
        // Always link to the .template.dart file equivalent of a file.
        if (!uri.endsWith(outputExtension)) {
          uri = _withOutputExtension(uri);
        }
        results.add(uri);
      }
    }));
    return results..sort();
  }

  // Determines whether initReflector needs to link to [directive].
  Future<bool> _needsInitReflector(
    UriReferencedElement directive,
    String sourceUri,
  ) async {
    if (directive is ImportElement && directive.isDeferred) {
      // Do not link to deferred code.
      return false;
    }
    final uri = directive.uri ?? '';
    if (uri.endsWith(outputExtension)) {
      // Always link when manually importing/exporting .template.dart files.
      return true;
    }
    // Link if we are have or will have a .template.dart file.
    if (!uri.contains('.')) {
      // Don't link imports that are missing an extension. These are either
      // valid Dart SDK imports which don't need to be linked, or invalid
      // imports which will be reported by the analyzer.
      return false;
    }
    final outputUri = _withOutputExtension(uri);
    try {
      return await isLibrary(outputUri) || await hasInput(uri);
    } catch (e) {
      throw BuildError.forElement(
          directive, 'Could not parse URI. Additional information:\n$e\n');
    }
  }

  bool _shouldRecordFactory(ClassElement element) =>
      $Injectable.hasAnnotationOfExact(element);
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
    this.urlsNeedingInitReflector = const [],
    this.registerClasses = const [],
    this.registerFunctions = const [],
  });

  static const _list = ListEquality<Object>();

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
  /// Actual class element.
  final ClassElement element;

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
    @required this.element,
    this.factory,
    @required this.name,
    this.registerAnnotation,
    this.registerComponentFactory = false,
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
