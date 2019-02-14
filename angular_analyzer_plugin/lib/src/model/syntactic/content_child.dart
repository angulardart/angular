import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:meta/meta.dart';

/// Syntactic model of `ContentChild`/`ContentChildren`. This may appear as:
///
/// ```dart
///   @ContentChild(...) Type contentChildField;
/// // or
///   @ContentChildren(...) List<Type> contentChildrenField;
/// ```
///
/// By tracking the field name, we can resolve the getter along with the
/// computed constant value of the annotation at link time. We also track the
/// syntactic name and type locations for better error reporting at that stage.
class ContentChild {
  final String fieldName;
  final SourceRange nameRange;
  final SourceRange typeRange;

  ContentChild(this.fieldName,
      {@required this.nameRange, @required this.typeRange});
}
