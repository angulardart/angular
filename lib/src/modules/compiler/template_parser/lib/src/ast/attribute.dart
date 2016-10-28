part of angular2_template_parser.src.ast;

class NgAttribute extends NgAstNode with NgAstSourceTokenMixin {
  final String name;

  final String value;

  NgAttribute(this.name, [this.value]) : super._(const []);

  NgAttribute.fromTokens(
      NgToken begin,
      NgToken name,
      NgToken end)
          : this.name = name.text,
            this.value = null,
            super._([begin, name, end]);
  
  NgAttribute.fromTokensWithValue(
      NgToken before,
      NgToken name,
      NgToken space,
      NgToken value,
      NgToken end)
          : this.name = name.text,
            this.value = value.text,
            super._([before, name, value, end]);

  @override
  int get hashCode => hash2(name, value);

  @override
  bool operator==(Object o) {
    if (o is NgAttribute) {
      return o.name == name && o.value == value;
    }
    return false;
  }
}
