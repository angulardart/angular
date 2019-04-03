import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:analyzer/src/generated/utilities_general.dart';

/// Interface for all angular definitions that are navigable, ie, users can
/// perform click-thru to get to this definition.
abstract class Navigable {
  /// Return the location of the name of this element in the file that contains
  /// the declaration of this element.
  SourceRange get navigationRange;

  /// Return the [Source] of this element.
  Source get source;
}

/// A simple navigable string. For instance, `exportAs: "myExport"` is navigable
/// from `<... #myVariable="myExport">`:
class NavigableString implements Navigable {
  final String string;

  @override
  final SourceRange navigationRange;

  @override
  final Source source;

  NavigableString(this.string, this.navigationRange, this.source);

  @override
  int get hashCode =>
      JenkinsSmiHash.hash3(string, navigationRange.hashCode, source.hashCode);

  @override
  bool operator ==(Object other) =>
      other is NavigableString &&
      other.string == string &&
      other.navigationRange == navigationRange &&
      other.source == source;
}
