import 'package:analyzer/analyzer.dart';
import 'package:angular2/src/transform/common/logging.dart';

/// Checks that all deferred imports call the corresponding `initReflector`
/// methods.
void checkDeferredImportInitialization(
    String originalSource, CompilationUnit compilationUnit) {
  var deferredImportsToCheck = compilationUnit.directives.where((d) =>
      d is ImportDirective &&
      d.deferredKeyword != null &&
      !d.metadata.any((m) => m.name.name == 'SkipAngularInitCheck'));

  for (ImportDirective deferredImport in deferredImportsToCheck) {
    var uriString = deferredImport.uri.stringValue;
    if (!originalSource.contains('${deferredImport.prefix}.initReflector')) {
      log.error(
          "Found the deferred import `${deferredImport.toSource()}` but no "
          "corresponding call to `${deferredImport.prefix}.initReflector()`. "
          "Please see http://shortn/_17oWPn6PtH for information on how to set "
          "up your component so that it can work in codegen and transformer "
          "based apps.");
    } else if (!uriString.endsWith('.template.dart')) {
      log.error("The `initReflector` method only exists in the generated "
          "*.template.dart file. Please change the import to "
          "$uriString to ${uriString.replaceFirst(".dart", ".template.dart")}. "
          "See http://shortn/_17oWPn6PtH for more info.");
    }
  }
}
