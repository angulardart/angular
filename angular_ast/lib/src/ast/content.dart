import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../hash.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents an `<ng-content>` element AST.
///
/// Embedded content is _like_ an `ElementAst`, but only contains children.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class EmbeddedContentAst implements StandaloneTemplateAst {
  /// Create a synthetic embedded content AST.
  factory EmbeddedContentAst([
    String selector,
    String ngProjectAs,
    ReferenceAst reference,
  ]) = _SyntheticEmbeddedContentAst;

  /// Create a synthetic [EmbeddedContentAst] that originated from [origin].
  factory EmbeddedContentAst.from(
    TemplateAst origin, [
    String selector,
    String ngProjectAs,
    ReferenceAst reference,
  ]) = _SyntheticEmbeddedContentAst.from;

  /// Create a new [EmbeddedContentAst] parsed from tokens in [sourceFile].
  factory EmbeddedContentAst.parsed(
    SourceFile sourceFile,
    NgToken startElementToken,
    NgToken elementIdentifierToken,
    NgToken endElementToken,
    CloseElementAst closeComplement, [
    AttributeAst? selectAttribute,
    AttributeAst? ngProjectAsAttribute,
    ReferenceAst? reference,
  ]) = ParsedEmbeddedContentAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C?> visitor, [C? context]) {
    return visitor.visitEmbeddedContent(this, context);
  }

  /// A CSS selector denoting what elements should be embedded.
  ///
  /// May be null if and only if decorator 'select' is defined,
  /// but no value is assigned.
  /// If 'select' is not defined at all (simple <ng-content>), then the value
  /// will default to '*'.
  String? get selector;

  /// A CSS selector denoting what this embedded content should be projected as.
  ///
  /// May be null if decorator `ngProjectAs` is not defined.
  String? get ngProjectAs;

  /// Reference assignment.
  ReferenceAst? get reference;

  /// </ng-content> that is paired to this <ng-content>.
  CloseElementAst get closeComplement;
  set closeComplement(CloseElementAst closeComplement);

  @override
  bool operator ==(Object o) {
    return o is EmbeddedContentAst &&
        o.selector == selector &&
        o.ngProjectAs == ngProjectAs &&
        o.reference == reference &&
        o.closeComplement == closeComplement;
  }

  @override
  int get hashCode => hash4(
      selector.hashCode, ngProjectAs.hashCode, reference, closeComplement);

  @override
  String toString() =>
      '$EmbeddedContentAst {$selector, $ngProjectAs, $reference}';
}

class ParsedEmbeddedContentAst extends TemplateAst with EmbeddedContentAst {
  // Token for 'ng-content'.
  final NgToken identifierToken;

  // Select assignment.
  final AttributeAst? selectAttribute;

  // NgProjectAs assignment.
  final AttributeAst? ngProjectAsAttribute;

  // Reference assignment.
  @override
  final ReferenceAst? reference;

  @override
  CloseElementAst closeComplement;

  ParsedEmbeddedContentAst(
    SourceFile sourceFile,
    NgToken startElementToken,
    this.identifierToken,
    NgToken endElementToken,
    this.closeComplement, [
    this.selectAttribute,
    this.ngProjectAsAttribute,
    this.reference,
  ]) : super.parsed(
          startElementToken,
          endElementToken,
          sourceFile,
        );

  @override
  String? get selector {
    // '<ng-content select>' ; no value was defined.
    // Return null to handle later.
    if (selectAttribute?.name != null && selectAttribute!.value == null) {
      return null;
    }
    return selectAttribute?.value ?? '*';
  }

  @override
  String? get ngProjectAs {
    return ngProjectAsAttribute?.value;
  }
}

class _SyntheticEmbeddedContentAst extends SyntheticTemplateAst
    with EmbeddedContentAst {
  @override
  final String selector;

  @override
  final String? ngProjectAs;

  @override
  final ReferenceAst? reference;

  @override
  late CloseElementAst closeComplement;

  _SyntheticEmbeddedContentAst(
      [this.selector = '*', this.ngProjectAs, this.reference]) {
    closeComplement = CloseElementAst('ng-content');
  }

  _SyntheticEmbeddedContentAst.from(
    TemplateAst origin, [
    this.selector = '*',
    this.ngProjectAs,
    this.reference,
  ]) : super.from(origin) {
    closeComplement = CloseElementAst('ng-content');
  }
}
