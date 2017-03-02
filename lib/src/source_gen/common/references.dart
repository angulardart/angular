import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

ReferenceBuilder toBuilder(DartType type, List<ImportElement> imports) =>
    reference(type.name, _importFrom(type, imports))
        .toTyped(_coerceTypeArgs(type, imports));

String _importFrom(DartType dartType, List<ImportElement> imports) {
  var definingLibrary = dartType.element.library;
  for (final import in imports) {
    if (_definesLibrary(import.importedLibrary, definingLibrary) &&
        // We might have some collection of show/hide that hides this symbol.
        // Easier to avoid then do this wrong, for now (b/35879283).
        import.combinators.isEmpty) {
      return import.uri;
    }
  }
  return null;
}

bool _definesLibrary(LibraryElement importedLibrary, LibraryElement library) =>
    importedLibrary == library ||
    importedLibrary.exportedLibraries
        .any((exportedLibrary) => _definesLibrary(exportedLibrary, library));

Iterable<TypeBuilder> _coerceTypeArgs(
    DartType type, List<ImportElement> imports) {
  if (type is! ParameterizedType) return const [];
  var typeArgs = (type as ParameterizedType).typeArguments;
  if (typeArgs.every((t) => t.isDynamic)) return const [];
  return typeArgs.map((type) => toBuilder(type, imports));
}
