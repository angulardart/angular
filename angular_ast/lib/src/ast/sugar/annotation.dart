import 'package:source_span/source_span.dart';

import '../../ast.dart';
import '../../token/tokens.dart';
import '../../visitor.dart';

/// Represents the sugared form of `@annotation`.
///
/// This AST may only exist in the parses that do not de-sugar directives (i.e.
/// useful for tooling, but not useful for compilers).
///
/// Clients should not extend, implement, or mix-in this class.
abstract class AnnotationAst implements TemplateAst {
  /// Create a new synthetic [AnnotationAst] with a string [name].
  factory AnnotationAst(String name) = _SyntheticAnnotationAst;

  /// Create a new synthetic [AnnotationAst] that originated from node [origin].
  factory AnnotationAst.from(TemplateAst origin, String name) =
      _SyntheticAnnotationAst.from;

  /// Create a new [AnnotationAst] parsed from tokens from [sourceFile].
  factory AnnotationAst.parsed(SourceFile sourceFile, NgToken prefixToken,
      NgToken elementDecoratorToken) = ParsedAnnotationAst;

  @override
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]) {
    return visitor.visitAnnotation(this, context);
  }

  @override
  bool operator ==(Object o) {
    if (o is AnnotationAst) {
      return name == o.name;
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;

  /// Static Annotation name.
  String get name;

  @override
  String toString() {
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

  ParsedAnnotationAst(SourceFile sourceFile, this.prefixToken, this.nameToken)
      : super.parsed(
          prefixToken,
          nameToken,
          sourceFile,
        );

  /// Static annotation name.
  @override
  String get name => nameToken.lexeme;

  /// Offset of template prefix `*`.
  @override
  int get prefixOffset => prefixToken.offset;

  @override
  NgToken get suffixToken => null;

  @override
  int get suffixOffset => null;

  @override
  NgAttributeValueToken get valueToken => null;
}

class _SyntheticAnnotationAst extends SyntheticTemplateAst with AnnotationAst {
  @override
  final String name;

  _SyntheticAnnotationAst(this.name);

  _SyntheticAnnotationAst.from(TemplateAst origin, this.name)
      : super.from(origin);
}
