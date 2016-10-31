part of angular2_template_parser.src.ast;

/// A parsed event AST.
class NgEvent extends NgAstNode with NgAstSourceTokenMixin {
  /// Name of the event.
  final String name;

  /// Listener of the event (an expression).
  final String value;

  NgEvent(this.name, this.value) : super._(const []);

  NgEvent.fromTokens(
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
    if (o is NgEvent) {
      return o.name == name && o.value == value;
    }
    return false;
  }

  @override
  String toString() => '$NgEvent ($name)="$value"';
}
