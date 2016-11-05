part of angular2_template_parser.src.compiler_error;


class ExtraStructuralDirective implements Error {

  @override
  StackTrace stackTrace;

  Iterable<NgToken> node;
  NgElement parent;

  ExtraStructuralDirective(this.parent, this.node): stackTrace = StackTrace.current;

  @override
  String toString() {
    final problemTag = node.map((x) => x.source.text).join('');
    final parentTag = parent.parsedTokens.map((x) => x.text).join('');
    final location = node.first.source;
    return
      '${location.start.line}:${location.start.column} '
      'error: cannot have multiple structural directives on the same tag.\n\n'
      '$parentTag$problemTag\n'
      '${" " * parentTag.length}${"^" * problemTag.length}\n'
      'to fix this error, change the first structural directive to a property with the same name\n'
      'and place it on a template tag wrapping the existing element.\n\n'
      '    <template [firstDirective]="...">\n'
      '      <div *secondDirective="..."></div>\n'
      '    </template>\n'
      '    \n';
  }
}
