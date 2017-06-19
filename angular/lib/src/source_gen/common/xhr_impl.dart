import 'dart:async';

import 'package:build/build.dart';
import 'package:angular/src/compiler/xhr.dart'
    show XHR;

import 'url_resolver.dart';

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
      log.warning('XhrImpl received unexpected url: $url');
    }
    final assetId = fromUri(url);
    if (!await _buildStep.canRead(assetId)) {
      throw new ArgumentError.value(
        url,
        'url',
        'No asset found at $url while running build on ${_buildStep.inputId}',
      );
    }
    return _buildStep.readAsString(assetId);
  }
}
