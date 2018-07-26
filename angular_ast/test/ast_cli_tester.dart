// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:angular_ast/angular_ast.dart';
import 'package:path/path.dart' as p;

RecoveringExceptionHandler exceptionHandler = RecoveringExceptionHandler();

List<StandaloneTemplateAst> parse(String template) => const NgParser().parse(
      template,
      sourceUrl: '/test/parser_test.dart#inline',
      exceptionHandler: exceptionHandler,
      desugar: false,
      parseExpressions: false,
    );

void main() {
  String input;
  if (exceptionHandler is RecoveringExceptionHandler) {
    exceptionHandler.exceptions.clear();
  }
  var fileDir = p.join('test', 'ast_cli_tester_source.html');
  var file = File(fileDir.toString());
  input = file.readAsStringSync();
  //input = stdin.readLineSync(encoding: UTF8);
  var ast = parse(input);
  print('----------------------------------------------');
  if (exceptionHandler is ThrowingExceptionHandler) {
    print('CORRECT!');
    print(ast);
  }
  if (exceptionHandler is RecoveringExceptionHandler) {
    var exceptionsList = exceptionHandler.exceptions;
    if (exceptionsList.isEmpty) {
      print('CORRECT!');
      print(ast);
    } else {
      var visitor = const HumanizingTemplateAstVisitor();
      var fixed = ast.map((t) => t.accept(visitor)).join('');
      print('ORGNL: $input');
      print('FIXED: $fixed');

      print('\n\nERRORS:');
      exceptionHandler.exceptions.forEach((e) {
        var context = input.substring(e.offset, e.offset + e.length);
        print('${e.errorCode.message} :: $context at ${e.offset}');
      });
    }
  }
}
