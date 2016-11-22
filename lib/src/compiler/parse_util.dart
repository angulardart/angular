import 'package:source_span/source_span.dart';

enum ParseErrorLevel { WARNING, FATAL }

abstract class ParseError {
  final SourceSpan span;
  final String msg;
  final ParseErrorLevel level;

  ParseError(this.span, this.msg, [this.level = ParseErrorLevel.FATAL]);

  @override
  String toString() => span.message('$level: $msg');
}
