import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';

const angular = 'package:angular/angular.dart';

/// Resolves [source] code as-if it is implemented with an AngularDart import.
///
/// Returns the resolved library as `package:test_lib/test_lib.dart`.
Future<LibraryElement> resolveLibrary(String source) => resolveSource('''
      library _test;
      import '$angular';\n\n$source''',
    (resolver) => resolver.findLibraryByName('_test'),
    inputId: new AssetId('test_lib', 'lib/test_lib.dart'));

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
