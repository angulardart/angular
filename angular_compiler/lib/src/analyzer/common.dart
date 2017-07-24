import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/src/utils.dart';

/// Returns a canonical URL pointing to [element].
///
/// For example, `List` would be `'dart:core#List'`.
Uri urlOf(Element element) {
  return normalizeUrl(element.source.uri).replace(fragment: element.name);
}
