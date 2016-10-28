part of angular2_template_parser.src.ast;

/// A simple string value (not an expression).
class NgText extends NgAstNode with NgAstSourceTokenMixin {
  /// Text value.
  final String value;

  /// Create a new [text] node.
  factory NgText(
    String text, [
    NgToken parsedToken,
  ]) = NgText._;

  NgText._(
    this.value, [
    NgToken parsedToken,
  ])
      : super._(parsedToken != null ? [parsedToken] : const []);

  @override
  bool operator ==(Object o) => o is NgText && value == o.value;

  @override
  int get hashCode => value.hashCode;
}
