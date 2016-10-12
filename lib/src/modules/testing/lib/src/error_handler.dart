import 'package:angular2/di.dart';
import 'package:angular2/src/facade/exception_handler.dart';

@Injectable()
class TestExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, reason]) {}
}
