part of angular2_template_parser.src.ast;

/// A parsed attribute AST.
///
/// An attribute is static property [name] defined at compile-time that
/// decorates an [NgElement]. A non-null [value] means the attribute also
/// receives a value, otherwise it is considered standalone.
class NgAttribute extends NgAstNode with NgAstSourceTokenMixin {
  /// Name of the attribute.
  final String name;

  /// Value of the attribute.
  ///
  /// If `null`, the attribute is considered value-less.
  final String value;

  /// Create a new [NgAttribute] with a [name] and [value].
  NgAttribute(this.name, [this.value]) : super._(const []);

  /// Create a new [NgAttribute] from tokenized HTML.
  NgAttribute.fromTokens(NgToken begin, NgToken name, NgToken end)
      : this.name = name.text,
        this.value = null,
        super._([begin, name, end]);

  /// Create a new [NgAttribute] with a [value] from tokenized HTML.
  NgAttribute.fromTokensWithValue(
      NgToken before, NgToken name, NgToken space, NgToken value, NgToken end)
      : this.name = name.text,
        this.value = value.text,
        super._([before, name, value, end]);

  @override
  int get hashCode => hash2(name, value);

  @override
  bool operator ==(Object o) {
    if (o is NgAttribute) {
      return o.name == name && o.value == value;
    }
    return false;
  }

  @override
  String toString() => '$NgAttribute $name="$value"';
}
