part of angular2_template_parser.src.ast;

/// A parsed binding AST.
class NgBinding extends NgAstNode with NgAstSourceTokenMixin {
  /// Name of the binding.
  final String name;

  /// An optional value
  final String value;

  /// Create a new [NgBinding] with a [name].
  NgBinding(this.name, {this.value}) : super._(const []);

  /// Create a new [NgBinding] from tokenized HTML.
  NgBinding.fromTokens(
    NgToken before,
    NgToken start,
    NgToken name,
    NgToken end,
  )
      : this.name = name.text,
        this.value = null,
        super._([before, start, name, end]);

  /// Create a new [NgBinding] with a value from tokenizer HTML.
  NgBinding.fromTokensWithValue(
    NgToken before,
    NgToken start,
    NgToken name,
    NgToken equals,
    NgToken value,
    NgToken end,
  )
      : this.name = name.text,
        this.value = value.text,
        super._([before, start, name, equals, value, end]);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object o) {
    if (o is NgBinding) {
      return o.name == name && o.value == value;
    }
    return false;
  }

  @override
  void visit(Visitor visitor) => visitor.visitBinding(this);

  @override
  String toString() => '$NgBinding #$name ${value != null ? value : ""}';
}
