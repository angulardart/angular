import 'dart:html' show Element, Event;

import 'package:angular2/di.dart' show Injectable;
import 'package:meta/meta.dart';

import 'event_manager.dart' show EventManagerPlugin;

@Injectable()
class DomEventsPlugin extends EventManagerPlugin {
  @override
  Function addEventListener(
    @checked Element element,
    String eventName,
    @checked void callback(Event event),
  ) {
    final zone = manager.getZone();
    guardedCallback(Event event) {
      return zone.runGuarded(() => callback(event));
    }

    element.addEventListener(eventName, guardedCallback);
    return null;
  }

  // This plugin comes last in the list of plugins, it accepts all events.
  @override
  bool supports(String eventName) => true;
}
