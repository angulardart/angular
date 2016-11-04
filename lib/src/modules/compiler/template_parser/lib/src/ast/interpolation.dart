part of angular2_template_parser.src.ast;

/// A simple string value (not an expression).
class NgInterpolation extends NgAstNode with NgAstSourceTokenMixin {
  /// Expression value.
  final String value;

  /// Create a new [NgInterpolation] node.
  NgInterpolation(this.value) : super._(const []);

  NgInterpolation.fromTokens(
    NgToken start,
    NgToken interpolate,
    NgToken end,
  )
      : this.value = interpolate.text,
        super._([start, interpolate, end]);

  @override
  bool operator ==(Object o) => o is NgInterpolation && value == o.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$NgInterpolation $value';
}
