// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import 'exception_handler/exception_handler.dart';
import 'scanner.dart';
import 'token/tokens.dart';

/// Separates an Angular template into a series of lexical tokens.
///
/// ## Example use
/// ```dart
/// const NgLexer().tokenize('<div>Hello World!</div>');
/// ```
class NgLexer {
  @literal
  const factory NgLexer() = NgLexer._;

  // Prevent inheritance.
  const NgLexer._();

  /// Return a series of tokens by incrementally scanning [template].
  Iterable<NgToken> tokenize(
      String template, ExceptionHandler exceptionHandler) sync* {
    var scanner = NgScanner(template, exceptionHandler);
    var token = scanner.scan();
    while (token != null) {
      yield token;
      token = scanner.scan();
    }
  }
}
