// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'scanner.dart';
import 'token.dart';

/// Separates an Angular micro-expression into a series of lexical tokens.
class NgMicroLexer {
  @literal
  const factory NgMicroLexer() = NgMicroLexer._;

  // Prevent inheritance.
  const NgMicroLexer._();

  /// Return a series of tokens by incrementally scanning [template].
  Iterable<NgMicroToken> tokenize(String template) sync* {
    var scanner = new NgMicroScanner(template);
    var token = scanner.scan();
    while (token != null) {
      yield token;
      token = scanner.scan();
    }
  }
}
