import 'dart:convert';

import 'package:angular/di.dart' show PipeTransform, Pipe;

/// Transforms any input value using `JSON.encode`. Useful for debugging.
@Pipe('json', pure: false)
class JsonPipe implements PipeTransform {
  static const JsonEncoder _json = const JsonEncoder.withIndent('  ');

  const JsonPipe();

  String transform(value) => _json.convert(value);
}
