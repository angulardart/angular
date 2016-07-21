import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/facade/lang.dart" show print, warn;
// Note: Need to rename warn as in Dart

// class members and imports can't use the same name.
var _warnImpl = warn;

@Injectable()
class Console {
  void log(String message) {
    print(message);
  }

  // Note: for reporting errors use `DOM.logError()` as it is platform specific
  void warn(String message) {
    _warnImpl(message);
  }
}
