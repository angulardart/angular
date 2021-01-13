/// A support library imported by `additional_expression_test.dart`.
library additional_expression_lib;

/// A class with static members to be referenced by a template.
class ExternalStaticClass {
  static String? nullString;
  static String returnsA() => 'A';
  static const valueB = 'staticB';
}

/// A top-level function to be referenced by a template.
String toUppercase(String input) => input.toUpperCase();

/// A top-level field to be referneced by a template.
const valueB = 'topLevelB';

/// A top-level field that is null.
const String? nullString = null;
