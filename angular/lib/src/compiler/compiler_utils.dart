import 'compile_metadata.dart';

const moduleSuffix = ".dart";

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
