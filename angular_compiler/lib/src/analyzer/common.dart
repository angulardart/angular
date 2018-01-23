import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:source_gen/src/utils.dart';

/// Forwards and backwards-compatible method of getting the "name" of [type].
String getTypeName(DartType type) {
  // Crux of the issue is that the latest dart analyzer/kernel/frontend does not
  // retain the name of a typedef, for example:
  //   typedef void InterestingFn();
  //
  // Is retained as "typedef InterestingFn = void Function()", where the
  // DartType itself no longer has a "name" property (it always returns null).
  if (type is FunctionType) {
    final element = type.element;
    if (element is GenericFunctionTypeElement) {
      return element.enclosingElement.name;
    }
  }
  return type.name;
}

/// Returns the bound [DartType] from the instance [object].
///
/// For example for the following code:
/// ```
/// const foo = const <String>[];
/// const bar = const ['A string'];
/// ```
///
/// ... both `foo` and `bar` should return the [DartType] for `String`.
DartType typeArgumentOf(DartObject object, [int index = 0]) {
  if (object.type.typeArguments.isEmpty) {
    return DynamicTypeImpl.instance;
  }
  return object.type.typeArguments[index];
}

/// Returns a canonical URL pointing to [element].
///
/// For example, `List` would be `'dart:core#List'`.
Uri urlOf(Element element, [String name]) {
  if (element?.source == null) {
    return new Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');
  }
  name ??= element.name;
  // NOTE: element.source.uri might be a file that is not importable (i.e. is
  // a "part"), while element.library.source.uri is always importable.
  return normalizeUrl(element.library.source.uri).replace(fragment: name);
}
