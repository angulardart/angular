part of 'exception_handler.dart';

/// Exception class to be used in AngularAst parser.
@sealed
class AngularParserException extends Error {
  /// Length of error segment/token.
  final int? length;

  /// Reasoning for exception to be raised.
  final ParserErrorCode errorCode;

  /// Offset of where the exception was detected.
  final int? offset;

  AngularParserException(
    this.errorCode,
    this.offset,
    this.length,
  );

  @override
  bool operator ==(Object o) {
    if (o is AngularParserException) {
      return errorCode == o.errorCode &&
          length == o.length &&
          offset == o.offset;
    }
    return false;
  }

  @override
  int get hashCode => hash3(errorCode, length, offset);

  @override
  String toString() => 'AngularParserException{$errorCode}';
}
