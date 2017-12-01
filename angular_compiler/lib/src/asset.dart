import 'dart:async';

import 'package:barback/barback.dart' as barback;
import 'package:build/build.dart';
import 'package:source_gen/src/utils.dart';

/// Wraps an [AssetReader] to provide an ergonomic API for finding input files.
abstract class NgAssetReader {
  const NgAssetReader();

  const factory NgAssetReader.fromBarback(barback.Transform transform) =
      _BarbackAssetReader;

  const factory NgAssetReader.fromBuildStep(BuildStep buildStep) =
      _BuildStepAssetReader;

  /// Returns [url]'s contents as a string.
  Future<String> readText(String url);

  /// Returns [url] relative to a [baseUrl].
  String resolveUrl(String baseUrl, String url) {
    baseUrl = _normalize(baseUrl);
    url = _normalize(url);
    final asset = new AssetId.resolve(url, from: new AssetId.resolve(baseUrl));
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

class _BarbackAssetReader extends NgAssetReader {
  final barback.Transform _transform;

  const _BarbackAssetReader(this._transform);

  @override
  Future<String> readText(String url) async {
    final id = new barback.AssetId.parse(url);
    return _transform.readInputAsString(id);
  }
}

class _BuildStepAssetReader extends NgAssetReader {
  final BuildStep _buildStep;

  const _BuildStepAssetReader(this._buildStep);

  @override
  Future<String> readText(String url) async {
    url = _normalize(url);
    return _buildStep.readAsString(new AssetId.resolve(url));
  }
}
