import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

dynamic _toLiteral(DartObject o) {
  final literal = new ConstantReader(o).anyValue;
  if (literal is List) {
    return literalList(literal);
  }
  if (literal is Map) {
    return literalMap(literal);
  }
  return literal;
}

/// Returns [list] with all literal types recursively inlined as a dart literal.
List<T> literalList<T>(List<DartObject> list) => list.map(_toLiteral).toList();

/// Returns [map] with all literal types recursively inlined as a dart literal.
Map<K, V> literalMap<K, V>(Map<DartObject, DartObject> map) =>
    mapMap<DartObject, DartObject, K, V>(map,
        key: (k, _) => _toLiteral(k), value: (_, v) => _toLiteral(v));

/// Returns [map] with all literal values recursively inlined as a literal.
Map<String, T> literalStringMap<T>(Map<String, DartObject> map) =>
    mapMap<String, DartObject, String, T>(map, value: (_, v) => _toLiteral(v));
