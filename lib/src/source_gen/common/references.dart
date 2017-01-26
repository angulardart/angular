import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

ReferenceBuilder toBuilder(DartType type, List<ImportElement> imports) =>
    reference(type.name, _importFrom(type, imports))
        .toTyped(_coerceTypeArgs(type, imports));

String _importFrom(DartType dartType, List<ImportElement> imports) {
  var definingLibrary = dartType.element.library;
  for (final import in imports) {
    if (_definesLibrary(import, definingLibrary)) {
      return import.uri;
    }
  }
  return null;
}

bool _definesLibrary(ImportElement import, LibraryElement library) =>
    import.importedLibrary == library ||
    import.importedLibrary.exportedLibraries
        .any((exportedLibrary) => exportedLibrary == library);

Iterable<TypeBuilder> _coerceTypeArgs(
    DartType type, List<ImportElement> imports) {
  if (type is! ParameterizedType) return const [];
  var typeArgs = (type as ParameterizedType).typeArguments;
  if (_isDynamic(typeArgs)) return const [];
  return typeArgs.map((type) => toBuilder(type, imports));
}

bool _isDynamic(List<DartType> types) =>
    types.length == 1 && types.first.isDynamic;
