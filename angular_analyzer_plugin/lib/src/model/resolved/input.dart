import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show SourceRange, Source;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/input.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/standard_components.dart';
import 'package:meta/meta.dart';

/// The resolved model for an Angular input.
///
/// ```dart
///   @Input('optionalName')
///   Type fieldName; // may be a setter only
/// ```
///
/// In addition to syntactic information about the input, this tracks the type
/// expected by the setter, the setter backing the input, and some internal
/// angular concepts like security info and a workaround for dart:html with
/// native html inputs.
class Input extends syntactic.Input implements Navigable {
  /// The setter element that backs the input.
  final dart.PropertyAccessorElement setter;

  /// The type expected by the setter.
  final dart.DartType setterType;

  /// The original name of an HTML input that has been transformed by angular.
  ///
  /// A given input can have an alternative name, or more 'conventional' name
  /// that differs from the name provided by dart:html source.
  /// For example: source -> 'className', but prefer 'class'.
  /// In this case, name = 'class' and originalName = 'originalName'.
  /// This should be null if there is no alternative name.
  final String originalName;

  /// The security context of this input, for accepting sanitized types.
  ///
  /// Native inputs vulnerable to XSS (such as a.href and *.innerHTML) may have
  /// a security context. The secure type of that context should be assignable
  /// to this input, and if the security context does not allow sanitization
  /// then it will always throw otherwise and thus should be treated as an
  /// assignment error.
  final SecurityContext securityContext;

  Input(
      {@required String name,
      @required SourceRange nameRange,
      @required this.setter,
      @required this.setterType,
      this.originalName,
      this.securityContext})
      : super(
            name: name,
            nameRange: nameRange,
            setterName: setter?.name,
            setterRange: setter == null
                ? null
                : SourceRange(setter.nameOffset, setter.nameLength));

  @override
  SourceRange get navigationRange => nameRange;

  @override
  Source get source => setter?.source;

  @override
  bool operator ==(Object other) =>
      other is Input && other.setter == setter && other.name == name;

  @override
  String toString() => 'Input($name, $setter)';
}
