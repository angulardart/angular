// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';

import 'ng_dart_ast.dart';

abstract class AngularDartAstVisitor<R> extends AstVisitor<R> {
  R visitPipeOptionalArgumentList(PipeOptionalArgumentList node);
  R visitPipeInvocation(PipeInvocationExpression node);
}

/// A visitor used to write a source representation of a visited AST node (and
/// all of it's children) to a writer. This handles AngularDartAst nodes.
class NgToSourceVisitor extends ToSourceVisitor2
    implements AngularDartAstVisitor<Object> {
  final StringSink _writer;

  factory NgToSourceVisitor() {
    final writer = new StringBuffer();
    return new NgToSourceVisitor._(writer);
  }

  NgToSourceVisitor._(this._writer) : super(_writer);

  @override
  Object visitPipeOptionalArgumentList(PipeOptionalArgumentList node) {
    _writer.write(node.toSource());
    return null;
  }

  @override
  Object visitPipeInvocation(PipeInvocationExpression node) {
    _writer.write(node.toSource());
    return null;
  }

  @override
  String toString() {
    return _writer.toString();
  }
}
