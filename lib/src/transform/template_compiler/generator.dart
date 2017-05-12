import 'dart:async';

import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/compiler/source_module.dart';
import 'package:angular2/src/transform/common/asset_reader.dart';
import 'package:angular2/src/transform/common/logging.dart';
import 'package:angular2/src/transform/common/model/annotation_model.pb.dart';
import 'package:angular2/src/transform/common/model/ng_deps_model.pb.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:angular2/src/transform/common/ng_compiler.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:angular2/src/transform/common/zone.dart' as zone;
import 'package:barback/barback.dart';

import 'compile_data_creator.dart';

/// Generates `.template.dart` files to initialize the Angular2 system.
///
/// - Processes the `.ng_meta.json` file represented by `assetId` using
///   `createCompileData`.
/// - Passes the resulting `NormalizedComponentWithViewDirectives` instance(s)
///   to the `TemplateCompiler` to generate compiled template(s) as a
///   `SourceModule`.
/// - Uses the resulting `NgDeps` object to generate code which initializes the
///   Angular2 reflective system.
Future<Outputs> processTemplates(
    AssetReader reader, AssetId assetId, TransformerOptions options) async {
  var compileDefs = await createCompileData(
      reader, assetId, options.platformDirectives, options.platformPipes);
  if (compileDefs == null) return null;
  var templateCompiler = zone.templateCompiler;
  if (templateCompiler == null) {
    var config = new CompilerConfig(
        genDebugInfo: options.codegenMode == CODEGEN_DEBUG_MODE,
        logBindingUpdate: options.reflectPropertiesAsAttributes,
        useLegacyStyleEncapsulation: options.useLegacyStyleEncapsulation,
        profileType: codegenModeToProfileType(options.codegenMode));
    templateCompiler = createTemplateCompiler(reader, config);
  }

  final compileComponentsData =
      compileDefs.viewDefinitions.values.toList(growable: false);
  if (compileComponentsData.isEmpty) {
    return new Outputs._(compileDefs.ngMeta.ngDeps, null);
  }

  final compiledTemplates = logElapsedSync(() {
    return templateCompiler.compile(compileComponentsData);
  }, operationName: 'compile', assetId: assetId);

  if (compiledTemplates != null) {
    // We successfully compiled templates!
    // For each compiled template, add the compiled template class as an
    // "Annotation" on the code to be registered with the reflector.
    for (var reflectable in compileDefs.viewDefinitions.keys) {
      // TODO(kegluneq): Avoid duplicating naming logic for generated classes.
      reflectable.annotations.add(new AnnotationModel()
        ..name = '${reflectable.name}NgFactory'
        ..isConstObject = true);
    }
  }

  return new Outputs._(compileDefs.ngMeta.ngDeps, compiledTemplates);
}

AssetId templatesAssetId(AssetId primaryId) =>
    new AssetId(primaryId.package, toTemplateExtension(primaryId.path));

class Outputs {
  final NgDepsModel ngDeps;
  final SourceModule templatesSource;

  Outputs._(this.ngDeps, this.templatesSource);
}
