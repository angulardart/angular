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
