// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library angular_ast.src.expression.ng_dart_ast;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

import '../exception_handler/exception_handler.dart';
import 'visitor.dart';

/// A list of arguments in the invocation of a pipe.
///
///   pipeArgument ::= ':' [Expression]
///
///   pipeArgumentList ::=
///       [PipeArgument] ([PipeArgument])*
abstract class PipeOptionalArgumentList extends AstNode {
  /// Initialize a newly created [PipeOptionalArgumentList]. The list of [arguments]
  /// must contain at least one `PipeArgument` and the rest are optional.
  factory PipeOptionalArgumentList(
          Token startingColon, List<Expression> optionalArguments) =
      PipeOptionalArgumentListImpl;

  /// Return the expressions producing the values of the arguments.
  /// The non-optional argument must always be the first argument while the
  /// remaining are considered optional.
  NodeList<Expression> get arguments;

  /// Return the starting colon.
  Token get startingColon;

  /// Set the parameter elements corresponding to each of the arguments in this
  /// list to the given list of [parameters]. The list of parameters must be
  /// the same length as the number of arguments, but can contain `null`
  /// entries if a given argument does not correspond to a formal parameter.
  set correspondingPropagatedParameters(List<ParameterElement> parameters);

  /// Set the parameter elements corresponding to each of the arguments in this
  /// list to the given list of [parameters]. The list of parameters must be the
  /// same length as the number of arguments.
  set correspondingStaticParameters(List<ParameterElement> parameters);
}

