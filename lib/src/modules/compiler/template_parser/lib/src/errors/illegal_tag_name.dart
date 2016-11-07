part of angular2_template_parser.src.compiler_error;

/// When an [NgTokenType.elementName] contains an invalid character.
class IllegalTagNameError extends SourceError {
  /// The parsed [NgToken] representing the element name.
  final NgToken elementToken;

  factory IllegalTagNameError(NgToken elementToken) {
    return new IllegalTagNameError._(elementToken, elementToken.source);
  }

  IllegalTagNameError._(this.elementToken, SourceSpan context)
      : super._(context);

  @override
  String toString() => toFriendlyMessage(
      header: 'Tag name for an Element is invalid',
      fixIt:
          // ---------------------------------80 chars--------------------------------------
          'To fix this error, make sure the tag name starts with an ascii letter, followed \n'
          'by any number of ascii letters, numbers, or the symbols "-" and "_".');
}
