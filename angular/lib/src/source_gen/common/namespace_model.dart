import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:quiver/iterables.dart';

/// A simple Import reference.
///
/// This is used to track the imports of types for reflection.
class ImportModel extends _NamespaceModel {
  final String prefix;
  final bool isDeferred;

  ImportModel(
      {String uri,
      this.prefix,
      this.isDeferred: false,
      List<String> showCombinators: const [],
      List<String> hideCombinators: const []})
      : super(
            uri: uri,
            showCombinators: showCombinators,
            hideCombinators: hideCombinators);

  factory ImportModel.fromElement(ImportElement element) => new ImportModel(
      uri: element.uri,
      prefix: element.prefix?.name,
      isDeferred: element.isDeferred,
      showCombinators: _showCombinators(element.combinators),
      hideCombinators: _hideCombinators(element.combinators));

  ImportBuilder get asBuilder =>
      new ImportBuilder(uri, deferred: isDeferred, prefix: prefix)
        ..showAll(showCombinators)
        ..hideAll(hideCombinators);

  String get asStatement => prettyToSource(asBuilder.buildAst());
}

/// A simple Export reference.
///
/// This is used to track the exports of types for reflection.
class ExportModel extends _NamespaceModel {
  ExportModel(
      {String uri,
      List<String> showCombinators: const [],
      List<String> hideCombinators: const []})
      : super(
            uri: uri,
            showCombinators: showCombinators,
            hideCombinators: hideCombinators);

  factory ExportModel.fromElement(ExportElement element) => new ExportModel(
      uri: element.uri,
      showCombinators: _showCombinators(element.combinators),
      hideCombinators: _hideCombinators(element.combinators));

  ImportModel get asImport => new ImportModel(
      uri: uri,
      showCombinators: showCombinators,
      hideCombinators: hideCombinators);

  ExportBuilder get asBuilder => new ExportBuilder(uri)
    ..showAll(showCombinators)
    ..hideAll(hideCombinators);
}

abstract class _NamespaceModel {
  final String uri;
  final List<String> showCombinators;
  final List<String> hideCombinators;

  _NamespaceModel(
      {this.uri,
      this.showCombinators: const [],
      this.hideCombinators: const []});
}

List<String> _showCombinators(List<NamespaceCombinator> combinators) =>
    concat(combinators
        .where((combinator) => combinator is ShowElementCombinator)
        .map((combinator) =>
            (combinator as ShowElementCombinator).shownNames)).toList();

List<String> _hideCombinators(List<NamespaceCombinator> combinators) =>
    concat(combinators
        .where((combinator) => combinator is HideElementCombinator)
        .map((combinator) =>
            (combinator as HideElementCombinator).hiddenNames)).toList();
