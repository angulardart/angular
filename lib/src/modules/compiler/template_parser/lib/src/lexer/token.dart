part of angular2_template_parser.src.lexer;

/// A recognized token while scanning a template.
class NgToken {
  /// What text was scanned.
  final SourceSpan source;

  /// Token text.
  final String text;

  /// What type of token.
  final NgTokenType type;

  /// Creates a new [NgToken] from a [type] and [text].
  NgToken(this.type, this.text) : source = null;

  /// Creates a new [NgToken] of [type] from [source].
  NgToken.fromSource(this.type, SourceSpan source)
      : this.text = source.text,
        this.source = source;

  @override
  bool operator ==(Object o) {
    if (o is NgToken) {
      return type == o.type && text == o.text;
    }
    return false;
  }

  @override
  int get hashCode => hash2(source, type);

  @override
  String toString() => '{$type: $text}';
}
