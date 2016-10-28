part of angular2_template_parser.src.ast;

/// A parsed element AST.
///
/// A [NgElement] represents a browser element, directive, or component, of
/// which may be determined by looking at the [schema] found when parsing.
class NgElement extends NgAstNode
    with NgDefinedNode<NgElementDefinition>, NgAstSourceTokenMixin {
  @override
  final List<NgAstNode> childNodes;

  /// Name of the element parsed.
  ///
  /// In HTML, this is referred to as the tag name (`<tag-name>`).
  final String name;

  /// Recognized element definition when this was parsed.
  ///
  /// This property may be `null` when [unknown].
  @override
  final NgElementDefinition schema;

  /// Create a new [schema] element.
  factory NgElement(
    NgElementDefinition schema, {
    Iterable<NgAstNode> childNodes,
    List<NgToken> parsedTokens,
  }) {
    return new NgElement._(
      schema.tagName,
      schema,
      childNodes,
      parsedTokens,
    );
  }

  /// Create a new [tagName] that was not recogniezd from a schema.
  factory NgElement.unknown(
    String tagName, {
    Iterable<NgAstNode> childNodes,
    List<NgToken> parsedTokens,
    SourceSpan source,
  }) {
    return new NgElement._(
      tagName,
      null,
      childNodes,
      parsedTokens,
    );
  }

  NgElement._(
    this.name,
    this.schema,
    Iterable<NgAstNode> childNodes,
    List<NgToken> parsedTokens,
  )
      : this.childNodes = (childNodes ?? const []).toList(),
        super._(parsedTokens);

  @override
  int get hashCode => hash2(name, super.hashCode);

  @override
  bool operator ==(Object o) => o is NgElement && name == o.name && super == o;
}
