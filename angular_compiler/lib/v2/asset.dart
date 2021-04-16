import 'package:build/build.dart';

extension NormalizedAssetId on AssetId {
  /// Returns `this` as an on-dik path (e.g. in a Bazel workspace).
  ///
  /// For example:
  /// ```
  /// // foo/bar/lib/baz.dart
  /// AssetId('foo.bar', 'lib/baz.dart').toRelativeUrl()
  /// ```
  String toRelativeUrl() {
    var directory = package.replaceAll('.', '/');
    // In Bazel, a directory that has no "." characters is assumed to be
    // relative to //third_party, not //. So for example:
    //
    // AssetId('foo', 'lib/bar.dart').toRelativeUrl()
    //
    // ... should resolve to "third_party/dart/foo/lib/bar.dart".
    if (directory == package) {
      directory = 'third_party/dart/$directory';
    }
    return '$directory/$path';
  }
}
