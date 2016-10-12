import "package:angular2/src/facade/lang.dart" show jsSplit;

const MODULE_SUFFIX = ".dart";

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
