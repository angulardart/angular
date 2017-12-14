// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../ast.dart';
import '../../exception_handler/exception_handler.dart';
import 'ast.dart';
import 'lexer.dart';
import 'token.dart';

class NgMicroParser {
  @literal
  const factory NgMicroParser() = NgMicroParser._;

  const NgMicroParser._();

  NgMicroAst parse(
    String directive,
    String expression,
    int expressionOffset, {
    @required String sourceUrl,
    TemplateAst origin,
  }) {
    var paddedExpression = ' ' * expressionOffset + expression;
    var tokens = const NgMicroLexer().tokenize(paddedExpression).iterator;
    return new _RecursiveMicroAstParser(
      directive,
      expressionOffset,
      expression.length,
      tokens,
      origin,
    )
        .parse();
  }
}

class _RecursiveMicroAstParser {
  final String _directive;
  final int _expressionOffset;
  final int _expressionLength;
//  final String _sourceUrl;
  final Iterator<NgMicroToken> _tokens;

  final letBindings = <LetBindingAst>[];
  final properties = <PropertyAst>[];

  final TemplateAst _origin;

  _RecursiveMicroAstParser(
    this._directive,
    this._expressionOffset,
    this._expressionLength,
    this._tokens,
    this._origin,
  );

  NgMicroAst parse() {
    while (_tokens.moveNext()) {
      var token = _tokens.current;
      if (token.type == NgMicroTokenType.letKeyword) {
        _parseLet();
      } else if (token.type == NgMicroTokenType.bindIdentifier) {
        _parseBind();
      } else if (token.type != NgMicroTokenType.endExpression) {
        throw _unexpected(token);
      }
    }
    return new NgMicroAst(letBindings: letBindings, properties: properties);
  }

  void _parseBind() {
    var name = _tokens.current.lexeme;
    if (!_tokens.moveNext() ||
        _tokens.current.type != NgMicroTokenType.bindExpressionBefore ||
        !_tokens.moveNext() ||
        _tokens.current.type != NgMicroTokenType.bindExpression) {
      throw _unexpected();
    }
    var value = _tokens.current.lexeme;
    properties.add(new PropertyAst.from(
      _origin,
      '$_directive${name[0].toUpperCase()}${name.substring(1)}',
      value,
    ));
  }

  void _parseLet() {
    String identifier;
    if (!_tokens.moveNext() ||
        _tokens.current.type != NgMicroTokenType.letKeywordAfter ||
        !_tokens.moveNext() ||
        _tokens.current.type != NgMicroTokenType.letIdentifier) {
      throw _unexpected();
    }
    identifier = _tokens.current.lexeme;
    if (!_tokens.moveNext() ||
        _tokens.current.type == NgMicroTokenType.endExpression ||
        !_tokens.moveNext() ||
        _tokens.current.type == NgMicroTokenType.endExpression) {
      letBindings.add(new LetBindingAst.from(_origin, identifier));
      return;
    }
    if (_tokens.current.type == NgMicroTokenType.letAssignment) {
      letBindings.add(
          new LetBindingAst.from(_origin, identifier, _tokens.current.lexeme));
    } else {
      letBindings.add(new LetBindingAst.from(_origin, identifier));
      if (_tokens.current.type != NgMicroTokenType.bindIdentifier) {
        throw _unexpected();
      }
      var property = _tokens.current.lexeme;
      if (!_tokens.moveNext() ||
          _tokens.current.type != NgMicroTokenType.bindExpressionBefore ||
          !_tokens.moveNext() ||
          _tokens.current.type != NgMicroTokenType.bindExpression) {
        throw _unexpected();
      }
      var expression = _tokens.current.lexeme;
      properties.add(new PropertyAst.from(
        _origin,
        '$_directive${property[0].toUpperCase()}${property.substring(1)}',
        expression,
      ));
    }
  }

  AngularParserException _unexpected([NgMicroToken token]) {
    token ??= _tokens.current;
    return new AngularParserException(
      NgParserWarningCode.INVALID_MICRO_EXPRESSION,
      _expressionOffset,
      _expressionLength,
    );
  }
}
