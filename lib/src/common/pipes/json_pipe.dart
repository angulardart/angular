import "package:angular2/di.dart" show Injectable, PipeTransform, Pipe;
import "package:angular2/src/facade/lang.dart" show Json;

/// Transforms any input value using `JSON.encode`. Useful for debugging.
@Pipe(name: "json", pure: false)
@Injectable()
class JsonPipe implements PipeTransform {
  String transform(dynamic value) {
    return Json.stringify(value);
  }

  const JsonPipe();
}
