import 'package:build/build.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/module/ng_compiler_module.dart';
import 'package:angular_compiler/v1/src/compiler/source_module.dart';
import 'package:angular_compiler/v1/src/source_gen/common/url_resolver.dart';

Future<Map<AssetId, String>> processStylesheet(
  BuildStep buildStep,
  AssetId stylesheetId,
  CompilerFlags flags,
) async {
  final stylesheetUrl = toAssetUri(stylesheetId);
  final templateCompiler = createViewCompiler(buildStep, flags);
  final cssText = await buildStep.readAsString(stylesheetId);
  final sourceModules = templateCompiler.compileStylesheet(
    stylesheetUrl,
    cssText,
  );
  return _mapSourceByAssetId(sourceModules);
}

Map<AssetId, String> _mapSourceByAssetId(List<DartSourceOutput> modules) {
  final sourceByAssetId = <AssetId, String>{};
  for (final module in modules) {
    final assetId = AssetId.resolve(Uri.parse(module.outputUrl));
    sourceByAssetId[assetId] = module.sourceCode;
  }
  return sourceByAssetId;
}
