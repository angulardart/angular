import "package:angular/src/facade/lang.dart" show jsSplit;

import 'compile_metadata.dart';

const moduleSuffix = ".dart";

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
      moduleUrl.substring(0, moduleUrl.length - moduleSuffix.length);
  return '$urlWithoutSuffix.template$moduleSuffix';
}

String stylesModuleUrl(String stylesheetUrl, bool shim) {
  return shim
      ? '$stylesheetUrl.shim$moduleSuffix'
      : '$stylesheetUrl$moduleSuffix';
}
