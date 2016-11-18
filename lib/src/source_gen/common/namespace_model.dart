import 'package:code_builder/code_builder.dart';

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
