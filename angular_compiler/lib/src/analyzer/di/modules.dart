import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import '../common.dart';
import '../types.dart';
import 'providers.dart';

/// Support for reading and parsing constant `Module`s into data structures.
class ModuleReader {
  final ProviderReader _providerReader;

  const ModuleReader({ProviderReader providerReader: const ProviderReader()})
      : _providerReader = providerReader;

  /// Returns whether an object represents a constant [List].
  @protected
  bool isList(DartObject o) => o.toListValue() != null;

  /// Returns whether an object is abstractly a "module" of providers.
  ///
  /// In AngularDart, this is currently represented as a `List<Object>` where
  /// the elements of the list can be other `List<Object>`, a `Provider`, or a
  /// `Type`.
  ///
  /// Validation may not be performed on the underlying elements.
  @protected
  bool isModule(DartObject o) => isList(o) || $Module.isExactlyType(o.type);

  /// Returns a unique ordered-set based off of [providers].
  ///
  /// [ProviderElement.token] is used to determine uniqueness.
  List<ProviderElement> deduplicateProviders(
    Iterable<ProviderElement> providers,
  ) {
    final soloProviders = new LinkedHashSet<ProviderElement>(
      equals: (a, b) => a.token == b.token,
      hashCode: (e) => e.token.hashCode,
      isValidKey: (e) => e is ProviderElement,
    )..addAll(providers.where((e) => !e.isMulti));
    return soloProviders.toList()..addAll(providers.where((e) => e.isMulti));
  }

  /// Parses a static object representing a `Module`.
  ModuleElement parseModule(DartObject o) {
    if (isList(o)) {
      return _parseList(o);
    } else if ($Module.isExactlyType(o.type)) {
      return _parseModule(o);
    } else {
      final typeName = getTypeName(o.type);
      throw new FormatException('Expected Module, got "$typeName".');
    }
  }

  ModuleElement _parseList(DartObject o) {
    final items = o.toListValue();
    final include =
        items.where((item) => isModule(item)).map(parseModule).toList();
    final provide = items
        .where((item) => !isModule(item))
        .map(_providerReader.parseProvider)
        .toList();

    return new ModuleElement(provide: provide, include: include);
  }

  ModuleElement _parseModule(DartObject o) {
    final reader = new ConstantReader(o);
    final include = reader.read('include').listValue.map(parseModule).toList();
    final provide = reader
        .read('provide')
        .listValue
        .map(_providerReader.parseProvider)
        .toList();

    return new ModuleElement(provide: provide, include: include);
  }
}

class ModuleElement {
  static const iterableEquality = const IterableEquality();

  /// A list of `Provider`s directly provided by the module.
  final List<ProviderElement> provide;

  /// A list of other `Module`s included in the module.
  final List<ModuleElement> include;

  ModuleElement({this.provide, this.include});

  /// Flattens the module to a list of `Provider`s.
  ///
  /// The returned providers _may_ have duplicate tokens, and an optimizing
  /// implementation should consider using [ModuleReader.deduplicateProviders]
  /// before generating code.
  List<ProviderElement> flatten() {
    return _flatten().toList();
  }

  Iterable<ProviderElement> _flatten() sync* {
    yield* provide;
    yield* include.map((m) => m._flatten()).expand((i) => i);
  }

  @override
  bool operator ==(Object o) =>
      o is ModuleElement &&
      iterableEquality.equals(provide, o.provide) &&
      iterableEquality.equals(include, o.include);

  @override
  int get hashCode =>
      iterableEquality.hash(provide) ^ iterableEquality.hash(include);

  @override
  String toString() =>
      'ModuleElement ' +
      {
        'provide': '$provide',
        'include': '$include',
      }.toString();
}
