import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/src/utils.dart';

/// Wraps an [AssetReader] to provide an ergonomic API for finding input files.
abstract class NgAssetReader {
  const NgAssetReader();

  const factory NgAssetReader.fromBuildStep(BuildStep buildStep) =
      _BuildStepAssetReader;

  /// Returns whether [url] is readable.
  Future<bool> canRead(String url);

  /// Returns [url]'s contents as a string.
  Future<String> readText(String url);

  /// Returns [url] relative to a [baseUrl].
  String resolveUrl(String baseUrl, String url) {
    baseUrl = _normalize(baseUrl);
    url = _normalize(url);
    final asset = AssetId.resolve(url, from: AssetId.resolve(baseUrl));
    return asset.uri.toString();
  }

  String _normalize(String url) => assetToPackageUrl(Uri.parse(url))
      .toString()
      // Normalization for Windows URLs.
      // See https://github.com/dart-lang/angular/issues/723.
      .replaceAll('..%5C', '')
      // Other normalization.
      .replaceAll('%7C', r'/');
}

class _BuildStepAssetReader extends NgAssetReader {
  final BuildStep _buildStep;

  const _BuildStepAssetReader(this._buildStep);

  @override
  Future<bool> canRead(String url) {
    final asset = AssetId.resolve(_normalize(url));
    return _buildStep.canRead(asset);
  }

  @override
  Future<String> readText(String url) async {
    final asset = AssetId.resolve(_normalize(url));
    return _buildStep.readAsString(asset);
  }
}
