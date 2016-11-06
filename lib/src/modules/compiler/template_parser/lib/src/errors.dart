library angular2_template_parser.src.compiler_error;

import 'package:source_span/source_span.dart';

import 'ast.dart';
import 'lexer.dart';

part 'errors/extra_structural_directive.dart';
part 'errors/illegal_tag_name.dart';

/// Represents errors with [SourceSpan]s found while parsing.
abstract class SourceError implements Error {
  /// The location of parsed text that caused the error.
  final SourceSpan context;

  @override
  final StackTrace stackTrace = StackTrace.current;

  SourceError._(this.context);

  /// Provides a formatted error message when something goes wrong.
  String toFriendlyMessage({
    String header: 'Invalid text',
    String fixIt: '',
  }) =>
    '${context.message(header)}\n'
    '\n'
    '$fixIt';

  // A default toString message that at least gives contextual information.
  @override
  String toString() => '${context.message('An error occured parsing')}';
}