class PipeOptionalArgumentListImpl extends AstNodeImpl
    implements PipeOptionalArgumentList {
  @override
  Token startingColon;

  NodeList<Expression> _arguments;

  List<ParameterElement> _correspondingStaticParameters;
  List<ParameterElement> _correspondingPropagatedParameters;

  PipeOptionalArgumentListImpl(this.startingColon, List<Expression> arguments) {
    _arguments = new NodeListImpl<Expression>(this, arguments);
  }

  @override
  NodeList<Expression> get arguments => _arguments;

  @override
  Token get beginToken => startingColon;

  @override
  Iterable<SyntacticEntity> get childEntities => new ChildEntities()
    ..add(startingColon)
    ..addAll(_arguments);

  List<ParameterElement> get correspondingPropagatedParameters =>
      _correspondingPropagatedParameters;

  @override
  set correspondingPropagatedParameters(List<ParameterElement> parameters) {
    if (parameters != null && parameters.length != _arguments.length) {
      throw new ArgumentError(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingPropagatedParameters = parameters;
  }

  List<ParameterElement> get correspondingStaticParameters =>
      _correspondingStaticParameters;

  @override
  set correspondingStaticParameters(List<ParameterElement> parameters) {
    if (parameters != null && parameters.length != _arguments.length) {
      throw new ArgumentError(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  @override
  Token get endToken => _arguments.last.endToken;

  @override
  R accept<R>(AstVisitor<R> visitor) {
    if (visitor is AngularDartAstVisitor) {
      return (visitor as AngularDartAstVisitor)
          .visitPipeOptionalArgumentList(this);
    }
    throw new ArgumentError(NgParserWarningCode.WRONG_VISITOR.message);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }

  @override
  String toSource() => arguments.map((e) {
        final visitor = new NgToSourceVisitor();
        e.accept(visitor);
        return ':${visitor.toString()}';
      }).join();
}

/// A pipe invocation in a PipedExpression
///
///   pipeInvocation ::=
///       [SimpleIdentifier][PipeArgumentList]?
abstract class PipeInvocationExpression extends Expression {
  /// Initialize a newly created pipe invocation.
  factory PipeInvocationExpression(
          Token bar,
          SimpleIdentifier pipe,
          Expression requiredArgument,
          PipeOptionalArgumentList pipeOptionalArgumentList) =>
      new PipeInvocationExpressionImpl(
          bar, pipe, requiredArgument, pipeOptionalArgumentList);

  /// Set the required argument to the pipe to the given [requiredArgument].
  Expression get requiredArgument;

  /// Set the required static parameter to the pipe to the given
  /// [requiredStaticParameter].
  set requiredArgumentStaticParameter(ParameterElement requiredStaticParameter);

  /// Set the required propagated parameter to the pipe to the given
  /// [requiredPropagatedParameter].
  set requiredArgumentPropagatedParameter(
      ParameterElement requiredPropagatedParameter);

  /// Set the list of arguments to the pipe to the given
  /// [pipeOptionalArgumentList].
  /// This may be null if no optional arguments were used.
  PipeOptionalArgumentList get pipeOptionalArgumentList;

  /// Set the '|' token.
  Token get bar;

  /// Return the name of the pipe being invoked.
  SimpleIdentifier get pipe;

  /// Set the name of the pipe being invoked to the given [identifier].
  set pipe(SimpleIdentifier identifier);

  /// Return the best element available for the pipe being invoked.
  /// If resolution was able to find a better element based on type
  /// propagation, that element will be return. Otherwise, the element
  /// found using the result of static analysis will be returned. If
  /// resolution has not been performed, then `null` will be returned.
  ExecutableElement get bestElement;

  /// Return the element associated with the pipe being invoked based on
  /// propagated type information, or `null` if the AST structure has
  /// not been resolved or the pipe could not be resolved.
  ExecutableElement get propagatedElement;

  /// Set the element associated with the pipe being invoked based on
  /// propagated type information to the given [element].
  set propagatedElement(ExecutableElement element);

  /// Return the element associated with the pipe being invoked based on
  /// static type information, or `null` if the AST structure has not been
  /// resolved or the pipe could not be resolved.
  ExecutableElement get staticElement;

  /// Set the element associated with the pipe being invoked based on static
  /// type information to the given [element].
  set staticElement(ExecutableElement element);
}

class PipeInvocationExpressionImpl extends ExpressionImpl
    implements PipeInvocationExpression {
  @override
  Token bar;

  @override
  SimpleIdentifier pipe;

  @override
  Expression requiredArgument;

  @override
  ParameterElement requiredArgumentStaticParameter;

  @override
  ParameterElement requiredArgumentPropagatedParameter;

  @override
  ExecutableElement staticElement;

  @override
  ExecutableElement propagatedElement;

  @override
  PipeOptionalArgumentList pipeOptionalArgumentList;

  /**
   * Initialize a newly created function expression invocation.
   */
  /// Initialize a newly created pipe invocation.
  PipeInvocationExpressionImpl(this.bar, this.pipe, this.requiredArgument,
      this.pipeOptionalArgumentList);

  @override
  Token get beginToken => bar;

  @override
  ExecutableElement get bestElement {
    ExecutableElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => new ChildEntities()
    ..add(bar)
    ..add(pipe)
    ..add(requiredArgument)
    ..add(pipeOptionalArgumentList);

  @override
  Token get endToken => pipeOptionalArgumentList == null
      ? pipeOptionalArgumentList.endToken
      : pipe.endToken;

  @override
  int get precedence => 15;

  @override
  R accept<R>(AstVisitor<R> visitor) {
    if (visitor is AngularDartAstVisitor) {
      return (visitor as AngularDartAstVisitor).visitPipeInvocation(this);
    }
    throw new ArgumentError(NgParserWarningCode.WRONG_VISITOR.message);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pipe.accept(visitor);
    requiredArgument.accept(visitor);
    pipeOptionalArgumentList?.accept(visitor);
  }

  @override
  ParameterElement propagatedParameterElement;

  @override
  ParameterElement get staticParameterElement;

  @override
  Expression get unParenthesized => this;

  @override
  String toSource() {
    final args = pipeOptionalArgumentList == null
        ? ''
        : pipeOptionalArgumentList.toSource();
    return '${requiredArgument.toSource()} ${bar.toString()} ${pipe
        .toSource()}$args';
  }
}
