import 'dart:async';

import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:barback/barback.dart';
import 'package:build/build.dart' as build;
import 'package:angular/src/compiler/source_module.dart';
import 'package:angular/src/source_gen/common/url_resolver.dart';
import 'package:angular/src/transform/common/logging.dart';
import 'package:angular/src/transform/common/names.dart';
import 'package:angular/src/transform/common/ng_compiler.dart';
import 'package:angular/src/transform/common/zone.dart' as zone;
import 'package:angular_compiler/angular_compiler.dart';

/// Converts a Barback asset ID to an asset URL.
String _assetIdToUrl(AssetId assetId) {
  final buildAssetId = new build.AssetId(assetId.package, assetId.path);
  return toAssetUri(buildAssetId);
}

/// Converts an asset URL to a Barback asset ID.
AssetId _urlToAssetId(String url) {
  final buildAssetId = new build.AssetId.resolve(url);
  return new AssetId(buildAssetId.package, buildAssetId.path);
}

AssetId shimmedStylesheetAssetId(AssetId cssAssetId) => new AssetId(
    cssAssetId.package, toShimmedStylesheetExtension(cssAssetId.path));

AssetId nonShimmedStylesheetAssetId(AssetId cssAssetId) => new AssetId(
    cssAssetId.package, toNonShimmedStylesheetExtension(cssAssetId.path));

Future<Iterable<Asset>> processStylesheet(
    NgAssetReader reader, AssetId stylesheetId, CompilerFlags flags) async {
  final stylesheetUrl = _assetIdToUrl(stylesheetId);
  var templateCompiler = zone.templateCompiler;
  if (templateCompiler == null) {
    templateCompiler = createTemplateCompiler(reader, flags);
  }
  final cssText = await reader.readText(stylesheetId.toString());
  return logElapsedAsync(() async {
    final sourceModules =
        templateCompiler.compileStylesheet(stylesheetUrl, cssText);

    return sourceModules.map((SourceModule module) => new Asset.fromString(
        _urlToAssetId(module.moduleUrl), writeSourceModule(module)));
  }, operationName: 'processStylesheet', assetId: stylesheetId);
}

/// Writes the full Dart code for the provided [SourceModule].
String writeSourceModule(SourceModule sourceModule, {String libraryName}) {
  if (sourceModule == null) return null;
  var buf = new StringBuffer();
  libraryName = _sanitizeLibName(
      libraryName != null ? libraryName : sourceModule.moduleUrl);
  buf..writeln('library $libraryName;')..writeln();

  buf..writeln()..writeln(sourceModule.source);

  return buf.toString();
}

final _unsafeCharsPattern = new RegExp(r'[^a-zA-Z0-9_\.]');
String _sanitizeLibName(String moduleUrl) {
  var sanitized =
      moduleUrl.replaceAll(_unsafeCharsPattern, '_').replaceAll('/', '.');
  for (var keyword in Keyword.values) {
    sanitized.replaceAll(keyword.lexeme, '${keyword.lexeme}_');
  }
  return sanitized;
}
