import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/input.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/output.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// Core behavior to directives and components, including functional directives,
/// but excluding non directive parts of angular such as pipes and regular
/// annotated classes.
abstract class DirectiveBase extends TopLevel {
  /// @Attribute() constructor arguments
  List<NavigableString> get attributes;

  /// `@ContentChild` information for this directive.
  List<ContentChild> get contentChildFields;

  /// `@ContentChildren` information for this directive.
  List<ContentChild> get contentChildrenFields;

  /// The `exportAs` identifier of this directive, if it exists.
  NavigableString get exportAs;

  /// `@Input()` definitions for this directive.
  List<Input> get inputs;

  /// Html directives and components get validated differently.
  bool get isHtml;

  /// Whether this directive appears to be used as a `*star` attr.
  ///
  /// Its very hard to tell which directives are meant to be used with a *star.
  /// However, any directives which have a `TemplateRef` as a constructor
  /// parameter are almost certainly meant to be used with one. We use this for
  /// whatever validation we can, and autocomplete suggestions.
  bool get looksLikeTemplate;

  /// `@Output()` definitions for this directive.
  List<Output> get outputs;

  Selector get selector;
}
