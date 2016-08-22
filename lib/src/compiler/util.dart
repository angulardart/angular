import "package:angular2/src/facade/lang.dart" show jsSplit;

const MODULE_SUFFIX = ".dart";
var CAMEL_CASE_REGEXP = new RegExp(r'([A-Z])');
var DASH_CASE_REGEXP = new RegExp(r'-([a-z])');
String camelCaseToDashCase(String input) {
  return input.replaceAllMapped(CAMEL_CASE_REGEXP, (m) {
    return "-" + m[1].toLowerCase();
  });
}

String dashCaseToCamelCase(String input) {
  return input.replaceAllMapped(DASH_CASE_REGEXP, (m) {
    return m[1].toUpperCase();
  });
}

List<String> splitAtColon(String input, List<String> defaultValues) {
  var parts = jsSplit(input.trim(), (new RegExp(r'\s*:\s*')));
  if (parts.length > 1) {
    return parts;
  } else {
    return defaultValues;
  }
}

String sanitizeIdentifier(String name) {
  return name.replaceAll(new RegExp(r'\W'), "_");
}
