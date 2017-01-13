import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

ReferenceBuilder toBuilder(DartType type, List<ImportElement> imports) =>
    reference(type.name, _importFrom(type, imports))
        .toTyped(_coerceTypeArgs(type, imports));

String _importFrom(DartType dartType, List<ImportElement> imports) {
  var definingLibrary = dartType.element.library;

  for (var import in imports) {
    if (import.importedLibrary == definingLibrary) {
      return import.uri;
    }
  }
  return null;
}

Iterable<TypeBuilder> _coerceTypeArgs(
    DartType type, List<ImportElement> imports) {
  if (type is! ParameterizedType) return const [];
  return (type as ParameterizedType)
      .typeArguments
      .map((type) => toBuilder(type, imports));
}
