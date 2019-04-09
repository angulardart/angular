import 'package:analyzer/src/generated/source.dart' show Source;

/// An abstract model of an Angular top level construct.
///
/// This may be a functional directive, component, or normal directive...or even
/// an [AnnotatedClass] which is a class that defines component/directive
/// behavior for the sake of being inherited.
abstract class TopLevel {
  /// Source info for navigation.
  Source get source;
}
