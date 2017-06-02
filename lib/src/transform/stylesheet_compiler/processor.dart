import 'dart:async';

import 'package:angular2/src/compiler/config.dart';
import 'package:angular2/src/transform/common/asset_reader.dart';
import 'package:angular2/src/compiler/source_module.dart';
import 'package:angular2/src/transform/common/logging.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:angular2/src/transform/common/options.dart';
import 'package:angular2/src/transform/common/ng_compiler.dart';
import 'package:angular2/src/transform/common/url_resolver.dart';
import 'package:angular2/src/transform/common/zone.dart' as zone;
import 'package:analyzer/dart/ast/token.dart' show Keyword;
import 'package:barback/barback.dart';

AssetId shimmedStylesheetAssetId(AssetId cssAssetId) => new AssetId(
    cssAssetId.package, toShimmedStylesheetExtension(cssAssetId.path));

AssetId nonShimmedStylesheetAssetId(AssetId cssAssetId) => new AssetId(
    cssAssetId.package, toNonShimmedStylesheetExtension(cssAssetId.path));

Future<Iterable<Asset>> processStylesheet(AssetReader reader,
    AssetId stylesheetId, TransformerOptions options) async {
  final stylesheetUrl = toAssetUri(stylesheetId);
  var templateCompiler = zone.templateCompiler;
  if (templateCompiler == null) {
    var config = new CompilerConfig(
        useLegacyStyleEncapsulation: options.useLegacyStyleEncapsulation);
    templateCompiler = createTemplateCompiler(reader, config);
  }
  final cssText = await reader.readAsString(stylesheetId);
  return logElapsedAsync(() async {
    final sourceModules =
        templateCompiler.compileStylesheet(stylesheetUrl, cssText);

    return sourceModules.map((SourceModule module) => new Asset.fromString(
        fromUri(module.moduleUrl), writeSourceModule(module)));
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
    sanitized.replaceAll(keyword.syntax, '${keyword.syntax}_');
  }
  return sanitized;
}
