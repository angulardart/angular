import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/dart/core.dart';
import 'package:quiver/iterables.dart';

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

  List<StatementBuilder> get setupMethod {
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
      setUpMethod.addStatement(literal(true).asAssign(_visited));
    }

    reflectables.forEach((r) {
      setUpMethod.addStatement(r.asRegistration);
    });

    // Call the setup method for our dependencies.
    for (var importModel in depImports) {
      // TODO(alorenzen): Fix scoping (prefix).
      setUpMethod
          .addStatement(reference(SETUP_METHOD_NAME, importModel.uri).call([]));
    }

    topLevelStatements.add(setUpMethod);
    return topLevelStatements;
  }
}

const String _visited = '_visited';
