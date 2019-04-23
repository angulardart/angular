import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart' as resolved;

/// A [Pipe] that can be matched by its [pipeName] and then lazy-loads.
class Pipe implements resolved.Pipe {
  @override
  final String pipeName;

  resolved.Pipe Function() linkFn;

  @override
  ClassElement classElement;

  resolved.Pipe _linkedPipe;

  @override
  SourceRange pipeNameRange;

  Pipe(this.pipeName, this.pipeNameRange, this.linkFn);

  @override
  String get className => classElement.name;

  bool get isLinked => _linkedPipe != null;

  @override
  List<DartType> get optionalArgumentTypes => load().optionalArgumentTypes;

  @override
  set optionalArgumentTypes(List<DartType> _optionalArgumentTypes) {
    throw UnsupportedError(
        'lazy pipes should not change [optionalArgumentTypes]');
  }

  @override
  DartType get requiredArgumentType => load().requiredArgumentType;

  @override
  Source get source => classElement.source;

  @override
  DartType get transformReturnType => load().transformReturnType;

  @override
  bool operator ==(Object other) =>
      other is Pipe && other.classElement == classElement;

  int get hashCode => classElement.hashCode;

  resolved.Pipe load() => _linkedPipe ??= linkFn();
}
