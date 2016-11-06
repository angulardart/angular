part of angular2_template_parser.src.compiler_error;


class IllegalTagName implements Error {

  @override
  StackTrace stackTrace;

  final Iterable<NgToken> contextBefore;
  final NgToken element;

  IllegalTagName(this.element, this.contextBefore)
      : stackTrace = StackTrace.current;

  @override
  String toString() {
    final location = element.source;
    final prev = contextBefore.map((x) => x.source.text).join('');
    return '${location.start.line}:${location.start.column} '
      'error: tag name for element is invalid.\n\n'
      '$prev<${element.source.text}\n'
      '${" " * (prev.length + 1)}${"^" * element.source.text.length}\n'
      'To fix this error, make sure the tag name starts with an ascii letter,\n'
      'followed by any number of ascii letters, numbers, or the '
      'symbols "-" and "_"';
  }
}
