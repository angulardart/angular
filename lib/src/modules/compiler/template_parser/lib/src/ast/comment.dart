part of angular2_template_parser.src.ast;

/// A parsed comment AST.
/// 
/// Comments are used to annotate the HTML to provide extra information for
/// developers or tools but are not rendered when the application is rendered
/// within the browser.
///
/// Comments may be removed in a production build.
///
/// ### Grammar
///   ```bnf
///   Comment ::= '<!--' CommentCharData? '-->'
///   ```
///
/// ### Examples
///   ```html
///   <!-- A single or multi line comment -->
///   ``` 
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
