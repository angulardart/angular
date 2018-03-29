import 'package:angular_compiler/cli.dart';
import 'package:source_span/source_span.dart';

enum ParseErrorLevel { WARNING, FATAL }

abstract class ParseError implements BuildError {
  final SourceSpan _span;
  final String _msg;
  final ParseErrorLevel _level;

  ParseError(this._span, this._msg, [this._level = ParseErrorLevel.FATAL]);

  @override
  String get message => _span.message('$_level: $_msg');

  @override
  String toString() => message;
}
