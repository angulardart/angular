import 'package:source_span/source_span.dart';

import '../ast.dart';
import '../token/tokens.dart';
import '../visitor.dart';

/// Represents a bound text element to an expression.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class InterpolationAst implements StandaloneTemplateAst {
  /// Create a new synthetic [InterpolationAst] with a bound [expression].
  factory InterpolationAst(
    String value,
  ) = _SyntheticInterpolationAst;

  /// Create a new synthetic [InterpolationAst] that originated from [origin].
  factory InterpolationAst.from(
    TemplateAst origin,
    String value,
  ) = _SyntheticInterpolationAst.from;

  /// Create a new [InterpolationAst] parsed from tokens in [sourceFile].
  factory InterpolationAst.parsed(
    SourceFile sourceFile,
    NgToken beginToken,
    NgToken valueToken,
    NgToken endToken,
  ) = ParsedInterpolationAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C?> visitor, [C? context]) {
    return visitor.visitInterpolation(this, context);
  }

  /// Bound String value used in expression; used to preserve offsets
  String get value;

  @override
  bool operator ==(Object o) {
    return o is InterpolationAst && o.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$InterpolationAst {$value}';
}

class ParsedInterpolationAst extends TemplateAst with InterpolationAst {
  final NgToken valueToken;

  ParsedInterpolationAst(
    SourceFile sourceFile,
    NgToken beginToken,
    this.valueToken,
    NgToken endToken,
  ) : super.parsed(beginToken, endToken, sourceFile);

  @override
  String get value => valueToken.lexeme;
}

class _SyntheticInterpolationAst extends SyntheticTemplateAst
    with InterpolationAst {
  _SyntheticInterpolationAst(this.value);

  _SyntheticInterpolationAst.from(
    TemplateAst origin,
    this.value,
  ) : super.from(origin);

  @override
  final String value;
}
