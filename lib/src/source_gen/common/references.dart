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
    if (exportedElement == dartType.element &&
        _isAllowedByCombinators(dartType.element, import)) {
      return import.uri;
    }
  }
  return null;
}

bool _isAllowedByCombinators(Element element, ImportElement import) {
  if (import.combinators.isEmpty) return true;
  Iterable<HideElementCombinator> hideCombinators = import.combinators
      .where((combinator) => combinator is HideElementCombinator);
  Iterable<ShowElementCombinator> showCombinators = import.combinators
      .where((combinator) => combinator is ShowElementCombinator);
  var isHidden = hideCombinators
      .any((combinator) => combinator.hiddenNames.contains(element.name));

  if (isHidden) return false;
  if (showCombinators.isEmpty) return true;
  return showCombinators
      .any((combinator) => combinator.shownNames.contains(element.name));
}

Iterable<TypeBuilder> _coerceTypeArgs(
    DartType type, List<ImportElement> imports) {
  if (type is! ParameterizedType) return const [];
  var typeArgs = (type as ParameterizedType).typeArguments;
  if (typeArgs.every((t) => t.isDynamic)) return const [];
  return typeArgs.map((type) => toBuilder(type, imports));
}
