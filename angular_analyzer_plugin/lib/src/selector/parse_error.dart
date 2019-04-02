import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_contains_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_starts_with_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_value_regex_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/class_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/contains_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/not_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/or_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';
import 'package:angular_analyzer_plugin/src/selector/tokenizer.dart';
import 'package:meta/meta.dart';

/// Mixin used by parser and tokenizer to report [SelectorParseError]s.
mixin ReportParseErrors {
  String get str;

  /// Report that the [actual] string in a [Selector] didn't match [expected].
  void expected(String expected,
      {@required String actual, @required int offset}) {
    throw new SelectorParseError(
        "Expected $expected, got $actual", str, offset, actual.length);
  }

  /// Report an unexpected string [string] at [offset].
  void unexpected(String string, int offset) {
    throw new SelectorParseError(
        "Unexpected $string", str, offset, string.length);
  }
}

/// A type of [FormatException] specific to errors parsing [Selector]s.
class SelectorParseError extends FormatException {
  int length;
  SelectorParseError(String message, String source, int offset, this.length)
      : super(message, source, offset);
}
