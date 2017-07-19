import 'package:angular/src/facade/exceptions.dart' show BaseException;

class InvalidPipeArgumentException extends BaseException {
  InvalidPipeArgumentException(Type type, Object value)
      : super("Invalid argument '$value' for pipe '$type'");
}
