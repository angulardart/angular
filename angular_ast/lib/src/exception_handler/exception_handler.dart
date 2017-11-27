// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library angular_ast.src.exceptions;

import 'package:analyzer/error/error.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

part 'angular_parser_exception.dart';
part 'exceptions.dart';

abstract class ExceptionHandler {
  void handle(AngularParserException e);
}

class ThrowingExceptionHandler implements ExceptionHandler {
  @override
  void handle(AngularParserException e) {
    throw e;
  }

  @literal
  const factory ThrowingExceptionHandler() = ThrowingExceptionHandler._;
  const ThrowingExceptionHandler._();
}

class RecoveringExceptionHandler implements ExceptionHandler {
  final exceptions = <AngularParserException>[];

  @override
  void handle(AngularParserException e) {
    if (e != null) {
      exceptions.add(e);
    }
  }
}
