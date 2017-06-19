import 'package:analyzer/dart/element/element.dart';

/// A wrapper around [ClassElement] which exposes the functionality
/// needed for the view compiler to find types for expressions.
class AnalyzedClass {
  final ClassElement _classElement;

  AnalyzedClass(this._classElement);
}
