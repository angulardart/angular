part of angular2_template_parser.src.ast;

/// A parsed property AST.
class NgProperty extends NgAstNode with NgAstSourceTokenMixin {
  /// Name of the property.
  final String name;

  /// Value of the property (an expression).
  final String value;

  NgProperty(this.name, this.value) : super._(const []);

  NgProperty.fromTokens(
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
  int get hashCode => hash2(name, value);

  @override
  bool operator ==(Object o) {
    if (o is NgProperty) {
      return o.name == name && o.value == value;
    }
    return false;
  }

  @override
  String toString() => '$NgProperty [$name]="$value"';
}
