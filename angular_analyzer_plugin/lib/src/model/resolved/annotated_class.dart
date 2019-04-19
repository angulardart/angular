import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/input.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/output.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/top_level.dart';
import 'package:meta/meta.dart';

/// Resolved representation of a class annotated with angular annotations.
///
/// Might be a directive, or a component, or neither. It might simply have
/// annotated @Inputs, @Outputs() intended to be inherited.
class AnnotatedClass extends TopLevel {
  /// The [ClassElement] this annotation is associated with.
  final dart.ClassElement classElement;

  /// The `@ContentChildren()` declarations on this class.
  final List<ContentChild> contentChildrenFields;

  /// The `@ContentChild()` declarations on this class.
  final List<ContentChild> contentChildFields;

  /// The `@Input()` declarations on this class.
  final List<Input> inputs;

  /// The `@Output()` declarations on this class.
  final List<Output> outputs;

  AnnotatedClass(this.classElement,
      {@required this.inputs,
      @required this.outputs,
      @required this.contentChildFields,
      @required this.contentChildrenFields});

  @override
  int get hashCode => classElement.hashCode;

  /// The source that contains this directive.
  @override
  Source get source => classElement.source;

  @override
  bool operator ==(Object other) =>
      other is AnnotatedClass && other.classElement == classElement;

  @override
  String toString() => '$runtimeType(${classElement.displayName} '
      'inputs=$inputs '
      'outputs=$outputs)';
}
