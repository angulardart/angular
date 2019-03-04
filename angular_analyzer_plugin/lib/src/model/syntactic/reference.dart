/// References are the ways that directives refer to each other, or pipes, or
/// their exports. References are very weak in the syntactic stage. At link
/// time, what's referenced by one prefix or identifier may change, so we can
/// only track Strings and offsets here.
///
/// Track list literals specially, however, with [ListLiteral].
import 'package:analyzer/src/generated/source.dart' show SourceRange;

/// A const list literal reference of some inner type [T]:
///
/// ```dart
///   [A, B, C, ...]
/// ```
///
/// By tracking each identifier individually, we can give better error
/// reporting.
class ListLiteral implements ListOrReference {
  /// The [Reference]s in the list literal. Note that we do not support list
  /// literals inside list literals. This works in practice because when users
  /// nest lists, the inner list is a [Reference], ie, `[A, B, listReference]`.
  final List<Reference> items;

  ListLiteral(this.items);
}

/// A list reference of some inner type [T]. Implemented by [ListLiteral]
/// or [Reference], because either is valid.
///
/// ```dart
///   directives: [ A, B, C, ... ] // this is valid
///   directives: myList // but so is this
/// ```
abstract class ListOrReference {}

/// A referenced identifier. We must know its name and prefix to be able to
/// locate it at link time. Track a [SourceRange] for error reporting reasons.
///
/// Any given reference may be intended to refer to a Pipe, Directive, or
/// Export (or a list of them, which get unnested in a similar way to how the
/// spread operator will work).
class Reference implements ListOrReference {
  String name;
  String prefix;
  SourceRange range;

  Reference(this.name, this.prefix, this.range);
}
