import 'package:angular/core.dart' show PipeTransform, Pipe;

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

/// Transforms text to lowercase.
@Pipe('lowercase')
class LowerCasePipe implements PipeTransform {
  String transform(String value) {
    if (value == null) return value;
    if (value is! String) {
      throw InvalidPipeArgumentException(LowerCasePipe, value);
    }
    return value.toLowerCase();
  }

  const LowerCasePipe();
}
