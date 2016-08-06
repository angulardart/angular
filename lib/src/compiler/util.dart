import "package:angular2/src/facade/lang.dart" show StringWrapper;

const MODULE_SUFFIX = ".dart";
var CAMEL_CASE_REGEXP = new RegExp(r'([A-Z])');
var DASH_CASE_REGEXP = new RegExp(r'-([a-z])');
String camelCaseToDashCase(String input) {
  return StringWrapper.replaceAllMapped(input, CAMEL_CASE_REGEXP, (m) {
    return "-" + m[1].toLowerCase();
  });
}

String dashCaseToCamelCase(String input) {
  return StringWrapper.replaceAllMapped(input, DASH_CASE_REGEXP, (m) {
    return m[1].toUpperCase();
  });
}

List<String> splitAtColon(String input, List<String> defaultValues) {
  var parts = StringWrapper.split(input.trim(), new RegExp(r'\s*:\s*'));
  if (parts.length > 1) {
    return parts;
  } else {
    return defaultValues;
  }
}

String sanitizeIdentifier(String name) {
  return StringWrapper.replaceAll(name, new RegExp(r'\W'), "_");
}
