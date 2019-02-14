import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';

/// The syntactic model of a pipe declaration.
///
/// ```dart
/// @Pipe('name', isPure: true)
/// class MyPipe {
///   Type transform(...) => ...;
/// }
/// ```
///
/// By tracking the class name and source, we can resolve the annotation's
/// computed constant value to see the state of `isPure`, and find the transform
/// method, which may be inherited.
class Pipe implements TopLevel {
  /// The user-defined name of this [Pipe], which they will use in the template.
  final String pipeName;

  /// The source range of the [pipeName], to be used for navigation.
  final SourceRange pipeNameRange;

  /// The class name of this pipe, so we can resolve it against the element
  /// model.
  final String className;

  /// The [Source] file of this pipe.
  @override
  final Source source;

  Pipe(this.pipeName, this.pipeNameRange, this.className, this.source);
}
