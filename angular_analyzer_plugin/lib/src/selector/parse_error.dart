import 'package:meta/meta.dart';

/// Mixin used by parser and tokenizer to report [SelectorParseError]s.
mixin ReportParseErrors {
  String get str;

  /// Report that the [actual] string in a [Selector] didn't match [expected].
  void expected(String expected,
      {@required String actual, @required int offset}) {
    throw SelectorParseError(
        "Expected $expected, got $actual", str, offset, actual.length);
  }

  /// Report an unexpected string [string] at [offset].
  void unexpected(String string, int offset) {
    throw SelectorParseError("Unexpected $string", str, offset, string.length);
  }
}

/// A type of [FormatException] specific to errors parsing [Selector]s.
class SelectorParseError extends FormatException {
  int length;
  SelectorParseError(String message, String source, int offset, this.length)
      : super(message, source, offset);
}
