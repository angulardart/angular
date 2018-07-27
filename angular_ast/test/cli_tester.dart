// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:angular_ast/angular_ast.dart';

RecoveringExceptionHandler exceptionHandler = RecoveringExceptionHandler();
Iterable<NgToken> tokenize(String html) {
  exceptionHandler.exceptions.clear();
  return const NgLexer().tokenize(html, exceptionHandler);
}

String untokenize(Iterable<NgToken> tokens) => tokens
    .fold(StringBuffer(), (buffer, token) => buffer..write(token.lexeme))
    .toString();

void main() {
  String input;
  while (true) {
    input = stdin.readLineSync(encoding: utf8);
    if (input == 'QUIT') {
      break;
    }
    try {
      var tokens = tokenize(input);
      var fixed = untokenize(tokens);
      if (exceptionHandler.exceptions.isEmpty) {
        print('CORRECT(UNCHANGED): $input');
      } else {
        print('ORGNL: $input');
        print('FIXED: $fixed');
        print('ERRORS:');
        exceptionHandler.exceptions.forEach((e) {
          var context = input.substring(e.offset, e.offset + e.length);
          print('${e.errorCode.message} :: $context at ${e.offset}');
        });
      }
    } catch (e) {
      print(e);
    }
  }
}
