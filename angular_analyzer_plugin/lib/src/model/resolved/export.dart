import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';

/// A referenced identifier that is exported to the template. Simply represented
/// by offset information and a backing dart [Element].
class Export extends Reference {
  final dart.Element element;

  Export(String name, String prefix, SourceRange range, this.element)
      : super(name, prefix, range);
}
