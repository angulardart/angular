import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:meta/meta.dart';

/// The model for an Angular output.
///
/// ```dart
///   @Output('optionalName')
///   Type fieldName; // may be a getter only
/// ```
///
/// By tracking the name, we can resolve the type at link time. We track the
/// [SourceRange] (as well as [nameOffset] and [nameLength] to help expose
/// better errors at that time.
class Output {
  /// The name of the output. Usually the field name, but may be overridden by
  /// the annotation.
  final String name;

  /// The [SourceRange} of the output [name].
  final SourceRange nameRange;

  /// The name of the getter backing the input, to be linked/resolved against
  /// the element model later.
  final String getterName;

  /// The [SourceRange] where [getter] is referenced in the input declaration.
  /// May be the same as this element offset/length in shorthand variants where
  /// names of a input and the getter are the same.
  final SourceRange getterRange;

  Output(
      {@required this.name,
      @required this.nameRange,
      @required this.getterName,
      @required this.getterRange});

  @override
  String toString() => 'Output($name, $getterName)';
}
