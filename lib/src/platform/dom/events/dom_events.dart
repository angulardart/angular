import 'package:angular2/di.dart' show Injectable;
import 'event_manager.dart' show EventManagerPlugin;

@Injectable()
class DomEventsPlugin extends EventManagerPlugin {
  // This plugin should come last in the list of plugins, because it accepts all
  // events.
  @override
  bool supports(String eventName) {
    return true;
  }

  @override
  Function addEventListener(
      dynamic element, String eventName, Function handler) {
    var guardedHandler =
        (event) => manager.getZone().runGuarded(() => handler(event));
    return element.on[eventName].listen(guardedHandler).cancel;
  }
}
