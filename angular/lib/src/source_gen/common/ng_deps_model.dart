import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/iterables.dart';
import 'package:angular/src/compiler/compiler_utils.dart';
import 'package:angular/src/transform/common/names.dart';

import 'namespace_model.dart';
import 'reflection_info_model.dart';

/// A model with all of the metadata necessary to generate the initialize of the
/// Dependency Injection system for Angular.
class NgDepsModel {
  final List<ReflectionInfoModel> reflectables;
  final List<ImportModel> depImports;
  final List<ImportModel> imports;
  final List<ExportModel> exports;

  NgDepsModel(
      {this.reflectables: const [],
      this.depImports: const [],
      this.imports: const [],
      this.exports: const []});

  List<ImportModel> get allImports => concat([imports, depImports]);

  StatementBuilder get localMetadataMap =>
      list(concat(reflectables.map((model) => model.localMetadataEntry)),
              type: lib$core.$dynamic, asConst: true)
          .asConst('_METADATA');

  List<StatementBuilder> createSetupMethod(Set<String> deferredImports) {
    final topLevelStatements = <StatementBuilder>[];

    var hasInitializationCode =
        reflectables.isNotEmpty || depImports.isNotEmpty;

    // Create global variable _visited to prevent initializing dependencies
    // multiple times.
    if (hasInitializationCode) {
      topLevelStatements.add(literal(false).asVar(_visited));
    }

    var setUpMethod = new MethodBuilder.returnVoid(SETUP_METHOD_NAME);

    // Write code to prevent reentry.
    if (hasInitializationCode) {
      setUpMethod.addStatement(ifThen(reference(_visited), [returnVoid]));
      setUpMethod.addStatement(literal(true).asAssign(reference(_visited)));
    }

    reflectables.forEach((r) {
      setUpMethod.addStatement(r.asRegistration);
    });

    // If there's a deferred import for the same URI, don't call the setup
    // method since we want to defer it.
    if (depImports.isNotEmpty) {
      depImports.removeWhere((importModel) {
        var assetUri = packageToAssetScheme(importModel.uri);
        return deferredImports.any((i) => i.contains(assetUri));
      });
    }

    // Call the setup method for our dependencies.
    for (var importModel in depImports) {
      setUpMethod
          .addStatement(reference(SETUP_METHOD_NAME, importModel.uri).call([]));
    }

    topLevelStatements.add(setUpMethod);
    return topLevelStatements;
  }
}

const String _visited = '_visited';
