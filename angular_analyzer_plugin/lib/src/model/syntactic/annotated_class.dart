import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model/syntactic/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/input.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/output.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:meta/meta.dart';

/// Syntactic representation of a class annotated with angular annotations.
///
/// Might be a directive, or a component, or neither. It might simply have
/// annotated @Inputs, @Outputs() intended to be inherited.
class AnnotatedClass extends TopLevel {
  final String className;

  /// The source that contains this directive.
  @override
  final Source source;

  /// The `@Input()` declarations on this class.
  final List<Input> inputs;

  /// The `@Output()` declarations on this class.
  final List<Output> outputs;

  /// The `@ContentChild()` declarations on this class.
  final List<ContentChild> contentChildFields;

  /// The `@ContentChildren()` declarations on this class.
  final List<ContentChild> contentChildrenFields;

  AnnotatedClass(this.className, this.source,
      {@required this.inputs,
      @required this.outputs,
      @required this.contentChildFields,
      @required this.contentChildrenFields});

  @override
  String toString() => '$runtimeType($className '
      'inputs=$inputs '
      'outputs=$outputs)';
}
