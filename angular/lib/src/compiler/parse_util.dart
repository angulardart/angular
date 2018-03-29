import 'package:angular_compiler/cli.dart';
import 'package:source_span/source_span.dart';

enum ParseErrorLevel { WARNING, FATAL }

abstract class ParseError extends BuildError {
  final SourceSpan _span;
  final String _msg;
  final ParseErrorLevel level;

  ParseError(this._span, this._msg, [this.level = ParseErrorLevel.FATAL]);

  @override
  String get message => _span.message('$level: $_msg');

  @override
  String toString() => message;
}
