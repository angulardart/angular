import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

ReferenceBuilder toBuilder(DartType type, List<ImportElement> imports) =>
    reference(type.name, _importFrom(type, imports))
        .toTyped(_coerceTypeArgs(type, imports));

String _importFrom(DartType dartType, List<ImportElement> imports) {
  for (final import in imports) {
    final exportedElement =
        import.importedLibrary.exportNamespace?.get(dartType.element.name);
    if (exportedElement == dartType.element) {
      return import.uri;
    }
  }
  return null;
}

Iterable<TypeBuilder> _coerceTypeArgs(
    DartType type, List<ImportElement> imports) {
  if (type is! ParameterizedType) return const [];
  var typeArgs = (type as ParameterizedType).typeArguments;
  if (typeArgs.every((t) => t.isDynamic)) return const [];
  return typeArgs.map((type) => toBuilder(type, imports));
}
