import 'package:angular_ast/angular_ast.dart';
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

class AstExceptionHandler extends RecoveringExceptionHandler {
  final String template;
  final String sourceUrl;

  final parseErrors = <ParseError>[];

  AstExceptionHandler(this.template, this.sourceUrl);

  void handleParseError(ParseError error) {
    parseErrors.add(error);
  }

  void handleAll(Iterable<ParseError> errors) {
    parseErrors.addAll(errors);
  }

  void maybeReportExceptions() {
    if (exceptions.isNotEmpty) {
      // We always throw here, so no need to clear the list.
      _reportExceptions();
    }
    if (parseErrors.isNotEmpty) {
      // TODO(alorenzen): Once this is no longer used for the legacy parser,
      // rename to reportParseErrors.
      _handleParseErrors(parseErrors);
      // handleParseErrors() may only log warnings and not throw, so we need to
      // clear the list before the next phase.
      parseErrors.clear();
    }
  }

  void _reportExceptions() {
    final sourceFile = SourceFile.fromString(template, url: sourceUrl);
    final buildErrors = exceptions.map((exception) => BuildError.forSourceSpan(
        sourceFile.span(exception.offset, exception.offset + exception.length),
        exception.errorCode.message));

    throw BuildError.multiple(buildErrors, 'Template parse errors');
  }
}

void _handleParseErrors(List<ParseError> parseErrors) {
  final warnings = <ParseError>[];
  final errors = <ParseError>[];
  for (final error in parseErrors) {
    if (error.level == ParseErrorLevel.WARNING) {
      warnings.add(error);
    } else if (error.level == ParseErrorLevel.FATAL) {
      errors.add(error);
    }
  }
  if (warnings.isNotEmpty) {
    logWarning('Template parse warnings:\n${warnings.join('\n')}');
  }
  if (errors.isNotEmpty) {
    throw BuildError.multiple(errors, 'Template parse errors');
  }
}
