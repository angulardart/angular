import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

extension NullableDartType on DartType? {
  /// Whether the type is an opted-in library where it is explicitly non-null.
  bool get isExplicitlyNonNullable {
    var type = this;
    if (type == null || type.isDynamic) {
      return false;
    }
    if (_isFutureOrWithExplicitlyNullableValue) {
      return false;
    }
    return type.nullabilitySuffix == NullabilitySuffix.none;
  }

  /// Whether the type is an opted-in library where it explicitly nullable.
  bool get isExplicitlyNullable {
    var type = this;
    if (type == null || type.isDynamic) {
      return false;
    }
    if (_isFutureOrWithExplicitlyNullableValue) {
      return true;
    }
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// A FutureOr<String?> can still be assigned null.
  bool get _isFutureOrWithExplicitlyNullableValue =>
      this!.isDartAsyncFutureOr &&
      (this as ParameterizedType).typeArguments.first.isExplicitlyNullable;
}
