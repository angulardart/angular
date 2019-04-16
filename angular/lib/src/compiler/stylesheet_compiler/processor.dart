import 'dart:async';

import 'package:build/build.dart';
import 'package:angular/src/compiler/module/ng_compiler_module.dart';
import 'package:angular/src/compiler/source_module.dart';
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular_compiler/cli.dart';

import 'zone.dart' as zone;

Future<Map<AssetId, String>> processStylesheet(
    BuildStep buildStep, AssetId stylesheetId, CompilerFlags flags) async {
  final stylesheetUrl = toAssetUri(stylesheetId);
  final templateCompiler =
      zone.templateCompiler ?? createOfflineCompiler(buildStep, flags);
  final cssText = await buildStep.readAsString(stylesheetId);
  final sourceModules =
      templateCompiler.compileStylesheet(stylesheetUrl, cssText);
  return _mapSourceByAssetId(sourceModules);
}

Map<AssetId, String> _mapSourceByAssetId(List<SourceModule> modules) {
  final sourceByAssetId = <AssetId, String>{};
  for (final module in modules) {
    final assetId = AssetId.resolve(module.moduleUrl);
    sourceByAssetId[assetId] = module.source;
  }
  return sourceByAssetId;
}
