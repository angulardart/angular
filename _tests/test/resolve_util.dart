import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular/src/compiler/offline_compiler.dart';
import 'package:angular/src/source_gen/template_compiler/find_components.dart';
import 'package:angular/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';

Future<LibraryElement> resolve(String source) async {
  final testAssetId = AssetId('_tests', 'lib/resolve.dart');
  return await resolveSource(
      source, (resolver) => resolver.libraryFor(testAssetId),
      inputId: testAssetId);
}

Future<NormalizedComponentWithViewDirectives> resolveAndFindComponent(
  String source,
) async {
  final library = await resolve("import 'package:angular/angular.dart';"
      "$source");
  final artifacts = findComponentsAndDirectives(
      LibraryReader(library), ComponentVisitorExceptionHandler());
  return artifacts.components.first;
}
