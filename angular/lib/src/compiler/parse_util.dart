import 'package:angular_ast/angular_ast.dart';
import 'package:angular_compiler/cli.dart';
import 'package:source_span/source_span.dart';

enum ParseErrorLevel { WARNING, FATAL }

abstract class ParseError extends BuildError {
  final SourceSpan _span;
  final String _msg;
  final ParseErrorLevel level;
  String _context;

  ParseError(this._span, this._msg, [this.level = ParseErrorLevel.FATAL]);

  @override
  String get message {
    var context = _context == null || _context.isEmpty ? '' : '($_context) ';
    return _span.message('$level: $context$_msg');
  }

  @override
  String toString() => message;

  void setContext(String context) => _context = context;
}

class AstExceptionHandler implements ExceptionHandler {
  final SourceFile _sourceFile;
  final _angularExceptionHandler = AngularExceptionHandler();
  final String _componentName;

  AstExceptionHandler(String template, String sourceUrl, [String componentName])
      : _sourceFile = SourceFile.fromString(template, url: sourceUrl),
        _componentName = componentName;

  @override
  void handle(AngularParserException e) {
    _angularExceptionHandler.handle(_toBuildError(e));
  }

  @override
  void handleWarning(AngularParserException e) {
    _angularExceptionHandler.handleWarning(_toBuildError(e));
  }

  void handleParseError(ParseError error) {
    error.setContext(_componentName);
    if (error.level == ParseErrorLevel.WARNING) {
      _angularExceptionHandler.handleWarning(error);
    } else {
      _angularExceptionHandler.handle(error);
    }
  }

  void handleAll(Iterable<ParseError> errors) {
    errors.forEach(handleParseError);
  }

  Future<void> maybeReportExceptions() =>
      _angularExceptionHandler.maybeReportErrors();

  BuildError _toBuildError(AngularParserException exception) =>
      BuildError.forSourceSpan(
          _sourceFile.span(
              exception.offset, exception.offset + exception.length),
          exception.errorCode.message);
}
