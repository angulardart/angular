import 'package:angular2/src/core/di.dart' show Injectable;

// Used internally to log messages in both online and offline mode.
//
// Both [warn] and [log] delegate to `print`, and this class can be removed in
// the future as it has no value.
@Injectable()
class Console {
  void log(String message) {
    print(message);
  }

  void warn(String message) {
    print(message);
  }
}
