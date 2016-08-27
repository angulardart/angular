import "package:angular2/di.dart" show PipeTransform, Injectable, Pipe;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

/// Implements uppercase transforms to text.
@Pipe(name: "uppercase")
@Injectable()
class UpperCasePipe implements PipeTransform {
  String transform(String value) {
    if (value == null) return value;
    if (value is! String) {
      throw new InvalidPipeArgumentException(UpperCasePipe, value);
    }
    return value.toUpperCase();
  }

  const UpperCasePipe();
}
