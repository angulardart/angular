import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

/// Finds the url of the library that declares the element.
///
/// Note that this needs to check librarySource instead of just source to handle
/// part files correctly.
String moduleUrl(Element element) {
  // TODO(mfairhurst) delete this check. This is just to preserve goldens when
  // https://dart-review.googlesource.com/c/sdk/+/62730 is rolled out. It has
  // no user-facing effects.
  if (element.kind == ElementKind.DYNAMIC) {
    return null;
  }
  // Type parameters aren't imported, thus don't required a library URL.
  if (element.kind == ElementKind.TYPE_PARAMETER) {
    return null;
  }
  var source = element.librarySource ?? element.source;
  var uri = source?.uri?.toString();
  if (uri == null) return null;
  if (Uri.parse(uri).scheme == 'dart') return uri;
  return toAssetUri(_fromUri(uri));
}

String toAssetUri(AssetId assetId) {
  if (assetId == null) throw ArgumentError.notNull('assetId');
  return 'asset:${assetId.package}/${assetId.path}';
}

AssetId _fromUri(String assetUri) {
  if (assetUri == null) throw ArgumentError.notNull('assetUri');
  if (assetUri.isEmpty) throw ArgumentError.value('(empty string)', 'assetUri');
  var uri = _toAssetScheme(Uri.parse(assetUri));
  return AssetId(uri.pathSegments.first, uri.pathSegments.skip(1).join('/'));
}

/// Returns the base file name for [AssetId].
String fileName(AssetId id) {
  var uri = _toAssetScheme(Uri.parse(toAssetUri(id)));
  return uri.pathSegments.last;
}

/// Converts `absoluteUri` to use the 'asset' scheme used in the Angular 2
/// template compiler.
///
/// The `scheme` of `absoluteUri` is expected to be either 'package' or
/// 'asset'.
Uri _toAssetScheme(Uri absoluteUri) {
  if (absoluteUri == null) throw ArgumentError.notNull('absoluteUri');

  if (!absoluteUri.isAbsolute) {
    throw ArgumentError.value(absoluteUri.toString(), 'absoluteUri',
        'Value passed must be an absolute uri');
  }
  if (absoluteUri.scheme == 'asset') {
    if (absoluteUri.pathSegments.length < 3) {
      throw FormatException(
          'An asset: URI must have at least 3 path '
          'segments, for example '
          'asset:<package-name>/<first-level-dir>/<path-to-dart-file>.',
          absoluteUri.toString());
    }
    return absoluteUri;
  }
  if (absoluteUri.scheme != 'package') {
    // Pass through URIs with non-package scheme
    return absoluteUri;
  }

  if (absoluteUri.pathSegments.length < 2) {
    throw FormatException(
        'A package: URI must have at least 2 path '
        'segments, for example '
        'package:<package-name>/<path-to-dart-file>',
        absoluteUri.toString());
  }

  var pathSegments = absoluteUri.pathSegments.toList()..insert(1, 'lib');
  return Uri(scheme: 'asset', pathSegments: pathSegments);
}

/// Returns `uri` with its extension updated to [_templateExtension].
String toTemplateExtension(String uri) =>
    _toExtension(uri, _allExtensions, _templateExtension);

/// Returns `uri` with its extension updated to `toExtension` if its
/// extension is currently in `fromExtension`.
String _toExtension(
    String uri, Iterable<String> fromExtensions, String toExtension) {
  if (uri == null) return null;
  if (uri.endsWith(toExtension)) return uri;
  for (var extension in fromExtensions) {
    if (uri.endsWith(extension)) {
      return '${uri.substring(0, uri.length - extension.length)}'
          '$toExtension';
    }
  }
  throw ArgumentError.value(
      uri,
      'uri',
      'Provided value ends with an unexpected extension. '
          'Expected extension(s): [${fromExtensions.join(', ')}].');
}

const _templateExtension = '.template.dart';

/// Note that due to the implementation of `_toExtension`, ordering is
/// important. For example, putting '.dart' first in this list will cause
/// incorrect behavior because it will (incompletely) match '.template.dart'
/// files.
const _allExtensions = [_templateExtension, '.ng_placeholder', '.dart'];
