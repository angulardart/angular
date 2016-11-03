import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

String coerceString(DartObject value, String field) =>
    getField(value, field)?.toStringValue();

List<String> coerceStringList(DartObject value, String field) =>
    coerceList(value, field)
        .map((obj) => obj.toStringValue())
        .where((obj) => obj != null)
        .toList();

List<DartObject> coerceList(DartObject value, String field) =>
    getField(value, field)?.toListValue() ?? const [];

/*=T*/ coerceEnumValue/*<T>*/(DartObject value, String field,
    List/*<T>*/ values, dynamic/*=T*/ defaultValue) {
  var enumValue = getField(value, field);
  var index = getField(enumValue, 'index');
  if (index == null || index.isNull) return defaultValue;
  var indexNum = index.toIntValue();
  return indexNum != null ? values[indexNum] : defaultValue;
}

bool coerceBool(DartObject value, String field, {bool defaultValue: false}) =>
    getField(value, field)?.toBoolValue ?? false;

/// Recursively gets the field from the [DartObject].
///
/// If the field is not found in the object, then it will visit the super
/// object.
DartObject getField(DartObject object, String field) {
  if (object == null || object.isNull) return null;
  var fieldValue = object.getField(field);
  if (fieldValue != null && !fieldValue.isNull) {
    return fieldValue;
  }
  return getField(object.getField('(super)'), field);
}

typedef T RecurseFn<T>(Element element);

/// Visits all of the [DartObject]s, accumulating the results of [RecurseFn].
///
/// If the DartObject is a type, then it will call [RecurseFn] on the types's
/// [Element]. If the DartObject is a list, then it will recursively visitAll
/// on that list.
List<dynamic/*=T*/ > visitAll/*<T>*/(
    Iterable<DartObject> objs, RecurseFn<dynamic/*=T*/ > recurseFn) {
  var metadata = /*<T>*/ [];
  for (DartObject obj in objs) {
    var type = obj.toTypeValue();
    if (type != null && type.element != null) {
      var value = recurseFn(type.element);
      if (value != null) {
        metadata.add(value);
      }
    } else {
      metadata.addAll(
          visitAll/*<T>*/(obj.toListValue() ?? <DartObject>[], recurseFn));
    }
  }
  return metadata;
}
