// @dart=2.9

import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/find_components.dart';

// Use custom package config for angular sources if specified
final _packageConfigFuture = Platform
            .environment['ANGULAR_PACKAGE_CONFIG_PATH'] !=
        null
    ? loadPackageConfigUri(
        Uri.base.resolve(Platform.environment['ANGULAR_PACKAGE_CONFIG_PATH']))
    : Isolate.packageConfig.then(loadPackageConfigUri);

Future<LibraryElement> resolve(String source,
    [PackageConfig packageConfig]) async {
  final testAssetId = AssetId('_tests', 'lib/resolve.dart');
  return await withEnabledExperiments(
    () => resolveSource(
      source,
      (resolver) => resolver.libraryFor(testAssetId),
      inputId: testAssetId,
      packageConfig: packageConfig,
    ),
    ['non-nullable'],
  );
}

Future<NormalizedComponentWithViewDirectives> resolveAndFindComponent(
  String source,
) async {
  final library = await resolve(
      "import 'package:angular/angular.dart';"
      '$source',
      await _packageConfigFuture);
  final artifacts = findComponentsAndDirectives(
      LibraryReader(library), ComponentVisitorExceptionHandler());
  return artifacts.components.first;
}
