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

  const ModuleReader({ProviderReader providerReader = const ProviderReader()})
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

  /// Helper method that can recursively extract [DartObject]s for `Provider`.
  ///
  /// A [value] can be one of four (4) things:
  /// * A constant instance of `Type` (implicit `Provider`)
  /// * A constant instance of `Provider`
  /// * A constant `List` of any of the above types, including other lists.
  /// * A constant `Module`, which has its own way of collecting these objects.
  ///
  /// **NOTE**: That the implicit conversion of `Type` to `Provider` is expected
  /// to happen elsewhere, this function is just a convenience for dealing with
  /// `Module` versus `List` in the view compiler.
  ///
  /// Returns a lazy iterable of only `Type` or `Provider` objects.
  Iterable<DartObject> extractProviderObjects(DartObject value) {
    // Guard against being passed a null field.
    if (value == null || value.isNull) {
      return const [];
    }
    if (isList(value)) {
      return _extractProvidersFromList(value);
    }
    if (isModule(value)) {
      return _extractProvidersFromModule(value);
    }
    return [value];
  }

  Iterable<DartObject> _extractProvidersFromList(DartObject value) {
    return value.toListValue().map(extractProviderObjects).expand((e) => e);
  }

  Iterable<DartObject> _extractProvidersFromModule(DartObject value) sync* {
    final providersField = value.getField('provide');
    final modulesField = value.getField('include');
    if (!modulesField.isNull) {
      yield* modulesField
          .toListValue()
          .map(_extractProvidersFromModule)
          .expand((e) => e);
    }
    if (!providersField.isNull) {
      yield* providersField.toListValue();
    }
  }

  /// Returns a unique ordered-set based off of [providers].
  ///
  /// [ProviderElement.token] is used to determine uniqueness.
  List<ProviderElement> deduplicateProviders(
    Iterable<ProviderElement> providers,
  ) {
    final soloProviders = LinkedHashSet<ProviderElement>(
      equals: (a, b) => a.token == b.token,
      hashCode: (e) => e.token.hashCode,
      isValidKey: (e) => e is ProviderElement,
    )..addAll(providers.where((e) => !e.isMulti).toList().reversed);
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
      throw FormatException('Expected Module, got "$typeName".');
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

    return ModuleElement(provide: provide, include: include);
  }

  ModuleElement _parseModule(DartObject o) {
    final reader = ConstantReader(o);
    final includeReader = reader.read('include');
    if (!includeReader.isList) {
      throw FormatException(
          "Expected list for 'include' field of ${reader.objectValue.type}");
    }
    final include = includeReader.listValue.map(parseModule).toList();
    final provideReader = reader.read('provide');
    if (!provideReader.isList) {
      throw FormatException(
          "Expected list for 'provide' field of ${reader.objectValue.type}.");
    }
    final provide =
        provideReader.listValue.map(_providerReader.parseProvider).toList();
    return ModuleElement(provide: provide, include: include);
  }
}

class ModuleElement {
  static const iterableEquality = IterableEquality();

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
    yield* include.map((m) => m._flatten()).expand((i) => i);
    yield* provide;
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
