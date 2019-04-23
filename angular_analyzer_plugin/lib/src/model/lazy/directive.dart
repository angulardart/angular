import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model.dart' hide Directive;
import 'package:angular_analyzer_plugin/src/model.dart' as resolved;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// A [Directive] that can be matched by its [selector] and then lazy-loads.
///
/// See README.md for more info on performance and design.
class Directive implements resolved.Directive {
  @override
  final Selector selector;

  resolved.Directive Function() linkFn;

  @override
  ClassElement classElement;

  resolved.Directive _linkedDirective;

  Directive(this.selector, this.linkFn);

  @override
  List<NavigableString> get attributes => load().attributes;

  @override
  List<ContentChild> get contentChildFields => load().contentChildFields;

  @override
  List<ContentChild> get contentChildrenFields => load().contentChildrenFields;

  @override
  NavigableString get exportAs => load().exportAs;

  @override
  List<Input> get inputs => load().inputs;

  @override
  bool get isHtml => load().isHtml;

  bool get isLinked => _linkedDirective != null;

  @override
  bool get looksLikeTemplate => load().looksLikeTemplate;

  @override
  List<Output> get outputs => load().outputs;

  @override
  Source get source => classElement.source;

  @override
  bool operator ==(Object other) =>
      other is Directive &&
      other.source == source &&
      other.classElement == classElement;

  int get hashCode => classElement.hashCode;

  resolved.Directive load() => _linkedDirective ??= linkFn();
}
