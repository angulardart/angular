// http://go/migrate-deps-first
// @dart=2.9
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

extension NullableDartType on DartType /*?*/ {
  /// Whether the type is an opted-in library where it is explicitly non-null.
  bool get isExplicitlyNonNullable {
    if (this == null || isDynamic) {
      return false;
    }
    if (_isFutureOrWithExplicitlyNullableValue) {
      return false;
    }
    return nullabilitySuffix == NullabilitySuffix.none;
  }

  /// Whether the type is an opted-in library where it explicitly nullable.
  bool get isExplicitlyNullable {
    if (this == null || isDynamic) {
      return false;
    }
    if (_isFutureOrWithExplicitlyNullableValue) {
      return true;
    }
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  /// A FutureOr<String?> can still be assigned null.
  bool get _isFutureOrWithExplicitlyNullableValue =>
      isDartAsyncFutureOr &&
      (this as ParameterizedType).typeArguments.first.isExplicitlyNullable;
}
