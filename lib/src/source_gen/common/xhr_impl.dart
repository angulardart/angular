import 'dart:async';

import 'package:angular2/src/compiler/xhr.dart' show XHR;
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:build/build.dart';

/// SourceGen-specific implementation of XHR that is backed by a [BuildStep].
///
/// This implementation expects urls using the asset: scheme.
/// See [src/source_gen/common/url_resolver.dart] for a way to convert package:
/// and relative urls to asset: urls.
class XhrImpl implements XHR {
  final BuildStep _buildStep;

  XhrImpl(this._buildStep);

  Future<String> get(String url) async {
    if (!url.startsWith('asset:')) {
      _buildStep.logger.warning('XhrImpl received unexpected url: $url');
    }
    final assetId = fromUri(url);
    if (!await _buildStep.hasInput(assetId)) {
      throw new ArgumentError.value('Could not read asset at uri $url', 'url');
    }
    return _buildStep.readAsString(assetId);
  }
}
