import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';

const angular = 'package:angular/angular.dart';

/// A custom package resolver for Angular sources.
///
/// This is needed to resolve sources that import Angular.
final packageConfigFuture = Platform
            .environment['ANGULAR_PACKAGE_CONFIG_PATH'] !=
        null
    ? loadPackageConfigUri(
        Uri.base.resolve(Platform.environment['ANGULAR_PACKAGE_CONFIG_PATH']!))
    : Isolate.packageConfig.then((uri) => loadPackageConfigUri(uri!));

/// Resolves [source] code as-if it is implemented with an AngularDart import.
///
/// Returns the resolved library as `package:test_lib/test_lib.dart`.
Future<LibraryElement> resolveLibrary(String source) async {
  final packageConfig = await packageConfigFuture;
  return withEnabledExperiments(
    () => resolveSource(
      '''
      library _test;
      import '$angular';\n\n$source
    ''',
      (resolver) async => (await resolver.findLibraryByName('_test'))!,
      inputId: AssetId('test_lib', 'lib/test_lib.dart'),
      packageConfig: packageConfig,
    ),
    ['non-nullable'],
  );
}

/// Resolves [source] code as-if it is implemented with an AngularDart import.
///
/// Returns first `class` in the file, or by [name] if given.
Future<ClassElement?> resolveClass(
  String source, [
  String? name,
]) async {
  final library = await resolveLibrary(source);
  return name != null
      ? library.getType(name)
      : library.definingCompilationUnit.types.first;
}
