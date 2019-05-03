import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model.dart' hide Component;
import 'package:angular_analyzer_plugin/src/model.dart' as resolved;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// A [Component] that can be matched by its [selector] and then lazy-loads.
///
/// See README.md for more info on performance and design.
class Component implements resolved.Component {
  @override
  final Selector selector;

  resolved.Component Function() linkFn;

  @override
  ClassElement classElement;

  resolved.Component _linkedComponent;

  Component(this.selector, Source source, this.linkFn);

  @override
  List<NavigableString> get attributes => load().attributes;

  @override
  List<ContentChild> get contentChildFields => load().contentChildFields;

  @override
  List<ContentChild> get contentChildrenFields => load().contentChildrenFields;

  @override
  List<DirectiveBase> get directives => load().directives;

  @override
  Map<String, List<DirectiveBase>> get elementTagsInfo =>
      load().elementTagsInfo;

  @override
  NavigableString get exportAs => load().exportAs;

  @override
  List<Export> get exports => load().exports;

  @override
  List<Input> get inputs => load().inputs;

  @override
  bool get isHtml => load().isHtml;

  bool get isLinked => _linkedComponent != null;

  @override
  bool get looksLikeTemplate => load().looksLikeTemplate;

  @override
  List<NgContent> get ngContents => load().ngContents;

  @override
  List<Output> get outputs => load().outputs;

  @override
  List<Pipe> get pipes => load().pipes;

  @override
  Source get source => classElement.source;

  @override
  Template get template => load().template;

  @override
  set template(Template template) {
    load().template = template;
  }

  @override
  Source get templateSource => load().templateSource;

  @override
  String get templateText => load().templateText;

  @override
  SourceRange get templateTextRange => load().templateTextRange;

  @override
  SourceRange get templateUrlRange => load().templateUrlRange;

  @override
  Source get templateUrlSource => load().templateUrlSource;

  @override
  bool operator ==(Object other) =>
      other is Component &&
      other.source == source &&
      other.classElement == classElement;

  int get hashCode => classElement.hashCode;

  resolved.Component load() => _linkedComponent ??= linkFn();
}
