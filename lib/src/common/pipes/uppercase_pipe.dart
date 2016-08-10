import "package:angular2/core.dart" show PipeTransform, Injectable, Pipe;
import "package:angular2/src/facade/lang.dart" show isString, isBlank;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

/// Implements uppercase transforms to text.
@Pipe(name: "uppercase")
@Injectable()
class UpperCasePipe implements PipeTransform {
  String transform(String value) {
    if (isBlank(value)) return value;
    if (!isString(value)) {
      throw new InvalidPipeArgumentException(UpperCasePipe, value);
    }
    return value.toUpperCase();
  }

  const UpperCasePipe();
}
