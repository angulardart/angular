library angular2_template_parser.src.compiler_error;

import 'package:source_span/source_span.dart';
import 'ast.dart';
import 'lexer.dart';

part 'errors/extra_structural_directive.dart';
part 'errors/illegal_tag_name.dart';

/// [SourceError] represents errors with source span information.
///
///
abstract class SourceError implements Error {
  final Iterable<NgToken> prev, current, next;

  @override
  final StackTrace stackTrace;

  const SourceError(this.prev, this.current, this.next, this.stackTrace);
}
