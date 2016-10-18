part of angular2_template_parser.src.ast;

/// A parsed element, representing a browser element, directive, or component.
class NgElement extends NgAstNode with NgDefinedNode<NgElementDefinition> {
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
    SourceSpan source,
  }) {
    return new NgElement._(
      schema.tagName,
      schema,
      childNodes,
      parsedTokens,
      source,
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
      source,
    );
  }

  NgElement._(
    this.name,
    this.schema,
    Iterable<NgAstNode> childNodes,
    List<NgToken> parsedTokens,
    SourceSpan source,
  )
      : this.childNodes = (childNodes ?? const []).toList(),
        super._(parsedTokens, source);

  @override
  int get hashCode => hash2(name, super.hashCode);

  @override
  bool operator ==(Object o) => o is NgElement && name == o.name && super == o;
}
