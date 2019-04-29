import 'package:analyzer/dart/element/type.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';

/// An internal variable used to resolve `let-` and `#x="y"` bindings.
///
/// These are stored as an export scope and an internal scope. Each directive
/// on a component is stored in the exported scope by its name, and variables
/// defined by `ngFor` is stored on an internal variable scope.
///
/// For resolution, `#x="y"` will read the `y` variable from the exportAs scope
/// to try to find the exported directive type, and `let-x="y"` will read the
/// variable `y` from the internal variables scope (or `$implicit` if the `let-`
/// attr has no value, as in the case of `ngFor="let x of ...`.
///
/// This mirrors what at least once was a design of the angular compiler and
/// runtime.
class InternalVariable {
  final String name;
  final Navigable element;
  final DartType type;

  InternalVariable(this.name, this.element, this.type);
}
