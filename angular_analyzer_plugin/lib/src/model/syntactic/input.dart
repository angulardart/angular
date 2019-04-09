import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:meta/meta.dart';

/// The model for an Angular input.
///
/// ```dart
///   @Input('optionalName')
///   Type fieldName; // may be a setter only
/// ```
class Input {
  /// The name of the input. Usually the field name, but may be overridden by
  /// the annotation.
  final String name;

  /// The [SourceRange} of the input [name].
  final SourceRange nameRange;

  /// The name of the setter backing the input, to be linked/resolved against
  /// the element model later.
  final String setterName;

  /// The [SourceRange] where [setter] is referenced in the input declaration.
  /// May be the same as this element offset/length in shorthand variants where
  /// names of a input and the setter are the same.
  final SourceRange setterRange;

  Input(
      {@required this.name,
      @required this.nameRange,
      @required this.setterName,
      @required this.setterRange});

  @override
  String toString() => 'Input($name, $setterName)';
}
