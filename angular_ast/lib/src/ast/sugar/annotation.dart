import 'package:source_span/source_span.dart';

import '../../ast.dart';
import '../../hash.dart';
import '../../token/tokens.dart';
import '../../visitor.dart';

/// Represents an annotation `@annotation` on an element.
///
/// This annotation may optionally be assigned a value `@annotation="value"`.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class AnnotationAst implements TemplateAst {
  /// Create a new synthetic [AnnotationAst] with a string [name].
  factory AnnotationAst(String name, [String value]) = _SyntheticAnnotationAst;

  /// Create a new synthetic [AnnotationAst] that originated from node [origin].
  factory AnnotationAst.from(
    TemplateAst origin,
    String name, [
    String value,
  ]) = _SyntheticAnnotationAst.from;

  /// Create a new [AnnotationAst] parsed from tokens from [sourceFile].
  factory AnnotationAst.parsed(
    SourceFile sourceFile,
    NgToken prefixToken,
    NgToken nameToken, [
    NgAttributeValueToken valueToken,
    NgToken equalSignToken,
  ]) = ParsedAnnotationAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitAnnotation(this, context);
  }

  @override
  bool operator ==(Object o) {
    if (o is AnnotationAst) {
      return name == o.name && value == o.value;
    }
    return false;
  }

  @override
  int get hashCode => hash2(name, value);

  /// Static annotation name.
  String get name;

  /// Static annotation value.
  String get value;

  @override
  String toString() {
    if (value != null) {
      return '$AnnotationAst {$name="$value"}';
    }
    return '$AnnotationAst {$name}';
  }
}

/// Represents a real(non-synthetic) parsed AnnotationAst. Preserves offsets.
///
/// Clients should not extend, implement, or mix-in this class.
class ParsedAnnotationAst extends TemplateAst
    with AnnotationAst
    implements ParsedDecoratorAst {
  @override
  final NgToken prefixToken;

  /// [NgToken] that represents the annotation name.
  @override
  final NgToken nameToken;

  @override
  final NgAttributeValueToken valueToken;

  /// Represents the equal sign token between the annotation name and value.
  ///
  /// May be `null` if the annotation has no value.
  final NgToken equalSignToken;

  ParsedAnnotationAst(
    SourceFile sourceFile,
    this.prefixToken,
    this.nameToken, [
    this.valueToken,
    this.equalSignToken,
  ]) : super.parsed(
          prefixToken,
          valueToken != null ? valueToken.rightQuote : nameToken,
          sourceFile,
        );

  @override
  String get name => nameToken.lexeme;

  @override
  String get value => valueToken?.innerValue?.lexeme;

  /// Offset of annotation prefix `@`.
  @override
  int get prefixOffset => prefixToken.offset;

  @override
  NgToken get suffixToken => null;

  @override
  int get suffixOffset => null;
}

class _SyntheticAnnotationAst extends SyntheticTemplateAst with AnnotationAst {
  @override
  final String name;

  @override
  final String value;

  _SyntheticAnnotationAst(this.name, [this.value]);

  _SyntheticAnnotationAst.from(TemplateAst origin, this.name, [this.value])
      : super.from(origin);
}
