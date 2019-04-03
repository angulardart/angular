import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';

/// A name that is a part of a [Selector].
class SelectorName extends NavigableString {
  SelectorName(String name, SourceRange sourceRange, Source source)
      : super(name, sourceRange, source);
}
