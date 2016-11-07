part of angular2_template_parser.src.compiler_error;

/// When more than one structural directives is used on a single element.
class ExtraStructuralDirectiveError extends SourceError {
  /// The element where more than one directive was attempted.
  final NgElement element;

  /// Orginal directive's name.
  final NgToken firstNameToken;

  /// Original directive's value.
  final NgToken firstValueToken;

  /// The extra directive's name.
  final NgToken nameToken;

  /// The extra directive's value.
  final NgToken valueToken;

  factory ExtraStructuralDirectiveError(
    NgElement elementAst,
    NgToken startToken,
    NgToken nameToken,
    NgToken valueToken,
    NgToken firstNameToken,
    NgToken firstValueToken,
  ) =>
      new ExtraStructuralDirectiveError._(
          elementAst,
          nameToken,
          valueToken,
          firstNameToken,
          firstValueToken,
          [startToken, nameToken].fold/*<SourceSpan>*/(
            null,
            (span, token) {
              return span == null ? token.source : span.union(token.source);
            },
          ));

  ExtraStructuralDirectiveError._(this.element, this.nameToken, this.valueToken,
      this.firstNameToken, this.firstValueToken, SourceSpan context)
      : super._(context);

  @override
  String toString() => toFriendlyMessage(
        header:
            'Cannot have more than a single structural (*) directive on an element',
        fixIt:
            // ---------------------------------80 chars--------------------------------------
            'Structural directives (i.e. ${context.text}) are just a convenience syntax:\n'
            '    <template [${nameToken.text}]="${valueToken.text}">\n'
            '      <${element.name}>...</${element.name}>\n'
            '    </template>\n'
            '\n\n'
            'Rewrite your tags as nested <template> tags in order you want them to apply:\n'
            '    <template [${firstNameToken.text}]="${firstValueToken.text}">\n'
            '      <template [${nameToken.text}]="${valueToken.text}">\n'
            '        <${element.name}>...</${element.name}>\n'
            '      </template>\n'
            '    </template>',
      );
}
