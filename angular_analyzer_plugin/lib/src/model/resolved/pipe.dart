import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart'
    as syntactic;
import 'package:meta/meta.dart';

/// The resolved model of a pipe declaration.
///
/// ```dart
/// @Pipe('name', isPure: true)
/// class MyPipe {
///   ReturnType transform(RequiredType requiredArg, [...]) => ...;
/// }
/// ```
///
/// Adds resolution information about the class that is annotated, such as the
/// element for that class, and the type information for the transform method.
class Pipe extends syntactic.Pipe {
  /// The resolved class this pipe belongs to.
  final dart.ClassElement classElement;

  /// Pipes must have one non-optional argument. Store its [DartType].
  final dart.DartType requiredArgumentType;

  /// Pipes return the [DartType] which it's transform method returns.
  final dart.DartType transformReturnType;

  /// Pipes may have additional optional arguments. Store their [DartType]s.
  List<dart.DartType> optionalArgumentTypes = <dart.DartType>[];

  Pipe(String pipeName, SourceRange pipeNameRange, this.classElement,
      {@required this.requiredArgumentType,
      @required this.transformReturnType,
      @required this.optionalArgumentTypes})
      : super(pipeName, pipeNameRange, classElement.name, classElement.source);
}
