import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
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
            Uri.base.resolve(Platform.environment['ANGULAR_PACKAGE_CONFIG_PATH']))
    : Isolate.packageConfig.then(loadPackageConfigUri);

/// Resolves [source] code as-if it is implemented with an AngularDart import.
///
/// Returns the resolved library as `package:test_lib/test_lib.dart`.
Future<LibraryElement> resolveLibrary(String source) async => resolveSource('''
      library _test;
      import '$angular';\n\n$source''',
    (resolver) => resolver.findLibraryByName('_test'),
    inputId: AssetId('test_lib', 'lib/test_lib.dart'),
    packageConfig: await packageConfigFuture);

/// Resolves [source] code as-if it is implemented with an AngularDart import.
///
/// Returns first `class` in the file, or by [name] if given.
Future<ClassElement> resolveClass(
  String source, [
  String name,
]) async {
  final library = await resolveLibrary(source);
  return name != null
      ? library.getType(name)
      : library.definingCompilationUnit.types.first;
}

/// Resolve [source] code as-if it is implemented with an AngularDart import.
///
/// Returns first top-level constant field in the file, or by [name] if given.
Future<TopLevelVariableElement> resolveField(
  String source, [
  String name,
]) async {
  final library = await resolveLibrary(source);
  return name == null
      ? library.definingCompilationUnit.topLevelVariables.first
      : library.definingCompilationUnit.topLevelVariables
          .firstWhere((e) => e.name == name);
}
