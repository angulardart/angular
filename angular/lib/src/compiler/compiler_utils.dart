import "package:angular/src/facade/lang.dart" show jsSplit;

import 'compile_metadata.dart';

const MODULE_SUFFIX = ".dart";

List<String> splitAtColon(String input, List<String> defaultValues) {
  var parts = jsSplit(input.trim(), (new RegExp(r'\s*:\s*')));
  if (parts.length > 1) {
    return parts;
  } else {
    return defaultValues;
  }
}

String sanitizeIdentifier(Object name) {
  return name.toString().replaceAll(new RegExp(r'\W'), "_");
}

String templateModuleUrl(CompileTypeMetadata type) {
  var moduleUrl = type.moduleUrl;
  var urlWithoutSuffix =
      moduleUrl.substring(0, moduleUrl.length - MODULE_SUFFIX.length);
  return '$urlWithoutSuffix.template$MODULE_SUFFIX';
}

String stylesModuleUrl(String stylesheetUrl, bool shim) {
  return shim
      ? '$stylesheetUrl.shim$MODULE_SUFFIX'
      : '$stylesheetUrl$MODULE_SUFFIX';
}
