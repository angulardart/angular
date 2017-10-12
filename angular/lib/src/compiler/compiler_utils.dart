import "package:angular/src/facade/lang.dart" show jsSplit;

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

String packageToAssetScheme(String uri) {
  const packagePrefix = 'package:';
  if (!uri.startsWith(packagePrefix)) return uri;
  String path = uri.substring(packagePrefix.length);
  int pos = path.indexOf('/');
  assert(pos != -1);
  return 'asset:${path.substring(0, pos)}/lib${path.substring(pos)}';
}
