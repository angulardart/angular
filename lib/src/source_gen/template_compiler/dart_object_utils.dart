import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';

String getString(DartObject value, String field) =>
    getField(value, field)?.toStringValue();

List<String> getStringList(DartObject value, String field) =>
    getList(value, field)
        .map((obj) => obj.toStringValue())
        .where((obj) => obj != null)
        .toList();

List<DartObject> getList(DartObject value, String field) =>
    getField(value, field)?.toListValue() ?? [];

dynamic/*=T*/ getEnumValue/*<T>*/(DartObject value, String field,
    List/*<T>*/ values, dynamic/*=T*/ defaultValue) {
  var enumValue = getField(value, field);
  var index = getField(enumValue, 'index');
  if (index == null || index.isNull) return defaultValue;
  var indexNum = index.toIntValue();
  return indexNum != null
      ? values[indexNum]
      : defaultValue;
}

bool getBool(DartObject value, String field, {bool defaultValue: false}) =>
    getField(value, field)?.toBoolValue ?? false;

DartObject getField(DartObject object, String field) {
  if (object == null || object.isNull) return null;
  var fieldValue = object.getField(field);
  if (fieldValue != null && !fieldValue.isNull) {
    return fieldValue;
  }
  return getField(object.getField('(super)'), field);
}

typedef Future<T> RecurseFn<T>(Element element);

Future<List/*<T>*/ > visitListOfObjects/*<T>*/(
    Iterable<DartObject> objs, RecurseFn/*<T>*/ recurseFn) async {
  var metadata = [];
  for (DartObject obj in objs) {
    var type = obj.toTypeValue();
    if (type != null && type.element != null) {
      var value = await recurseFn(type.element);
      if (value != null) {
        metadata.add(value);
      }
    } else {
      metadata.addAll(await visitListOfObjects(
          obj.toListValue() ?? <DartObject>[], recurseFn));
    }
  }
  return metadata;
}
