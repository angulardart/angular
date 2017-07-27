import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/src/utils.dart';

/// Returns the inheritance hierarchy of [type] in an ordered list.
///
/// Types are followed, in order, by their mixins, interfaces, and superclass.
List<InterfaceType> getInheritanceHierarchy(InterfaceType type) {
  final types = <InterfaceType>[];
  final typesToVisit = [type];
  final visitedTypes = new Set<InterfaceType>();
  while (typesToVisit.isNotEmpty) {
    final currentType = typesToVisit.removeLast();
    if (visitedTypes.contains(currentType)) continue;
    visitedTypes.add(currentType);
    final supertype = currentType.superclass;
    // Skip [Object], since it can't have metadata, mixins, or interfaces.
    if (supertype == null) continue;
    types.add(currentType);
    typesToVisit
      ..add(supertype)
      ..addAll(currentType.interfaces)
      ..addAll(currentType.mixins);
  }
  return types;
}

/// Returns a canonical URL pointing to [element].
///
/// For example, `List` would be `'dart:core#List'`.
Uri urlOf(Element element) {
  return normalizeUrl(element.source.uri).replace(fragment: element.name);
}
