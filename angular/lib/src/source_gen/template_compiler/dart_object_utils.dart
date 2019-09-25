import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

/// Reads and returns [field] on [value] as a boolean.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or is not a boolean, returns [defaultTo].
bool coerceBool(DartObject value, String field, {bool defaultTo}) =>
    getField(value, field)?.toBoolValue() ?? defaultTo;

/// Reads and returns [field] on [value] as an integer.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or is not a boolean, returns [defaultTo].
int coerceInt(DartObject value, String field, {int defaultTo}) =>
    getField(value, field)?.toIntValue() ?? defaultTo;

/// Reads and returns [field] on [value] as a string.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or is not a string, returns [defaultTo].
String coerceString(DartObject value, String field, {String defaultTo}) =>
    getField(value, field)?.toStringValue() ?? defaultTo;

/// Reads and returns [field] on [value] as a list.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or not a list, returns [defaultTo].
List<DartObject> coerceList(
  DartObject value,
  String field, {
  List<DartObject> defaultTo = const [],
}) =>
    getField(value, field)?.toListValue() ?? defaultTo;

/// Reads and returns [field] on [value] as a list of strings.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or not a list, returns [defaultTo].
List<String> coerceStringList(
  DartObject value,
  String field, {
  List<String> defaultTo = const [],
}) {
  final list = getField(value, field)?.toListValue();
  return list != null
      ? list.map((o) => o.toStringValue()).where((s) => s != null).toList()
      : defaultTo;
}

/// Reads and returns [field] on value as a map of string -> string.
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or not a map, returns [defaultTo].
Map<String, String> coerceStringMap(
  DartObject value,
  String field, {
  Map<String, String> defaultTo = const {},
}) {
  final map = getField(value, field)?.toMapValue();
  if (map == null) {
    return defaultTo;
  }
  final result = <String, String>{};
  map.forEach((key, value) {
    result[key.toStringValue()] = value.toStringValue();
  });
  return result;
}

/// Reads and returns [field] on value as an enum from [values].
///
/// Unlike `DartObject#getField`, this also traverses `super` if available.
///
/// If the value is missing or not a map, returns [defaultTo].
T coerceEnum<T>(
  DartObject object,
  String field,
  List<T> values, {
  T defaultTo,
}) {
  final enumField = getField(object, field);
  if (enumField == null || enumField.isNull) {
    return defaultTo;
  }
  final enumValue =
      _findEnumByName(enumField, values) ?? _findEnumByIndex(enumField, values);
  if (enumValue == null) {
    throw ArgumentError(
      'Could not determine the enum of $enumField from $values',
    );
  }
  return enumValue;
}

/// Returns the element representing the declaration of [value]'s type.
///
/// May return null if [value] isn't a valid constant expression or has an
/// unknown type.
Element typeDeclarationOf(DartObject value) {
  var function = value.toFunctionValue();
  if (function != null) return function;

  // For functions, `toTypeValue()` is null so we fall back on `type`.
  final type = value.toTypeValue() ?? value.type;
  return type?.element;
}

// TODO: For whatever reason 'ByName' works in Bazel, but not 'ByIndex', and the
// opposite is true when using build_runner on the command-line to generate
// goldens - so for now we need both.

T _findEnumByName<T>(DartObject object, List<T> values) => values.firstWhere(
      (field) => !isNull(getField(object, '$field'.split('.')[1])),
      orElse: () => null,
    );

T _findEnumByIndex<T>(DartObject field, List<T> values) {
  final index = getField(field, 'index')?.toIntValue();
  return index != null ? values[index] : null;
}

/// Returns whether [object] is null or represents the value `null`.
bool isNull(DartObject object) => object == null || object.isNull;

/// Recursively gets the field from the [DartObject].
///
/// If the field is not found in the object, then it will visit the super
/// object.
DartObject getField(DartObject object, String field) {
  if (isNull(object)) return null;
  var fieldValue = object.getField(field);
  if (!isNull(fieldValue)) {
    return fieldValue;
  }
  return getField(object.getField('(super)'), field);
}

/// Visits all of the [DartObject]s, accumulating the results of [recuseFn].
///
/// If the DartObject is a list, then it will recursively visitAll
/// on that list. Otherwise, then it will call [recuseFn] on the object.
List<T> visitAll<T>(Iterable<DartObject> objs, T recurseFn(DartObject o)) {
  var metadata = <T>[];
  for (DartObject obj in objs) {
    var maybeList = obj.toListValue();
    if (maybeList != null) {
      metadata.addAll(visitAll<T>(maybeList, recurseFn));
    } else {
      var value = recurseFn(obj);
      if (value != null) {
        metadata.add(value);
      }
    }
  }
  return metadata;
}
