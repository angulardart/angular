// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

/// A light-weight representation of a browser URL.
///
/// This class primarily exists to avoid a direct dependency on [Uri].
class Url {
  static bool isHashStrategy = false;

  /// Parses a [url] string into an [Url] object.
  static Url parse(String url) {
    final uri = Uri.parse(url);
    return new Url(
      normalizePath(uri.path),
      fragment: uri.fragment,
      queryParameters: uri.queryParameters,
    );
  }

  /// Normalizes paths so they are standardized when handled around the router.
  static String normalizePath(String path, [bool hashStrategy = false]) {
    if (path == null) return null;
    hashStrategy = isHashStrategy || hashStrategy;

    if (!hashStrategy && !path.startsWith('/')) {
      path = '/' + path;
    }
    if (hashStrategy && path.startsWith('/')) {
      path = path.substring(1);
    }

    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    return path;
  }

  /// Normalizes hashes so they are standardized.
  static String normalizeHash(String hash) {
    if (hash.startsWith('#')) {
      return hash.substring(1);
    }

    return hash;
  }

  static String trimSlashes(String path) {
    if (path == null) return null;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);

    return path;
  }

  /// Optional; if non-empty this is the part of the URL after a `#` symbol.
  final String fragment;

  /// URL path.
  final String path;

  /// Query parameters.
  final Map<String, String> queryParameters;

  Url(String path, {String fragment: '', Map<String, String> queryParameters})
      : this.path = path ?? '',
        this.fragment = fragment ?? '',
        this.queryParameters = new Map.unmodifiable(queryParameters ?? {});

  @override
  bool operator ==(Object o) {
    if (o is Url) {
      return path == o.path &&
          fragment == o.fragment &&
          const MapEquality().equals(queryParameters, o.queryParameters);
    }
    return false;
  }

  @override
  int get hashCode =>
      hash3(path, fragment, const MapEquality().hash(queryParameters));

  /// Returns as a URL string that could be used for navigation/link sharing.
  String toUrl() {
    final buffer = new StringBuffer();
    buffer.write(path);
    if (queryParameters?.isNotEmpty == true) {
      buffer
        ..write('?')
        ..writeAll(queryParameters.keys.map((k) {
          final v = queryParameters[k];
          k = Uri.encodeComponent(k);
          return v != null ? '$k=${Uri.encodeComponent(v)}' : k;
        }), '&');
    }
    if (fragment?.isNotEmpty == true) {
      buffer..write('#')..write(fragment);
    }
    return buffer.toString();
  }

  @override
  String toString() => toUrl();
}
