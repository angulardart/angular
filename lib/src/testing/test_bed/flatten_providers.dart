import 'dart:convert';

import 'package:angular2/di.dart';

/// Returns a flattened list of providers if all elements are valid.
///
/// We want to provide good and quick responses when configuration is wrong
/// instead of relying on hard-to-debug runtime errors. Asserts that every
/// element in [providers] is either of type [Type] or [Provider], or is an
/// [Iterable] itself (recursive).
///
/// Throws [InvalidProviderTypeException] with a debuggable error message if any
/// element is an unexpected type or `null`.
Iterable<Object> flattenProviders(Iterable<Object> providers) {
  // TODO(matanl): Add cycle detection and support > 1 nested level.
  final flattened = providers.expand((i) => i is Iterable ? i : [i]).toList();
  for (var i = 0; i < flattened.length; i++) {
    if (flattened[i] is! Provider && flattened[i] is! Type) {
      throw new InvalidProviderTypeException._(flattened, i);
    }
  }
  return flattened;
}

/// Thrown when at least one object in a provider collection is an invalid type.
///
/// Valid types are considered to be [Type] or [Provider].
///
/// [toString] returns a debuggable error message in a human-readable format.
class InvalidProviderTypeException implements Exception {
  static const JsonEncoder _json = const JsonEncoder.withIndent('  ');

  static String _toString(Object object) {
    if (object is Type) {
      return 'Type {$object}';
    } else if (object is Provider) {
      return 'Provider {${object.token}}';
    }
    if (object == null) {
      return 'null';
    } else {
      return '${object.runtimeType} {$object}';
    }
  }

  /// First object in [source] detected as an invalid type.
  final int index;

  /// Source where [index] is an invalid type.
  final List<Object> source;

  InvalidProviderTypeException._(List<Object> source, this.index)
      : this.source = new List<Object>.unmodifiable(source);

  /// An alias for item [index] in [source].
  Object get invalid => source[index];

  @override
  String toString() {
    /*
      Invalid provider: [
        #3: Type {Foo},
        vvvvvvvvvvv
        #4: null,
        ^^^^^^^^^^^
        #5: Provider {Bar}
      ]
    */
    var output = <String>[];
    if (index > 0) {
      output.add('#${index - 1}: ' + _toString(source[index - 1]));
    }
    var badItemMessage = '#$index: ' + _toString(invalid);
    output.add('v' * badItemMessage.length);
    output.add(badItemMessage);
    output.add('^' * badItemMessage.length);
    if (index < source.length - 1) {
      output.add('#${index + 1}: ' + _toString(source[index + 1]));
    }
    return 'Invalid provider: ${_json.convert(output)}';
  }
}
