part of angular2_template_parser.src.ast;

/// A comment node.
class NgComment extends NgAstNode with NgAstSourceTokenMixin {
  /// Comment value.
  final String value;

  /// Create a new [NgComment] node.
  NgComment(this.value) : super._(null);

  /// Create a new [NgComment] node from [NgToken]s.
  NgComment.fromTokens(
      NgToken beginComment, NgToken comment, NgToken endComment)
      : this.value = comment.text,
        super._([beginComment, comment, endComment]);

  @override
  int get hashCode {
    return parsedTokens == null ? value.hashCode : super.hashCode;
  }

  @override
  bool operator==(Object o) {
    if (o is NgComment) {
      return parsedTokens == null ? value == o.value : super == o;
    }
    return false;
  }
}
