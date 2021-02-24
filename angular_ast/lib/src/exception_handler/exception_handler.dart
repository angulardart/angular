import 'package:meta/meta.dart';

import '../hash.dart';

part 'angular_parser_exception.dart';
part 'exceptions.dart';

abstract class ExceptionHandler {
  void handle(AngularParserException? e);
}

@sealed
class ThrowingExceptionHandler implements ExceptionHandler {
  @override
  void handle(AngularParserException? e) {
    if (e != null) {
      throw e;
    }
  }

  @literal
  const ThrowingExceptionHandler();
}

class RecoveringExceptionHandler implements ExceptionHandler {
  final exceptions = <AngularParserException>[];

  @override
  void handle(AngularParserException? e) {
    if (e != null) {
      exceptions.add(e);
    }
  }
}
