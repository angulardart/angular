// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quiver/core.dart';
import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents an `<ng-content>` element AST.
///
/// Embedded content is _like_ an `ElementAst`, but only contains children.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class EmbeddedContentAst implements StandaloneTemplateAst {
  /// Create a synthetic embedded content AST.
  factory EmbeddedContentAst([String selector, String ngProjectAs]) =
      _SyntheticEmbeddedContentAst;

  /// Create a synthetic [EmbeddedContentAst] that originated from [origin].
  factory EmbeddedContentAst.from(
    TemplateAst origin, [
    String selector,
    String ngProjectAs,
  ]) = _SyntheticEmbeddedContentAst.from;

  /// Create a new [EmbeddedContentAst] parsed from tokens in [sourceFile].
  factory EmbeddedContentAst.parsed(
    SourceFile sourceFile,
    NgToken startElementToken,
    NgToken elementIdentifierToken,
    NgToken endElementToken,
    CloseElementAst closeComplement, [
    NgToken selectToken,
    NgToken selectEqualSign,
    NgAttributeValueToken selectorValueToken,
    NgToken ngProjectAsToken,
    NgToken ngProjectAsEqualSign,
    NgAttributeValueToken ngProjectAsValueToken,
  ]) = ParsedEmbeddedContentAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitEmbeddedContent(this, context);
  }

  /// A CSS selector denoting what elements should be embedded.
  ///
  /// May be null if and only if decorator 'select' is defined,
  /// but no value is assigned.
  /// If 'select' is not defined at all (simple <ng-content>), then the value
  /// will default to '*'.
  String get selector;

  /// A CSS selector denoting what this embedded content should be projected as.
  ///
  /// May be null if decorator `ngProjectAs` is not defined.
  String get ngProjectAs;

  /// </ng-content> that is paired to this <ng-content>.
  CloseElementAst get closeComplement;
  set closeComplement(CloseElementAst closeComplement);

  @override
  bool operator ==(Object o) {
    return o is EmbeddedContentAst &&
        o.selector == selector &&
        o.ngProjectAs == ngProjectAs &&
        o.closeComplement == closeComplement;
  }

  @override
  int get hashCode =>
      hash3(selector.hashCode, ngProjectAs.hashCode, closeComplement);

  @override
  String toString() => '$EmbeddedContentAst {$selector, $ngProjectAs}';
}

class ParsedEmbeddedContentAst extends TemplateAst with EmbeddedContentAst {
  // Token for 'ng-content'.
  final NgToken identifierToken;

  // Token for 'select'. May be null.
  final NgToken selectToken;

  // Token for '='. May be null.
  final NgToken selectEqualSign;

  // Token for value paired to 'select'. May be null.
  final NgAttributeValueToken selectorValueToken;

  // Token for 'select'. May be null.
  final NgToken ngProjectAsToken;

  // Token for '='. May be null.
  final NgToken ngProjectAsEqualSign;

  // Token for value paired to 'select'. May be null.
  final NgAttributeValueToken ngProjectAsValueToken;

  @override
  CloseElementAst closeComplement;

  ParsedEmbeddedContentAst(
    SourceFile sourceFile,
    NgToken startElementToken,
    this.identifierToken,
    NgToken endElementToken,
    this.closeComplement, [
    this.selectToken,
    this.selectEqualSign,
    this.selectorValueToken,
    this.ngProjectAsToken,
    this.ngProjectAsEqualSign,
    this.ngProjectAsValueToken,
  ])
      : super.parsed(
          startElementToken,
          endElementToken,
          sourceFile,
        );

  @override
  String get selector {
    // '<ng-content select>' ; no value was defined.
    // Return null to handle later.
    if (selectToken != null && selectEqualSign == null) {
      return null;
    }
    return selectorValueToken?.innerValue?.lexeme ?? '*';
  }

  @override
  String get ngProjectAs {
    // '<ng-content ngProjectAs>' ; no value was defined.
    // Return null to handle later.
    if (ngProjectAsToken != null && ngProjectAsEqualSign == null) {
      return null;
    }
    return ngProjectAsValueToken?.innerValue?.lexeme;
  }
}

class _SyntheticEmbeddedContentAst extends SyntheticTemplateAst
    with EmbeddedContentAst {
  @override
  final String selector;

  @override
  final String ngProjectAs;

  @override
  CloseElementAst closeComplement;

  _SyntheticEmbeddedContentAst([this.selector = '*', this.ngProjectAs]) {
    this.closeComplement = new CloseElementAst('ng-content');
  }

  _SyntheticEmbeddedContentAst.from(
    TemplateAst origin, [
    this.selector = '*',
    this.ngProjectAs,
  ])
      : super.from(origin) {
    this.closeComplement = new CloseElementAst('ng-content');
  }
}
